# Design: Procurement Agent Architecture

## Overview
The solution integrates `Pydantic AI` (for the agent loop and tool calling) with `LlamaIndex` (for RAG and document citation). 

## Architecture

### Components
1.  **CopilotKit Frontend (Existing)**: Sends messages to backend.
2.  **Pydantic AI Middleware (`agent/src/main.py`)**: Receives requests, instantiates Agent.
3.  **Agent (`ProcurementCodeSuggestorAgent`)**:
    -   **System Prompt**: Enforces strict workflow (Read -> Cite -> Generate).
    -   **Tools**:
        -   `read_code_generation_file`: Reads the guidebook.
        -   `rag_query`: Queries the vector index for citations.
4.  **LlamaIndex Storage**: Stores vector embeddings of the guidebook.

### Data Flow
1.  User request -> Frontend -> Backend.
2.  Agent checks history/state.
3.  **Mandatory Step**: Agent calls `read_code_generation_file`.
4.  Agent may call `rag_query` for citations.
5.  Agent generates response with citations and code.

### Context Management Strategy
To meet the requirement "context of the old code should be removed", we will implement a mechanisms to detect completion of a request.
-   *Option 1*: Modify `main.py` handle a "reset" flag or API endpoint.
-   *Option 2*: Since Frontend controls history, we rely on the Agent's internal `deps` state to track "current request" status. When a new request comes (detected by semantic change or explicit user intent), the Agent will be instructed via System Prompt to ignore previous specific code context, effectively "resetting" its internal focus. Truly clearing the context window requires frontend cooperation or a backend middleware that truncates `messages` list. We will assume the `ag-ui` might not support explicit history truncation easily, so we will focus on **System Prompt enforcement of "Memory Reset"** as described in the reference implementation.

## Trade-offs
-   **LlamaIndex vs Pydantic AI Tools**: We wrap LlamaIndex query engines as Pydantic functions. This adds a slight layer of complexity but leverages the strong RAG capabilities of LlamaIndex.
-   **Context Window**: We are limited by the model's context window. DeepSeek has 128k, which is generous. 

## Dependencies
-   `llama-index`
-   `pydantic-ai`
-   `openai` (for DeepSeek compatibility)
