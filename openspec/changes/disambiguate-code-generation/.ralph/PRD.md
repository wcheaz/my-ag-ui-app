# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

## Why

Users currently discover incorrect procurement codes only after they've been generated and saved, creating a poor user experience. The agent often attempts to infer or guess ambiguous inputs instead of asking for clarification, leading to inaccurate codes that require regeneration and correction.

## What Changes

- Implement a confirm-before-generate pattern for ambiguous code generation inputs
- Add a disambiguation workflow that identifies when multiple component matches exist
- Require explicit user confirmation before generating codes when any component is ambiguous
- Only allow the agent to make guesses when the user explicitly states they don't know
- Implement iterative clarification - if the user's answer remains ambiguous, ask again for more specific information
- Update the agent's workflow to parse user descriptions, identify component matches, and surface options before calling save_procurement_code

## Capabilities

### New Capabilities
- `code-disambiguation`: A capability that provides structured disambiguation for code generation components, including parsing user descriptions, identifying multiple plausible matches for each component, and presenting options to users for confirmation before generation

### Modified Capabilities
- `procurement-agent`: Modify the agent's workflow to enforce the confirm-before-generate pattern, requiring all components to be unambiguous before proceeding with code generation

## Impact

- **Agent Behavior**: The agent will no longer silently guess or infer ambiguous inputs; it must explicitly ask for clarification
- **User Experience**: Users will see clarification prompts with options before any code is generated, reducing the need for corrections
- **Tool Flow**: The agent workflow will include a new disambiguation step between parsing the user's description and calling save_procurement_code
- **Code Generation Logic**: May need a new disambiguation tool or enhanced prompt patterns to support the confirm-before-generate workflow
- **Testing**: Will require new test cases covering ambiguous inputs and the clarification flow

## Specifications

code-disambiguation/spec.md
# code-disambiguation Specification

## Purpose
The code disambiguation capability ensures that procurement codes are only generated after all required components are unambiguous and confirmed by the user. This prevents the generation of incorrect codes and improves user experience by surfacing clarification options before any code is created.

## Requirements

### Requirement: Parse User Description for Component Extraction
The system MUST parse the user's description to identify the best match for each of the 8 required code components (Major Category, Manufacturing Method, Object Shape, Material Type, Quality Grade, Size Category, Year, Daily Sequence).

#### Scenario: Successful Component Extraction
- **WHEN** the user provides a clear, unambiguous description
- **THEN** the system MUST identify a single best match for each component
- **AND** all components MUST be marked as unambiguous

#### Scenario: Ambiguous Component Detection
- **WHEN** the user's description could match multiple valid options for a component
- **THEN** the system MUST identify all plausible matches (2 or more)
- **AND** the component MUST be marked as ambiguous

### Requirement: Identify Multiple Plausible Matches
The system MUST identify when a component has 2 or more plausible matches from the CODE_GENERATION.md rules and list these options for user clarification.

#### Scenario: Single Match Found
- **WHEN** a component has exactly one plausible match
- **THEN** the component MUST be considered unambiguous
- **AND** no clarification is required for that component

#### Scenario: Multiple Matches Found
- **WHEN** a component has 2 or more plausible matches
- **THEN** the system MUST list all matching options with their descriptions
- **AND** the component MUST be marked as requiring clarification

#### Scenario: No Matches Found
- **WHEN** a component has no plausible matches
- **THEN** the system MUST indicate that no valid options were found
- **AND** the component MUST be marked as requiring clarification

### Requirement: Present Clarification Options to User
The system MUST present clarification options to the user in a structured format that the UI can render, listing all plausible matches for ambiguous components.

#### Scenario: Single Ambiguous Component
- **WHEN** exactly one component is ambiguous
- **THEN** the system MUST present the options for that component only
- **AND** the user MUST be able to select from the listed options

#### Scenario: Multiple Ambiguous Components
- **WHEN** multiple components are ambiguous
- **THEN** the system MUST present options for all ambiguous components
- **AND** each component's options MUST be clearly separated
- **AND** the user MUST be able to select options for each component

#### Scenario: Structured Option Format
- **WHEN** presenting clarification options
- **THEN** each option MUST include the component name, the option code/value, and a clear description
- **AND** the format MUST be parseable by the UI for rendering

### Requirement: Enforce Confirm-Before-Generate Pattern
The system MUST NOT generate or save any procurement code until all 8 components are unambiguous and confirmed by the user.

#### Scenario: All Components Unambiguous
- **WHEN** all 8 components are unambiguous after parsing
- **THEN** the system MAY proceed to code generation
- **AND** the user MUST be presented with the complete code for final confirmation

#### Scenario: Any Component Ambiguous
- **WHEN** any component is ambiguous
- **THEN** the system MUST NOT generate any code
- **AND** the system MUST present clarification options to the user
- **AND** the system MUST wait for user confirmation before proceeding

#### Scenario: Save Procurement Code Blocked
- **WHEN** the agent attempts to call `save_procurement_code` with ambiguous components
- **THEN** the system MUST reject the save with a clear error message indicating which components need clarification
- **AND** the code MUST NOT be saved to the state

### Requirement: Allow Explicit User-Initiated Guessing
The system MUST only allow the agent to make guesses when the user explicitly states they don't know or provides insufficient information.

#### Scenario: User Explicitly States They Don't Know
- **WHEN** the user explicitly states "I don't know" or similar for a component
- **THEN** the system MAY use the most likely match based on context
- **AND** the system MUST inform the user which option was selected as a guess
- **AND** the system MUST mark the component as "guessed" for tracking purposes

#### Scenario: User Provides Insufficient Information
- **WHEN** the user provides minimal or unclear information for a component
- **THEN** the system MUST ask for clarification
- **AND** the system MUST NOT make a guess unless the user explicitly requests it

#### Scenario: No Explicit Guess Permission
- **WHEN** the user has not explicitly stated they don't know
- **THEN** the system MUST NOT make any guesses
- **AND** the system MUST continue to ask for clarification until the user provides sufficient information

### Requirement: Implement Iterative Clarification
The system MUST continue to ask for clarification if the user's answer remains ambiguous, ensuring all components are unambiguous before code generation.

#### Scenario: User Provides Still-Ambiguous Answer
- **WHEN** the user provides an answer that still has multiple plausible matches
- **THEN** the system MUST ask for further clarification
- **AND** the system MUST present the narrowed-down options
- **AND** the system MUST NOT proceed to code generation

#### Scenario: User Provides Clear Answer
- **WHEN** the user provides an answer that results in a single unambiguous match
- **THEN** the component MUST be marked as unambiguous
- **AND** the system MUST proceed to check other components

#### Scenario: Multiple Clarification Rounds
- **WHEN** clarification requires multiple rounds of user interaction
- **THEN** the system MUST maintain context across rounds
- **AND** the system MUST track which components have been clarified
- **AND** the system MUST only ask about remaining ambiguous components

### Requirement: Track Component Ambiguity Status
The system MUST track the ambiguity status of each component throughout the disambiguation workflow to ensure proper workflow enforcement.

#### Scenario: Initial Component Status
- **WHEN** the system first parses the user's description
- **THEN** each component MUST be marked as either "unambiguous" or "ambiguous"
- **AND** ambiguous components MUST list all plausible matches

#### Scenario: Component Clarification Update
- **WHEN** the user provides clarification for an ambiguous component
- **THEN** the component's status MUST be updated to "unambiguous" if a single match is found
- **OR** the component MUST remain "ambiguous" if multiple matches persist
- **AND** the list of plausible matches MUST be updated accordingly

#### Scenario: Complete Ambiguity Resolution
- **WHEN** all components are marked as "unambiguous"
- **THEN** the system MUST indicate that disambiguation is complete
- **AND** the system MUST allow code generation to proceed

procurement-agent/spec.md
# procurement-agent Specification (Delta)

## MODIFIED Requirements

### Requirement: Enforce Procurement Workflow
The agent MUST strictly follow a defined workflow to ensure accurate procurement code generation and use all required tools. The workflow SHALL be enforced programmatically, not just through system prompt instructions. The workflow MUST include a disambiguation step where the agent identifies ambiguous components and asks for user clarification before generating codes.

#### Scenario: Agent Initialization
Given the agent starts up
Then it must load the necessary tools (`read_code_generation_file`, `save_procurement_code`, `reset_conversation`)
And it must have the specific System Prompt loaded
And the ProcurementState MUST include a `rules_loaded_this_turn` flag that defaults to False

#### Scenario: Rule File Read Enforcement
Given the agent receives a code generation request
When the agent calls `read_code_generation_file` and it succeeds
Then the `rules_loaded_this_turn` flag MUST be set to True
And the agent MUST proceed to the disambiguation step

#### Scenario: Disambiguation Step
Given the agent has successfully called `read_code_generation_file`
When the agent parses the user's description
Then the agent MUST identify all 8 code components
And the agent MUST check each component for ambiguity
And if ANY component has 2 or more plausible matches
Then the agent MUST present clarification options to the user
And the agent MUST NOT proceed to code generation until all components are unambiguous

#### Scenario: Rule File Read Failure
Given the agent calls `read_code_generation_file`
When the file read fails (file not found or read error)
Then the system MUST raise an exception with a clear error message
And the `rules_loaded_this_turn` flag MUST remain False
And the agent MUST NOT proceed with code generation

#### Scenario: Save Validation with Disambiguation
Given the agent attempts to call `save_procurement_code`
When the `rules_loaded_this_turn` flag is False
Then the system MUST return an error message: "ERROR: You must call read_code_generation_file before saving a code."
And the code MUST NOT be saved to the state

#### Scenario: Save Validation with Ambiguous Components
Given the agent has successfully called `read_code_generation_file`
And the agent attempts to call `save_procurement_code`
When any component remains ambiguous
Then the system MUST return an error message indicating which components need clarification
And the code MUST NOT be saved to the state

#### Scenario: Successful Save After Disambiguation
Given the agent has successfully called `read_code_generation_file`
And all 8 components are unambiguous and confirmed by the user
When the agent calls `save_procurement_code`
Then the system MUST save the code to the state
And return a success message

### Requirement: Programmatic Workflow Enforcement
The agent MUST enforce the workflow programmatically, not just through system prompt instructions. The workflow MUST include disambiguation checks before code generation.

#### Scenario: Rules File Read Enforcement
Given the agent needs to generate a procurement code
When the agent attempts to save a code without first reading the rules file
Then the `save_procurement_code` tool MUST reject the save with a clear error message
And the agent MUST call `read_code_generation_file` before proceeding

#### Scenario: Disambiguation Enforcement
Given the agent has successfully called `read_code_generation_file`
When the agent attempts to generate a code without clarifying ambiguous components
Then the agent MUST identify which components are ambiguous
And the agent MUST present clarification options to the user
And the agent MUST NOT proceed to code generation until all components are unambiguous

#### Scenario: Error Handling on File Read Failure
Given the agent calls `read_code_generation_file`
When the rules file cannot be found or read
Then the tool MUST raise an appropriate exception (FileNotFoundError or general Exception)
And the agent MUST handle the exception appropriately

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
And the previous request state MUST NOT affect the new request

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

### Requirement: Tool Availability
The `query_rag_system` tool MUST be available to the agent for citation purposes.

#### Scenario: Calling RAG Tool
Given the agent is initialized
When the agent needs to verify a fact
Then it can call `query_rag_system` with a query string



## Design

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

## Current Task Context

## Current Task
- 4.5 Write unit tests for guess marking and notification
## Completed Tasks for Git Commit
- [x] 1.1 Create `AmbiguityInfo` data class to track component ambiguity status (status, options, selected value)
- [x] 1.2 Extend `ProcurementState` with `component_ambiguity_status` field (Dict[str, AmbiguityInfo])
- [x] 1.3 Add validation logic to ensure state transitions are valid (ambiguous → unambiguous)
- [x] 1.4 Write unit tests for state management and ambiguity tracking
- [x] 2.1 Implement component extraction logic to parse user descriptions against CODE_GENERATION.md rules
- [x] 2.2 Implement ambiguity detection logic to identify when a component has 2+ plausible matches
- [x] 2.3 Implement keyword-based matching for component options
- [x] 2.4 Implement semantic similarity scoring for component options (initial version)
- [x] 2.5 Add logic to handle "no matches found" scenario
- [x] 2.6 Write unit tests for component extraction with clear inputs
- [x] 2.7 Write unit tests for ambiguity detection with ambiguous inputs
- [x] 2.8 Write unit tests for edge cases (no matches, single match, multiple matches)
- [x] 3.1 Implement `clarify_components` tool in `agent.py`
- [x] 3.2 Add tool to agent's available tools list
- [x] 3.3 Implement JSON output format for structured disambiguation options
- [x] 3.4 Add logic to filter and present only ambiguous components
- [x] 3.5 Add logic to include unambiguous components in output for context
- [x] 3.6 Write unit tests for `clarify_components` tool
- [x] 3.7 Write integration tests for tool with various input scenarios
- [x] 4.1 Implement phrase detection for explicit guess permission ("I don't know", "whatever", "you choose")
- [x] 4.2 Add logic to mark components as "guessed" when permission detected
- [x] 4.3 Implement user notification when a guess is made
- [x] 4.4 Write unit tests for guess permission detection
