# rag-support Specification

## Purpose
TBD - created by archiving change implement-procurement-agent. Update Purpose after archive.
## Requirements
### Requirement: RAG Infrastructure
The system MUST provide a robust RAG infrastructure to support the agent's knowledge retrieval needs.

#### Scenario: Index Loading
- **Given** the application starts
- **Then** it must attempt to load the LlamaIndex storage from a persistent directory.
- **If** the index is missing, it should either auto-generate it or fail gracefully with a helpful message.

#### Scenario: Direct Citation
- **Given** the RAG query tool is called
- **Then** it must return chunks with specific `citation_id` metadata.
- **And** the `citation_system_prompt` must be enforced to ensure accurate citation usage.

