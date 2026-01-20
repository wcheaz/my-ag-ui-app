# Proposal: Implement Procurement Code Suggestor Agent

## Goal
Replace the existing demo agent with a robust `ProcurementCodeSuggestorAgent` that leverages a LlamaIndex RAG system and a specific guidebook (`CODE_GENERATION.md`) to suggest procurement codes. The agent must strictly follow a defined workflow, utilizing citations and maintaining context only for the duration of a single code request.

## Requirements
- **Core Agent**: Implement a Pydantic AI agent `ProcurementCodeSuggestorAgent`.
- **RAG Integration**: Port and adapt the LlamaIndex-based RAG workflow from `create-llama-test`.
- **Guidebook Access**: Incorporate `CODE_GENERATION.md` and the `read_code_generation_file` tool.
- **Context Management**: Ensure conversation history is effectively reset between code generation requests.
- **System Prompts**: strict adherence to the system prompts defined in the reference project.
- **Configuration**: Use existing `.env` values, porting missing ones from the reference project.
- **Frontend Compatibility**: Seamlessly integrate with the existing CopilotKit frontend.

## Team
- **Owner**: User
- **Implementer**: Antigravity

## Timeline
- **Start**: Immediate
- **Completion**: Upon successful verification of the agent in the `ag-ui`.
