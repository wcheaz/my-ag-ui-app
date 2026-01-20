# procurement-agent Specification

## Purpose
TBD - created by archiving change implement-procurement-agent. Update Purpose after archive.
## Requirements
### Requirement: Enforce Procurement Workflow
The agent MUST strictly follow a defined workflow to ensure accurate procurement code generation and use all required tools.

#### Scenario: Agent Initialization
Given the agent starts up
Then it must load the necessary tools (`read_code_generation_file`, `query_rag_system`, `save_procurement_code`, `reset_conversation`).
And it must have the specific System Prompt from `create-llama-test` loaded.

### Requirement: Tool Availability
The `query_rag_system` tool MUST be available to the agent for citation purposes.

#### Scenario: Calling RAG Tool
Given the agent is initialized
When the agent needs to verify a fact
Then it can call `query_rag_system` with a query string

