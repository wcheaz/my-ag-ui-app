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