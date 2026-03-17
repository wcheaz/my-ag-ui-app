## Context

The procurement agent currently generates codes based on user descriptions but lacks a systematic disambiguation workflow. The agent's current workflow is:

1. User provides a description
2. Agent calls `read_code_generation_file` (enforced)
3. Agent infers/guesses component values
4. Agent calls `save_procurement_code`

The problem occurs at step 3: the agent often makes assumptions about ambiguous inputs without user confirmation, leading to incorrect codes that are only discovered after generation.

**Current State:**
- Agent enforces reading the rules file before saving
- No structured disambiguation mechanism
- Agent may silently guess or infer ambiguous inputs
- Users discover incorrect codes after generation

**Constraints:**
- Must maintain existing `rules_loaded_this_turn` enforcement
- Must work with existing tool architecture
- Must not break backward compatibility for unambiguous inputs
- Must be enforceable programmatically, not just via system prompt

**Stakeholders:**
- Users who need accurate procurement codes
- Developers maintaining the agent codebase
- QA team testing the disambiguation workflow

## Goals / Non-Goals

**Goals:**
- Implement a confirm-before-generate pattern that prevents ambiguous code generation
- Provide structured disambiguation for all 8 code components
- Allow explicit user-initiated guessing when appropriate
- Support iterative clarification until all components are unambiguous
- Enforce disambiguation programmatically through the agent workflow
- Maintain backward compatibility for clear, unambiguous inputs

**Non-Goals:**
- Implementing persistent code history (deferred per project scope)
- Changing the code generation rules themselves
- Modifying the RAG citation system
- Implementing a full-blown conversational UI for all interactions
- Storing disambiguation history across sessions

## Decisions

### Decision 1: Hybrid Approach - Tool + Prompt Pattern

**Choice:** Implement both a new disambiguation tool AND enhance the system prompt to enforce the confirm-before-generate workflow.

**Rationale:**
- **Tool approach**: Provides programmatic enforcement and structured output that the UI can render. A `clarify_components` tool can return JSON-structured options for ambiguous components.
- **Prompt pattern**: Ensures the agent understands the workflow and knows when to call the tool. The system prompt will explicitly state the disambiguation workflow.
- **Combined benefits**: The tool provides enforcement and structure, while the prompt guides the agent's behavior. This dual approach is more robust than either alone.

**Alternatives Considered:**
- **Prompt-only approach**: Would rely on agent compliance, which has proven unreliable (see suggestion 1's enforcement pattern).
- **Tool-only approach**: Without prompt guidance, the agent might not know when or how to use the tool effectively.

**Implementation:**
```python
def clarify_components(ctx, user_description: str) -> str:
    """
    Parses user description and identifies ambiguous components.
    Returns structured options for clarification.
    """
    # Parse description against CODE_GENERATION.md rules
    # Identify ambiguous components (2+ matches)
    # Return JSON with component options
```

### Decision 2: State-Based Ambiguity Tracking

**Choice:** Extend `ProcurementState` to track component ambiguity status throughout the disambiguation workflow.

**Rationale:**
- The existing `ProcurementState` already tracks `rules_loaded_this_turn`
- Adding `component_ambiguity_status` allows programmatic enforcement
- Enables `save_procurement_code` to reject saves with ambiguous components
- Maintains state consistency with the existing enforcement pattern

**Implementation:**
```python
class ProcurementState(BaseModel):
    rules_loaded_this_turn: bool = False
    component_ambiguity_status: Dict[str, AmbiguityInfo] = Field(default_factory=dict)
    # AmbiguityInfo: {component_name: {status: "ambiguous"|"unambiguous", options: [...], selected: ...}}
```

### Decision 3: Iterative Clarification with Context Preservation

**Choice:** Implement iterative clarification where the agent maintains context across rounds and only asks about remaining ambiguous components.

**Rationale:**
- Users may not provide all information in one response
- Iterative approach is more user-friendly than requiring complete information upfront
- Context preservation prevents asking the same question multiple times
- Aligns with natural conversation flow

**Implementation:**
- After each clarification round, update `component_ambiguity_status`
- Only present options for components still marked as ambiguous
- Track which components have been confirmed to avoid redundant questions

### Decision 4: Explicit Guess Permission via User Intent Detection

**Choice:** Only allow guessing when the user explicitly states they don't know or provides minimal information, detected through intent analysis.

**Rationale:**
- Balances accuracy with user experience
- Prevents silent guessing while allowing user-initiated shortcuts
- Requires clear user intent to bypass disambiguation

**Implementation:**
- Detect phrases like "I don't know", "whatever", "you choose", etc.
- When detected, mark component as "guessed" and inform user
- Require explicit confirmation before proceeding with guessed values

### Decision 5: Structured JSON Output for UI Integration

**Choice:** Return disambiguation options in structured JSON format that the UI can render.

**Rationale:**
- Enables UI to render interactive selection components
- Separates presentation logic from agent logic
- Provides flexibility for future UI enhancements
- Makes the output parseable and testable

**Implementation:**
```json
{
  "ambiguous_components": [
    {
      "component_name": "Major Category",
      "options": [
        {"value": "A", "description": "Agricultural products"},
        {"value": "C", "description": "Chemical products"}
      ]
    }
  ],
  "unambiguous_components": ["Manufacturing Method", "Object Shape", ...]
}
```

## Risks / Trade-offs

### Risk 1: User Frustration with Excessive Clarification

**Risk:** Users may become frustrated if the agent asks too many clarification questions, especially for experienced users who provide detailed descriptions.

**Mitigation:**
- Only ask when genuine ambiguity exists (2+ plausible matches)
- Allow experienced users to provide more detailed descriptions upfront
- Consider adding a "skip disambiguation" option for power users (future enhancement)
- Monitor and tune the ambiguity detection threshold

### Risk 2: Ambiguity Detection Accuracy

**Risk:** The ambiguity detection logic may incorrectly classify clear inputs as ambiguous, or miss genuine ambiguities.

**Mitigation:**
- Start with conservative thresholds (only flag clear ambiguities)
- Implement comprehensive test cases covering edge cases
- Monitor production usage and refine detection logic
- Allow manual override if detection is clearly wrong

### Risk 3: State Management Complexity

**Risk:** Adding `component_ambiguity_status` to `ProcurementState` increases state complexity and potential for bugs.

**Mitigation:**
- Keep state structure simple and well-documented
- Implement validation for state transitions
- Write comprehensive unit tests for state management
- Consider using a dedicated `DisambiguationState` class if complexity grows

### Risk 4: Backward Compatibility

**Risk:** Changes to the agent workflow may break existing integrations or test cases.

**Mitigation:**
- Ensure unambiguous inputs follow the same workflow path (no additional steps)
- Maintain existing tool signatures
- Run existing test suite before and after changes
- Provide clear migration documentation for any breaking changes

### Trade-off: Accuracy vs. Speed

**Trade-off:** The confirm-before-generate pattern prioritizes accuracy over speed, which may increase interaction time for some users.

**Rationale:**
- The user explicitly stated: "I value accuracy over speed for all code generation"
- Incorrect codes require more time to fix than upfront clarification
- Poor UX from incorrect codes outweighs minor speed improvements

## Migration Plan

### Phase 1: Implementation (Development)
1. Implement `clarify_components` tool in `agent.py`
2. Extend `ProcurementState` with `component_ambiguity_status`
3. Update `save_procurement_code` to check ambiguity status
4. Enhance system prompt with disambiguation workflow instructions
5. Write unit tests for disambiguation logic

### Phase 2: Testing (Staging)
1. Run existing test suite to ensure no regressions
2. Add integration tests for disambiguation workflow
3. Test with ambiguous inputs (single and multiple components)
4. Test iterative clarification scenarios
5. Test explicit guess permission scenarios
6. Test UI integration with JSON output

### Phase 3: Deployment (Production)
1. Deploy to production with feature flag (if available)
2. Monitor for errors and unexpected behavior
3. Gather user feedback on disambiguation experience
4. Tune ambiguity detection thresholds based on usage

### Rollback Strategy
- If critical issues arise, revert to previous version of `agent.py`
- State changes are backward compatible (new fields have defaults)
- System prompt changes can be reverted independently
- Feature flag allows quick disable without code deployment

## Open Questions

1. **Ambiguity Detection Threshold:** How should we determine when a component has "2+ plausible matches"? Should we use semantic similarity, keyword matching, or a combination? This may require experimentation and tuning.

2. **UI Integration:** What specific UI components should render the disambiguation options? Dropdowns, radio buttons, or something else? This depends on frontend capabilities and may require frontend changes.

3. **Guess Permission Phrasing:** What exact phrases should trigger explicit guess permission? Need to compile a comprehensive list and potentially support multiple languages.

4. **Performance Impact:** How will the disambiguation logic affect response time, especially for complex descriptions? May need to optimize parsing logic.

5. **Error Handling:** What should happen if the disambiguation tool fails or returns unexpected results? Need clear error handling and recovery strategies.