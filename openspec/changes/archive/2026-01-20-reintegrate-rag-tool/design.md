# Design: Robust RAG Integration

## Problem
The `get_index` function in `agent/src/rag/index.py` currently uses a hardcoded relative path `agent/data/storage`. This causes "Index not found" errors if the agent is executed from a directory other than the project root (e.g., `agent/`).

## Solution: Dynamic Path Resolution
We will implement a path resolution strategy similar to `load_env` or `read_code_generation_file`.

The `get_index` function should check the following locations for `storage/index_store.json` (or just the directory existence):
1.  `os.path.join(os.getcwd(), "agent", "data", "storage")` (Project root execution)
2.  `os.path.join(os.getcwd(), "data", "storage")` (Agent dir execution)
3.  `os.path.join(os.path.dirname(__file__), "..", "..", "data", "storage")` (Relative to `index.py`)

## Architecture
- **`agent/src/rag/index.py`**:
    -   Update `STORAGE_DIR` to be determined dynamically.
    -   Add logging to indicate where the index was found (or where checks failed).
- **`agent/src/agent.py`**:
    -   Uncomment imports and tool definitions.
    -   Ensure `query_rag_system` handles `None` index gracefully (already present in `.bak` logic).

## Trade-offs
-   **Complexity vs Reliability**: Adding dynamic path resolution adds slight complexity but significantly improves reliability across different dev/prod environments and test runners.
