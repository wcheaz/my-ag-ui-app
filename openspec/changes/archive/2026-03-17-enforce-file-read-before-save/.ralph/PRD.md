# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

## Why

The agent currently relies on voluntary compliance to call `read_code_generation_file` before generating codes. Under conversational pressure, the LLM may skip reading the rules file, leading to inaccurate procurement codes that don't match the current CODE_GENERATION.md specifications. This enforcement is critical for accuracy since rules may change and need to be re-injected into the active context window on every request.

## What Changes

- Add `rules_loaded_this_turn` flag to `ProcurementState` that resets per request
- Modify `read_code_generation_file` tool to set the flag when successfully executed
- Add validation in `save_procurement_code` tool to check the flag and reject saves if rules weren't loaded
- Change `read_code_generation_file` to raise exceptions on failure instead of returning error strings
- Update system prompt to reflect the new enforced workflow

## Capabilities

### New Capabilities
(None - this change modifies existing behavior)

### Modified Capabilities

- `procurement-agent`: Add requirement to enforce that `read_code_generation_file` MUST be called before `save_procurement_code`. The agent cannot skip reading rules or save codes without loading them first.

## Impact

- **Code**: `agent/src/agent.py` - modifications to `ProcurementState`, `read_code_generation_file`, and `save_procurement_code` functions
- **State**: New per-request state tracking for rules loading
- **Error Handling**: Improved error visibility through exceptions instead of silent error strings
- **Backward Compatibility**: **BREAKING** - agents that previously skipped file-read will now be blocked from saving codes

## Specifications

procurement-agent/spec.md
## MODIFIED Requirements

### Requirement: Enforce Procurement Workflow
The agent MUST strictly follow a defined workflow to ensure accurate procurement code generation and use all required tools. The workflow SHALL be enforced programmatically, not just through system prompt instructions.

#### Scenario: Agent Initialization
Given the agent starts up
Then it must load the necessary tools (`read_code_generation_file`, `save_procurement_code`, `reset_conversation`)
And it must have the specific System Prompt loaded
And the ProcurementState MUST include a `rules_loaded_this_turn` flag that defaults to False

#### Scenario: Rule File Read Enforcement
Given the agent receives a code generation request
When the agent calls `read_code_generation_file` and it succeeds
Then the `rules_loaded_this_turn` flag MUST be set to True
And the agent MUST proceed with code generation

#### Scenario: Rule File Read Failure
Given the agent calls `read_code_generation_file`
When the file read fails (file not found or read error)
Then the system MUST raise an exception with a clear error message
And the `rules_loaded_this_turn` flag MUST remain False
And the agent MUST NOT proceed with code generation

#### Scenario: Save Validation
Given the agent attempts to call `save_procurement_code`
When the `rules_loaded_this_turn` flag is False
Then the system MUST return an error message: "ERROR: You must call read_code_generation_file before saving a code."
And the code MUST NOT be saved to the state

#### Scenario: Successful Save After Read
Given the agent has successfully called `read_code_generation_file`
When the agent calls `save_procurement_code`
Then the system MUST save the code to the state
And return a success message

## ADDED Requirements

### Requirement: State Tracking for Rule Loading
The ProcurementState MUST track whether the code generation rules file has been loaded during the current request to enforce workflow compliance.

#### Scenario: Flag Initialization
Given a new request begins
When the ProcurementState is initialized
Then the `rules_loaded_this_turn` flag MUST be set to False

#### Scenario: Flag Reset on New Request
Given the agent starts a new code generation request
When the request context is created
Then the `rules_loaded_this_turn` flag MUST be reset to False
And previous request state MUST NOT affect the new request

### Requirement: Exception-Based Error Handling
The system MUST raise exceptions for file read failures instead of returning error strings to ensure errors are visible and unignorable.

#### Scenario: File Not Found Exception
Given the agent calls `read_code_generation_file`
When the CODE_GENERATION.md file is not found in any expected location
Then the system MUST raise a FileNotFoundError with message "CODE_GENERATION.md not found. Cannot generate codes without rules."

#### Scenario: Read Error Exception
Given the agent calls `read_code_generation_file`
When an error occurs while reading the file
Then the system MUST raise an Exception with a descriptive error message including the original error



## Design

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

## Current Task Context

## Current Task
- 1.1 Move `import datetime` statement to the top of `agent/src/agent.py` (currently at line 272, needs to be before line 61 where it's used)
