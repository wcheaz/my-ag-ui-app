# Project Context

## Purpose
This project implements an AI agent using Pydantic AI, designed to be served via a UI. The **Procurement Agent** is tasked with suggesting procurement codes based on user input.

## Tech Stack
- Python 3.12+
- Pydantic AI (with `ag-ui` and `openai` extras)
- Uvicorn (ASGI server)
- Logfire (Observability)
- python-dotenv (Environment variable management)
- LlamaIndex (RAG)

## Project Conventions

### Code Style
- **Formatting**: Adhere to PEP 8 standards.
- **Typing**: Enforce strict typing. Use Pydantic models for state and data validation.
- **Imports**: Group imports logically (standard library, third-party, local).
- **Naming**: Use names related to "procurement code agents" for functions and classes.

### Architecture Patterns
- **Agentic Design**: Use `pydantic_ai.Agent` for defining agent behavior.
- **State Management**: Use Pydantic models to define and track agent state.
- **Dependency Injection**: Use `RunContext` to inject state and dependencies into tools.
- **ASGI**: The agent is exposed as an ASGI app using `agent.to_ag_ui()`.
- **RAG**: Use LlamaIndex for Retrieval-Augmented Generation.

### Testing Strategy
[Explain your testing approach and requirements]

### Git Workflow
[Describe your branching strategy and commit conventions]

## Domain Context
The current domain involves:
- **Procurement Codes**: The agent suggests appropriate procurement codes.

## Existing Code
- `agent/src/agent.py`: Defines the `agent` instance and its tools. It uses OpenAI's model (defaulting to `deepseek-chat`).
- `agent/src/main.py`: Entry point that converts the agent to an ASGI app and runs it with Uvicorn.
- `agent/pyproject.toml`: Project configuration and dependencies.

## Important Constraints
- **Environment Variables**: Requires `OPENAI_API_KEY`, `OPENAI_BASE_URL` (optional), and `OPENAI_MODEL` (optional) to be set.

## External Dependencies
- **DeepSeek API**: The primary LLM provider (using `deepseek-chat`), accessed via the OpenAI client compatibility layer (`OPENAI_BASE_URL`).
