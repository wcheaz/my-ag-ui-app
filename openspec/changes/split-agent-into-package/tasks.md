## 1. Create package directory and dependency-free submodules

- [ ] 1.1 Create `agent/src/agent/` package directory. Create `models.py` containing `ProcurementCode`, `AmbiguityInfo`, `ProcurementState` (with all methods), and the necessary imports (`pydantic`, `typing`, etc.). Include all field definitions, `update_component_ambiguity`, `validate_state_transition`, `validate_all_component_states`, `validate_all_components_unambiguous`, `get_ambiguous_components`, `get_unambiguous_components`.
  - Done when: `from src.agent.models import ProcurementState, ProcurementCode, AmbiguityInfo` succeeds.
- [ ] 1.2 Create `prompt.py` containing only the `STATIC_SYSTEM_PROMPT` string and the commented-out old prompt block (lines 2975–3120). No intra-package imports needed.
  - Done when: `from src.agent.prompt import STATIC_SYSTEM_PROMPT` returns the same string as the original.
- [ ] 1.3 Create `metrics.py` containing the `disambiguation_logger` setup (lines 91–112), `DisambiguationMetrics` class, `get_disambiguation_metrics()`, and `log_disambiguation_metrics_summary()`. No intra-package imports needed.
  - Done when: `from src.agent.metrics import DisambiguationMetrics, get_disambiguation_metrics, log_disambiguation_metrics_summary` succeeds.

## 2. Create matching submodule

- [ ] 2.1 Create `matching.py` containing `calculate_semantic_similarity`, `detect_explicit_guess_permission`, `parse_code_generation_rules`, `find_component_matches`, `_get_filter_reason`, `extract_components_from_description`, `get_component_extraction_results`, `validate_options_similarity_threshold`. Import `AmbiguityInfo` from `src.agent.models`. Preserve all external imports (`re`, `json`, `numpy`, etc.).
  - Done when: `from src.agent.matching import parse_code_generation_rules, find_component_matches, extract_components_from_description` succeeds without circular-import warnings.

## 3. Create tools submodule

- [ ] 3.1 Create `tools.py` containing `read_code_generation_file`, `get_rag_tool`, `query_rag_system`, `get_citation_sources`, `clarify_components`, `detect_component_ambiguity`, `format_guess_notification`, `reset_conversation`, `save_procurement_code`, and the `rag_engine_tool = get_rag_tool()` module-level call. Import `ProcurementState` from `src.agent.models`, matching functions from `src.agent.matching`, and metrics from `src.agent.metrics`. Preserve all external imports (`RunContext`, `StateDeps`, etc.).
  - Done when: `from src.agent.tools import clarify_components, save_procurement_code, reset_conversation, read_code_generation_file` succeeds without error.

## 4. Create model submodule and wire the agent

- [ ] 4.1 Create `model.py` containing the `load_dotenv()` call, `LoggingOpenAIModel` class, env-var loading (`OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL`), the `model` instance, and the `agent` instantiation. Import `ProcurementState` from `src.agent.models`, tool functions from `src.agent.tools`, and `STATIC_SYSTEM_PROMPT` from `src.agent.prompt`. Do NOT import from any other intra-package submodule.
  - Done when: `from src.agent.model import agent` returns a `pydantic_ai.Agent` instance with the correct tools and system prompt.

## 5. Create __init__.py, remove old file, and verify

- [ ] 5.1 Create `agent/src/agent/__init__.py` that re-exports the public contract: `from src.agent.models import ProcurementState`, `from pydantic_ai.ag_ui import StateDeps`, `from src.agent.model import agent`, with `__all__ = ["ProcurementState", "StateDeps", "agent"]`.
  - Done when: `from src.agent import ProcurementState, StateDeps, agent` succeeds in a fresh Python session.
- [ ] 5.2 Delete `agent/src/agent.py` and clean `agent/src/__pycache__/` to remove stale `.pyc` files.
  - Done when: `ls agent/src/agent.py` shows file not found and `ls agent/src/agent/__init__.py` shows the new file.

## 6. Verification

- [ ] 6.1 Run `python -c "from src.agent import ProcurementState, StateDeps, agent; print('OK')"` from the `agent/` directory. Verify no `ImportError`, no circular-import warnings.
  - Done when: command prints `OK` and exits 0.
- [ ] 6.2 Run any existing test suite and lint/typecheck commands. Fix any import-path failures.
  - Done when: all tests pass and lint/typecheck exits 0.
- [ ] 6.3 Start the application with `uvicorn main:app --host 0.0.0.0 --port 3000` and send a GET request to `/api/health`. Verify HTTP 200 response with `{"status": "healthy"}`.
  - Done when: health check returns 200. Stop and hand off if the server fails to start.
