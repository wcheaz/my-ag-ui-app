# Improve RAG Citations Proposal

## Diagnosis
The current RAG system generates citations using internal UUIDs (e.g., `[citation:0c33c2fc-ae5c-4248-9e9a-3a208fa61ddc]`) which are not human-readable. This occurs because the `NodeCitationProcessor` in `agent/src/rag/citation.py` copies the `node_id` (a UUID) directly into the `citation_id` metadata field.

### Research Findings
After inspecting the node metadata and reviewing LlamaIndex's citation documentation, I found:
1. **Available metadata** includes only: `file_name`, `file_path`, `file_type`, `file_size`, and dates - no page numbers or section headers
2. **Filename-only citations** (e.g., `[citation:CODE_GENERATION.md]`) are too broad for large documents
3. **LlamaIndex's recommended approach** uses numbered sources (e.g., `Source 1:`, `Source 2:`) by splitting retrieved chunks into smaller citation units

## Solution Overview
Implement **numbered source citations** following LlamaIndex best practices:

1.  **Modify `NodeCitationProcessor`**: Update to assign sequential numbers (1, 2, 3...) as citation IDs instead of UUIDs
2.  **Prepend source labels**: Modify node text to include `Source N:` prefix for clarity
3.  **Result**: Citations like `[citation:1]`, `[citation:2]` that map to specific text chunks

This provides:
- **Human-readable** citation numbers
- **Granular attribution** for large documents (multiple citations per file)
- **Consistency** with LlamaIndex patterns

## Scope
- `agent/src/rag/citation.py`: Update `NodeCitationProcessor` to use numbered citations
- No changes to other files required

---

## Update: Citation System Removed (2026-01-20)

This OpenSpec change was implemented and tested, but the citation system was ultimately removed from the agent. The implementation worked technically, but citations proved to be misleading because the agent reads the full `CODE_GENERATION.md` document directly rather than using RAG for information retrieval.

For a detailed explanation of why the citation system was removed, see: [`agent/hidden/RAG-REMOVAL-EXPLANATION.md`](../../agent/hidden/RAG-REMOVAL-EXPLANATION.md)

The code has been preserved (commented out) in `agent/src/agent.py` for future reference.
