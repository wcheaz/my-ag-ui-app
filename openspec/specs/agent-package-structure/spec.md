## ADDED Requirements

### Requirement: Package preserves the public import contract
After `agent/src/agent.py` is replaced by `agent/src/agent/__init__.py`, the statement `from src.agent import ProcurementState, StateDeps, agent` SHALL resolve without error and return the same types and objects as before the split.

#### Scenario: main.py imports work unchanged
- **WHEN** `from src.agent import ProcurementState, StateDeps, agent` is executed
- **THEN** `ProcurementState` is the Pydantic model class, `StateDeps` is `pydantic_ai.ag_ui.StateDeps` parameterized with `ProcurementState`, and `agent` is a `pydantic_ai.Agent` instance

#### Scenario: StateDeps is correctly parameterized
- **WHEN** `StateDeps(state=ProcurementState())` is constructed
- **THEN** the resulting object is accepted by `agent.to_ag_ui(deps=...)` without error

### Requirement: Original agent.py file is removed
The file `agent/src/agent.py` SHALL NOT exist after the split. Only the package directory `agent/src/agent/` SHALL exist.

#### Scenario: No stale module file
- **WHEN** `os.path.exists("agent/src/agent.py")` is checked
- **THEN** the result is `False`

#### Scenario: Package directory exists
- **WHEN** `os.path.isdir("agent/src/agent")` is checked
- **THEN** the result is `True`

### Requirement: Submodules contain correct code groups
The package SHALL contain submodules with the following contents, with no code omitted or duplicated:

| Submodule | SHALL contain |
|---|---|
| `models.py` | `ProcurementCode`, `AmbiguityInfo`, `ProcurementState` and all its methods |
| `matching.py` | `parse_code_generation_rules`, `find_component_matches`, `_get_filter_reason`, `extract_components_from_description`, `get_component_extraction_results`, `validate_options_similarity_threshold`, `detect_explicit_guess_permission`, `calculate_semantic_similarity` |
| `tools.py` | `read_code_generation_file`, `clarify_components`, `save_procurement_code`, `reset_conversation`, `get_rag_tool`, `query_rag_system`, `get_citation_sources`, `detect_component_ambiguity`, `format_guess_notification` |
| `metrics.py` | `DisambiguationMetrics`, `get_disambiguation_metrics`, `log_disambiguation_metrics_summary`, and the `disambiguation_logger` setup |
| `prompt.py` | `STATIC_SYSTEM_PROMPT` string literal |
| `model.py` | `LoggingOpenAIModel`, `load_dotenv` call, env-var loading, `model` instance, `agent` instance |

#### Scenario: All public symbols remain importable
- **WHEN** each symbol listed above is imported from its submodule (e.g., `from src.agent.models import ProcurementState`)
- **THEN** the import succeeds and the symbol is the same object or class as in the original `agent.py`

#### Scenario: No symbol is lost during the split
- **WHEN** the union of all symbols across all submodules is compared to the symbols defined in the original `agent.py`
- **THEN** every non-import, non-dunder symbol from the original file is present in exactly one submodule

### Requirement: No circular imports exist
The import graph among the submodules SHALL form a directed acyclic graph. No submodule SHALL import from `model.py`.

#### Scenario: All submodules are importable
- **WHEN** Python imports `src.agent.models`, `src.agent.matching`, `src.agent.tools`, `src.agent.metrics`, `src.agent.prompt`, and `src.agent.model` in sequence
- **THEN** no `ImportError` or circular-import `RuntimeWarning` is raised

### Requirement: Module-level side effects are preserved
All module-level side effects present in the original `agent.py` SHALL continue to execute at the same point in application startup.

#### Scenario: dotenv loads before model construction
- **WHEN** `src.agent.model` is imported
- **THEN** `OPENAI_API_KEY`, `OPENAI_BASE_URL`, and `OPENAI_MODEL` environment variables are already loaded from `.env`

#### Scenario: RAG tool initializes eagerly
- **WHEN** `src.agent.tools` is imported
- **THEN** `rag_engine_tool` is initialized (either as a tool object or `None`), matching the original `get_rag_tool()` call behavior

### Requirement: Application starts and serves requests
The application launched via `uvicorn main:app` SHALL start without error and respond to the `/api/health` endpoint with HTTP 200.

#### Scenario: Health check passes after split
- **WHEN** a GET request is sent to `/api/health`
- **THEN** the response status is 200 and the body contains `{"status": "healthy"}`

#### Scenario: Agent responds to requests after split
- **WHEN** a valid AG-UI request is sent to the agent endpoint
- **THEN** the agent processes the request without `ImportError` or `ModuleNotFoundError`
