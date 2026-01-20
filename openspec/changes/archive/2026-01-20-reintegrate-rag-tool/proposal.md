# Proposal: Reintegrate RAG Tool

## Description
This proposal aims to reintegrate the `query_rag_system` tool into the `ProcurementCodeSuggestorAgent`. The tool was previously present but commented out due to "Index not found" errors. This change will restore the functionality, enabling the agent to provide citations from the knowledge base, while also hardening the index loading mechanism to be robust against different execution contexts (CWD).

## Motivation
The `query_rag_system` is critical for providing accurate citations for procurement codes. Without it, the agent cannot strictly adhere to the "CITATIONS ONLY" rule for verifying information. Reintegrating it aligns with the original design intent and improves the agent's reliability.

## Proposed Solution
1.  **Robust Index Loading**: Modify `agent/src/rag/index.py` to dynamically locate the `agent/data/storage` directory, inspecting multiple potential paths relative to the current working directory and the file location.
2.  **Restore Tool Code**: Uncomment and enable the `get_rag_tool`, `rag_engine_tool`, and `query_rag_system` definitions in `agent/src/agent.py`.
3.  **Register Tool**: Add `query_rag_system` to the agent's tool list.
4.  **Verification**: Verify that the tool loads correctly and can be called by the agent without "Index not found" errors.
