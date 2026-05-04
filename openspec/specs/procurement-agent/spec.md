# procurement-agent Specification

## Purpose
The procurement agent generates standardized procurement codes based on the CODE_GENERATION.md rules. The agent enforces a strict workflow where rules must be read before codes can be generated and saved, ensuring accuracy and consistency.
## Requirements
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

