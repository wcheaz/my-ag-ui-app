# Citation Readability Specification

## ADDED Requirements

### Requirement: Human-Readable Citations
The system MUST provide citations that allow a human user to easily identify the source of information using numbered references.

#### Scenario: Numbered Source Citations
- **Given** the RAG system retrieves multiple text chunks
- **When** it generates a response with citations
- **Then** each chunk must be assigned a sequential number (1, 2, 3...)
- **And** citations must use the format `[citation:1]`, `[citation:2]`, etc.
- **And** the node text must be prepended with `Source N:` for clarity

#### Scenario: Multiple Citations Per Document
- **Given** a large document is split into multiple chunks
- **When** multiple chunks are retrieved from the same file
- **Then** each chunk must have a unique numbered citation
- **And** users can distinguish between different parts of the same document
