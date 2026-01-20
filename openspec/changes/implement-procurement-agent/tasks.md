# Tasks

1.  **Environment Setup** <!-- id: 0 -->
    1.1. [x] Read `create-llama-test/.env` to identify required variables (`LLM_MAX_TOKENS`, `EMBEDDING_MODEL`).
    1.2. [x] Check `my-ag-ui-app/.env` for existing variables.
    1.3. [x] Append missing variables to `my-ag-ui-app/.env`.
    1.4. [x] Verify `OPENAI_API_KEY` and `OPENAI_BASE_URL` are set correctly for DeepSeek.

2.  **Data Migration** <!-- id: 1 -->
    2.1. [x] Create directory `agent/data/`.
    2.2. [x] Copy `create-llama-test/ui/data/CODE_GENERATION.md` to `agent/data/CODE_GENERATION.md`.
    2.3. [x] Create directory `agent/data/storage/`.
    2.4. [x] Copy contents of `create-llama-test/src/storage/` to `agent/data/storage/`.

3.  **Dependencies** <!-- id: 2 -->
    3.1. [x] Add `llama-index-core` to `agent/pyproject.toml`.
    3.2. [x] Add `llama-index-readers-file` to `agent/pyproject.toml`.
    3.3. [x] Add `llama-index-embeddings-huggingface` to `agent/pyproject.toml`.
    3.4. [x] Add `llama-index-llms-deepseek` to `agent/pyproject.toml`.
    3.5. [x] Run `uv sync` to install dependencies.

4.  **RAG Infrastructure Porting** <!-- id: 3 -->
    4.1. [x] Create directory `agent/src/rag/`.
    4.2. [x] Copy `create-llama-test/src/index.py` into `agent/src/rag/`.
    4.3. [x] Edit `agent/src/rag/index.py`: Update `STORAGE_DIR` to point to `agent/data/storage`.
    4.4. [x] Copy `create-llama-test/src/citation.py` into `agent/src/rag/`.
    4.5. [x] Copy `create-llama-test/src/settings.py` into `agent/src/rag/`.
    4.6. [x] Edit `agent/src/rag/settings.py`: Adapt to use `OPENAI_` environment variables from `my-ag-ui-app/.env`.

5.  **Agent Implementation** <!-- id: 4 -->
    5.1. [ ] Create `ProcurementState` class definition in `agent/src/agent.py`.
    5.2. [ ] Implement `read_code_generation_file` tool function in `agent/src/agent.py`.
    5.3. [ ] Import RAG modules (`get_index`, `init_settings`, `enable_citation`, `get_query_engine_tool`) in `agent/src/agent.py`.
    5.4. [ ] Implement `get_rag_tool` function to initialize the QueryEngineTool.
    5.5. [ ] Retrieve the strict System Prompt from `create-llama-test/src/workflow_with_embeddings.py`.
    5.6. [ ] Replace the existing `SystemPrompt` in `agent/src/agent.py` with the retrieved prompt.
    5.7. [ ] Instantiate the `ProcuementCodeSuggestorAgent` with the tools and system prompt.

6.  **Automatic Context Reset Logic** <!-- id: 5 -->
    6.1. [ ] Implement logic in `agent/src/agent.py` to detect "new request" intent (e.g., regex for "code", "procurement", or purely new session).
    6.2. [ ] Add mechanism to clear `ctx.message_history` or equivalent when a new request is detected.
    6.3. [ ] Verify that context reset happens invisibly to the user (no UI interaction required).

7.  **Verification** <!-- id: 6 -->
    7.1. [ ] Start the application: `./manage_app.sh start`.
    7.2. [ ] Open web UI.
    7.3. [ ] Submit query: "I need a code for a steel pipe".
    7.4. [ ] Check output for "Document content preview: ..." (Tool Usage).
    7.5. [ ] Check output for inline citations `[citation:...]`.
    7.6. [ ] Submit follow-up: "actually, make it copper". (Should result in context usage).
    7.7. [ ] Submit NEW request: "I need a code for a plastic toy".
    7.8. [ ] Verify that the previous "steel pipe" context is ignored/cleared.
