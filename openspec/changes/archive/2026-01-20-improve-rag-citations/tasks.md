# Tasks: Improve RAG Citations

- [x] Update `NodeCitationProcessor` in `agent/src/rag/citation.py` to use numbered citations (1, 2, 3...) instead of UUIDs.
- [x] Prepend "Source N:" labels to node text for clarity.
- [x] Verify the agent output now produces readable citations like `[citation:1]`, `[citation:2]` with source previews.
