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

All development and testing files must be placed in the `test/` directory located at the project root. This includes:

- **Test files**: Files matching `test*.py` pattern (e.g., `test_agent_tools.py`, `test_complete_workflow.py`)
- **Debug files**: Files matching `debug*.py` pattern (e.g., `debug_parsing.py`, `debug_component_extraction.py`)
- **Check files**: Files matching `check*.py` pattern (e.g., `check_version.py`)
- **Measure files**: Files matching `measure*.py` pattern (e.g., `measure_startup_time.py`)
- **Performance files**: Files matching `performance*.py` or `env_performance*.py` patterns (e.g., `performance_test.py`, `env_performance_test.py`)
- **Verify files**: Files matching `verify*.py` pattern (e.g., `verify_datetime_fix.py`, `verify_flag_reset.py`)
- **Validate files**: Files matching `validate*.py` pattern (e.g., `validate_similarity_threshold.py`)

**Naming Conventions:**

- Test files: Use `test_*.py` prefix
- Debug files: Use `debug_*.py` prefix
- Check files: Use `check_*.py` prefix
- Measure files: Use `measure_*.py` prefix
- Performance files: Use `performance_*.py` or `env_performance_*.py` prefix
- Verify files: Use `verify_*.py` prefix
- Validate files: Use `validate_*.py` prefix

**Running Tests:**

When running test files from the `test/` directory, ensure proper import paths. Most files can be run directly with `python test/your_test_file.py` from the project root, or by navigating to the `test/` directory first.

### OpenSpec Development Workflow

Development through OpenSpec is driven by Ralph loops (automated AI-driven development workflows). When creating new OpenSpec changes:

- **Task Design**: Create tasks that can be executed autonomously without human interaction
- **Clear Instructions**: Provide detailed, unambiguous task descriptions that enable automated execution
- **Self-Contained Tasks**: Each task should have all necessary information to complete independently
- **Verifiable Outcomes**: Tasks should produce clear, measurable results that can be automatically validated
- **Minimal Dependencies**: Design tasks to minimize dependencies on external factors or manual interventions

**Goal**: Enable Ralph loops to implement changes end-to-end with minimal human oversight, accelerating development while maintaining quality.

### Git Workflow

TODO: Describe your branching strategy and commit conventions.

## Domain Context

The current domain involves:

- **Procurement Codes**: The agent suggests appropriate procurement codes.
- **.env.copy**: Check instead of ".env" for env structure.

## Existing Code

- `agent/src/agent.py`: Defines the `agent` instance and its tools. It uses OpenAI's model (defaulting to `deepseek-chat`).
- `agent/src/main.py`: Entry point that converts the agent to an ASGI app and runs it with Uvicorn.
- `agent/pyproject.toml`: Project configuration and dependencies.

## Important Constraints

- **Environment Variables**: Requires `OPENAI_API_KEY`, `OPENAI_BASE_URL` (optional), and `OPENAI_MODEL` (optional) to be set.

## External Dependencies

- **DeepSeek API**: The primary LLM provider (using `deepseek-chat`), accessed via the OpenAI client compatibility layer (`OPENAI_BASE_URL`).
