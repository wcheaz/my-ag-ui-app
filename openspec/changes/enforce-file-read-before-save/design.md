## Context

The procurement agent currently relies on voluntary compliance to call `read_code_generation_file` before generating codes. The system prompt instructs the agent to "MUST first call `read_code_generation_file`", but this is trust-based enforcement. Under conversational pressure or in long conversations, the LLM may skip reading the rules file, leading to inaccurate procurement codes that don't match the current `CODE_GENERATION.md` specifications.

**Current State:**
- [`ProcurementState`](agent/src/agent.py:40) tracks conversation history and generated codes but has no mechanism to track rule file loading
- [`read_code_generation_file()`](agent/src/agent.py:50) returns error strings on failure (lines 85, 91) instead of raising exceptions
- [`save_procurement_code()`](agent/src/agent.py:220) has no validation that rules were loaded before saving
- The system prompt (lines 242-260) mandates the workflow but cannot enforce it programmatically

**Constraints:**
- Must work within the existing PydanticAI framework and StateDeps pattern
- Changes should be minimal and focused on enforcement, not architectural overhaul
- Error handling must be visible to the agent and user
- The flag must reset per request to prevent stale state

## Goals / Non-Goals

**Goals:**
- Enforce that `read_code_generation_file` is called before `save_procurement_code` on every request
- Make file read failures visible through exceptions instead of silent error strings
- Provide clear error messages to the agent when workflow violations occur
- Maintain backward compatibility for agents that already follow the workflow correctly

**Non-Goals:**
- Implementing persistent code history (suggestion #6 from SUGGESTIONS.md)
- Adding deterministic code validation (suggestion #2 from SUGGESTIONS.md)
- Implementing disambiguation tools (suggestion #3 from SUGGESTIONS.md)
- Refactoring the entire agent architecture (suggestion #5 from SUGGESTIONS.md)
- Cleaning up debug/logging code (suggestion #4 from SUGGESTIONS.md)

## Decisions

### Decision 1: Add `rules_loaded_this_turn` flag to `ProcurementState`

**Choice:** Add a boolean field `rules_loaded_this_turn: bool = False` to the [`ProcurementState`](agent/src/agent.py:40) class that resets at the start of each new request.

**Rationale:**
- Simple, lightweight state tracking that aligns with existing Pydantic BaseModel pattern
- Boolean flag is sufficient - we only need to know IF rules were loaded, not WHEN or HOW
- Per-request reset prevents stale state from previous requests
- No database or persistence needed (out of scope per current requirements)

**Alternatives Considered:**
- *Timestamp-based tracking*: More complex, not needed for simple boolean check
- *Counter-based tracking*: Overkill, boolean is sufficient
- *External state storage*: Adds complexity, not needed for per-request enforcement

### Decision 2: Set flag in `read_code_generation_file` on successful execution

**Choice:** Set `ctx.deps.state.rules_loaded_this_turn = True` immediately after successfully reading the file content (after line 88 in the current implementation).

**Rationale:**
- Ensures flag is set ONLY when file read succeeds
- Placed after content read but before return, ensuring atomic operation
- Clear contract: successful read = flag set
- Aligns with existing error handling flow

**Alternatives Considered:**
- *Set flag before reading*: Would incorrectly mark success even if read fails
- *Set flag in caller*: Would require changes to agent framework, more invasive
- *Use try/finally*: Unnecessary complexity for simple boolean set

### Decision 3: Validate flag in `save_procurement_code` before saving

**Choice:** Add a check at the start of [`save_procurement_code()`](agent/src/agent.py:220) that returns an error message if `rules_loaded_this_turn` is `False`.

**Rationale:**
- Enforces workflow at the point of action (save)
- Provides immediate feedback to the agent when workflow is violated
- Error message is clear: "ERROR: You must call read_code_generation_file before saving a code."
- Prevents invalid codes from being saved to state

**Alternatives Considered:**
- *Raise exception instead of returning error*: Would require agent to handle exceptions, more complex
- *Check in agent framework layer*: Would require framework changes, more invasive
- *Check in UI layer*: Too late - code already saved, validation should happen before save

### Decision 4: Raise exceptions on file read failures

**Choice:** Replace error string returns in [`read_code_generation_file()`](agent/src/agent.py:50) with `raise FileNotFoundError()` or `raise Exception()` for failures (lines 85, 91).

**Rationale:**
- Makes failures visible and unignorable to the agent
- Aligns with Python best practices for error handling
- Prevents silent failures where agent continues with invalid state
- Exception messages are clear and actionable

**Alternatives Considered:**
- *Keep returning error strings*: Silent failures, agent may ignore or work around them
- *Return None or empty string*: Ambiguous, doesn't distinguish between success and failure
- *Use custom exception classes*: Overkill for simple error cases

### Decision 5: Update system prompt to reflect enforced workflow

**Choice:** Update the [`STATIC_SYSTEM_PROMPT`](agent/src/agent.py:239) to indicate that the workflow is now enforced programmatically, not just recommended.

**Rationale:**
- Communicates to the agent that enforcement is now in place
- Reduces likelihood of agent attempting to bypass the workflow
- Aligns prompt with actual implementation behavior
- Maintains clarity about expected behavior

**Alternatives Considered:**
- *Leave prompt unchanged*: Agent may not realize enforcement is in place
- *Remove workflow instructions entirely*: Agent needs guidance on what to do
- *Add complex error handling instructions*: Unnecessary, enforcement handles it

## Risks / Trade-offs

### Risk 1: Breaking change for agents that skip file-read

**Risk:** Agents that previously skipped `read_code_generation_file` will now be blocked from saving codes.

**Mitigation:** This is intentional - the breaking change is the goal. However, we should:
- Provide clear error messages explaining what the agent needs to do
- Test with existing agent behavior to ensure proper error handling
- Document the breaking change clearly in deployment notes

### Risk 2: Flag not resetting between requests

**Risk:** If `rules_loaded_this_turn` doesn't reset properly, an agent could read once and save multiple times without re-reading.

**Mitigation:** 
- The flag is reset per request by the PydanticAI framework when creating new state instances
- We can add explicit reset in `reset_conversation()` if needed (line 210 already clears `citation_sources`)
- Test multi-request scenarios to verify proper flag behavior

### Risk 3: Exception handling complexity

**Risk:** Raising exceptions instead of returning error strings changes the error handling pattern.

**Mitigation:**
- PydanticAI framework handles exceptions gracefully
- Agent will see exception messages and can take appropriate action
- Test exception scenarios to ensure proper agent behavior

### Risk 4: Missing `datetime` import in `read_code_generation_file`

**Risk:** The current code uses `datetime.datetime.now()` at line 61 but `datetime` is imported at line 272, not in scope at line 61.

**Mitigation:**
- Move the `import datetime` statement to the top of the file (near line 1-4)
- This is a bug fix that should be done as part of this change

### Trade-off: Enforcement vs. Flexibility

**Trade-off:** We're sacrificing some flexibility (agents can no longer skip file-read even if they want to) for accuracy and reliability.

**Justification:** The use case (procurement code generation) requires high accuracy. The flexibility to skip file-read was never a feature - it was a bug. The enforcement aligns with the stated goal of ensuring codes match current specifications.

### Trade-off: Complexity vs. Simplicity

**Trade-off:** Adding state tracking and validation increases code complexity slightly.

**Justification:** The complexity is minimal (one boolean field, two checks) and the benefit (enforced accuracy) is high. The design is simple and focused, not over-engineered.
