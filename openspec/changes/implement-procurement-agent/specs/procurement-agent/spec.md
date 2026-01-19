# Spec: Procurement Agent Logic

## ADDED Requirements

### Requirement: Enforce Procurement Workflow
The agent MUST strictly follow a defined workflow to ensure accurate procurement code generation.

#### Scenario: Agent Initialization
- **Given** the agent starts up
- **Then** it must load the necessary tools (`read_code_generation_file`, `rag_query`).
- **And** it must have the specific System Prompt from `create-llama-test` loaded.

#### Scenario: Mandatory Guidebook Reading
- **Given** a user asks for a procurement code
- **Then** the agent MUST call `read_code_generation_file` before providing any code.
- **And** the agent must confirm "I have now read the document..." before proceeding.

#### Scenario: Context Reset
- **Given** a user has just received a procurement code
- **When** the user asks for a *new* procurement code
- **Then** the agent must behave as if it is a fresh request, re-reading the guidebook.
- **And** it must not hallucinate based on the previous code's specific details.

#### Scenario: Citation formatting
- **Given** the agent provides information from the RAG tool
- **Then** it must include inline citations in the format `[citation:id]`.
