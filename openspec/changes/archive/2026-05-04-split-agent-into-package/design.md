## Context

`agent/src/agent.py` is a single 3254-line Python module containing the entire procurement agent: Pydantic data models (`ProcurementCode`, `AmbiguityInfo`, `ProcurementState`), four agent tools (`read_code_generation_file`, `clarify_components`, `save_procurement_code`, `reset_conversation`), component matching/extraction logic, disambiguation metrics tracking, the system prompt string, a `LoggingOpenAIModel` wrapper, and the final `Agent` instantiation. Only one external consumer exists — `agent/src/main.py` imports `ProcurementState`, `StateDeps`, and `agent`.

The change is purely structural: convert the flat module into a package so that each concern lives in its own file, while keeping the public import API identical.

## Goals / Non-Goals

**Goals:**

- Split `agent.py` into a `agent/src/agent/` package with focused submodules
- Preserve the exact public import contract: `from src.agent import ProcurementState, StateDeps, agent`
- Preserve all runtime behavior — no changes to tool signatures, prompts, or logic
- Make each submodule independently importable for future targeted testing

**Non-Goals:**

- No behavioral changes to any tool, prompt, or workflow
- No refactoring of function signatures or class methods
- No changes to `main.py`, Dockerfile, or deployment configuration
- No renaming of public or private symbols

## Decisions

### D1: Package layout — six submodules

The file splits naturally into six submodules plus an `__init__.py`:

| Submodule | Contents | Approx lines |
|---|---|---|
| `models.py` | `ProcurementCode`, `AmbiguityInfo`, `ProcurementState` (and all its methods) | ~390 |
| `matching.py` | `parse_code_generation_rules`, `find_component_matches`, `_get_filter_reason`, `extract_components_from_description`, `get_component_extraction_results`, `validate_options_similarity_threshold`, `detect_explicit_guess_permission`, `calculate_semantic_similarity` | ~870 |
| `tools.py` | `read_code_generation_file`, `clarify_components`, `save_procurement_code`, `reset_conversation`, `get_rag_tool`, `query_rag_system`, `get_citation_sources`, `detect_component_ambiguity`, `format_guess_notification` | ~1150 |
| `metrics.py` | `DisambiguationMetrics`, `get_disambiguation_metrics`, `log_disambiguation_metrics_summary` | ~230 |
| `prompt.py` | `STATIC_SYSTEM_PROMPT` string literal | ~60 |
| `model.py` | `LoggingOpenAIModel` class, env-var loading, `model` and `agent` instantiation | ~125 |
| `__init__.py` | Re-exports: `ProcurementState`, `StateDeps`, `agent` | ~10 |

**Rationale**: This grouping follows the existing logical boundaries in the file. Each group has minimal cross-dependencies — `tools.py` depends on `models.py` and `matching.py`, but `matching.py` and `metrics.py` are largely self-contained. The coarsest grouping that still keeps each file under ~1200 lines.

**Alternative considered**: A finer split (e.g., one file per tool function) would create too many tiny files with high cross-import coupling, increasing import complexity without proportional readability gain.

### D2: Import contract via `__init__.py` re-exports

`__init__.py` will contain:

```python
from src.agent.models import ProcurementState
from pydantic_ai.ag_ui import StateDeps
from src.agent.model import agent

__all__ = ["ProcurementState", "StateDeps", "agent"]
```

**Rationale**: This makes `from src.agent import ProcurementState, StateDeps, agent` resolve identically. Python resolves `src.agent` to the package's `__init__.py` when `src/agent/` is a directory, so no changes are needed in `main.py` or any test file.

### D3: Internal cross-module imports

- `tools.py` imports from `models.py` (for `ProcurementState`), `matching.py` (for component matching functions), `metrics.py` (for metrics tracking), and `prompt.py` (no dependency, but tools don't need the prompt).
- `matching.py` imports from `models.py` (for `AmbiguityInfo`).
- `model.py` imports from `models.py` (for `ProcurementState`), `tools.py` (for tool functions), and `prompt.py` (for `STATIC_SYSTEM_PROMPT`).
- `metrics.py` and `prompt.py` have no intra-package imports.

**Rationale**: This creates a clean DAG with no circular imports. `model.py` is the leaf that wires everything together into the `Agent` instance, matching the current bottom-of-file instantiation pattern.

### D4: Logging setup stays in `metrics.py`

The `disambiguation_logger` setup (file handler, formatter) at lines 91–112 currently lives at module level. It will move to `metrics.py` since it is only used by `DisambiguationMetrics`.

### D5: RAG module-level initialization moves to `tools.py`

The `rag_engine_tool = get_rag_tool()` module-level call (line 1026) moves to `tools.py`, keeping its eager-initialization behavior.

### D6: `dotenv` loading stays in `model.py`

`load_dotenv()` at line 88 is called for `OPENAI_API_KEY`, `OPENAI_BASE_URL`, and `OPENAI_MODEL`. It moves to `model.py` alongside the model instantiation that consumes those env vars.

## Risks / Trade-offs

- **Circular import risk** → Mitigated by the DAG structure in D3. `tools.py` imports from `models.py` and `matching.py`; `model.py` imports from `tools.py` and `models.py`. No module imports from `model.py`. Verified: no circular path exists.
- **Module-level side effects** → `get_rag_tool()` and `load_dotenv()` run at import time today. They continue to run at import time in their new submodules, preserving behavior. Order matters: `dotenv` loads in `model.py` before `OpenAIModel` is constructed.
- **`__pycache__` staleness** → After deleting `agent.py` and creating `agent/`, old `.pyc` files could cause confusion. Mitigation: delete `agent/src/__pycache__/` as part of the migration.
- **Test discovery** → Any test file doing `from src.agent import X` works unchanged. Tests importing private helpers by file path (unlikely) would need updating.

## Migration Plan

1. Create the `agent/src/agent/` package directory
2. Write each submodule by extracting the relevant code from `agent.py`
3. Write `__init__.py` with re-exports
4. Delete `agent/src/agent.py`
5. Clean `agent/src/__pycache__/`
6. Verify `from src.agent import ProcurementState, StateDeps, agent` succeeds
7. Run existing tests (if any) and lint/typecheck

**Rollback**: Revert the commit — `git revert` restores the single-file `agent.py`.

## Open Questions

None — all design decisions are resolved above. No unresolved policy choices for the implementing agent.
