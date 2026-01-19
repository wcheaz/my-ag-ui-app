# Tasks

- [ ] **Environment Setup**: Port necessary environment variables (`LLM_MAX_TOKENS`, `LLM_CONTEXT_WINDOW`, `EMBEDDING_MODEL`) from reference project to `.env`. <!-- id: 0 -->
- [ ] **Data Migration**: Copy `CODE_GENERATION.md` to `agent/data/CODE_GENERATION.md`. <!-- id: 1 -->
- [ ] **RAG Infrastructure**: Port `src/index.py`, `src/citation.py`, `src/settings.py` (and related) to `agent/src/` adapting as necessary. <!-- id: 2 -->
- [ ] **Agent Implementation**: 
    - [ ] Create `agent/src/agent.py` identifying `ProcurementCodeSuggestorAgent`.
    - [ ] Implement `read_code_generation_file` tool.
    - [ ] Implement `get_rag_tool` using LlamaIndex.
    - [ ] Inject the comprehensive system prompt.
- [ ] **Context Logic**: Implement logic to handle session resets (e.g., via `deps` or explicit instructions). <!-- id: 3 -->
- [ ] **Verification**: Run `uv run generate` (if needed) to index data, then start app and verify behavior in UI. <!-- id: 4 -->
