# procurement-agent Specification

## Purpose
The procurement agent generates standardized procurement codes based on the CODE_GENERATION.md rules. The agent enforces a strict workflow where rules must be read before codes can be generated and saved, ensuring accuracy and consistency.
## Requirements
### Requirement: Enforce Procurement Workflow
The agent MUST strictly follow a defined workflow to ensure accurate procurement code generation and use all required tools.

#### Scenario: Agent Initialization
Given the agent starts up
Then it must load the necessary tools (`read_code_generation_file`, `query_rag_system`, `save_procurement_code`, `reset_conversation`).
And it must have the specific System Prompt from `create-llama-test` loaded.

### Requirement: Programmatic Workflow Enforcement
The agent MUST enforce the workflow programmatically, not just through system prompt instructions.

#### Scenario: Rules File Read Enforcement
Given the agent needs to generate a procurement code
When the agent attempts to save a code without first reading the rules file
Then the `save_procurement_code` tool MUST reject the save with a clear error message
And the agent MUST call `read_code_generation_file` before proceeding

#### Scenario: Error Handling on File Read Failure
Given the agent calls `read_code_generation_file`
When the rules file cannot be found or read
Then the tool MUST raise an appropriate exception (FileNotFoundError or general Exception)
And the agent MUST handle the exception appropriately

### Requirement: Tool Availability
The `query_rag_system` tool MUST be available to the agent for citation purposes.

#### Scenario: Calling RAG Tool
Given the agent is initialized
When the agent needs to verify a fact
Then it can call `query_rag_system` with a query string

