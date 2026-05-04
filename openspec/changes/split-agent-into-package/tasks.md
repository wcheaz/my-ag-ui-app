# File Placement Rules (CRITICAL)

When creating test files or documentation files, follow these rules:

## Test Files
- **Placement**: All test files MUST be placed in the `test/` directory at project root
- **Forbidden locations**: DO NOT create test files in the change directory, agent/ directory, or project root
- **File patterns**: test*.py, debug*.py, check*.py, measure*.py, performance*.py, verify*.py, validate*.py
- **Naming conventions**: Use appropriate prefixes (test_, debug_, check_, measure_, performance_, verify_, validate_)
- **Example**: Task "Write unit tests for component extraction" → Create: test/test_component_extraction.py

## Documentation Files
- **Placement**: All .md documentation files MUST be placed in the `ralph-docs/` directory at project root
- **Forbidden locations**: DO NOT create .md documentation files in the project root (except core files: README.md, CHANGELOG.md, SETUP.md, TESTING.md, DEPENDENCIES.md, deploy_log.md)
- **Examples**: Task "Create deployment summary" → Create: ralph-docs/DEPLOYMENT_SUMMARY.md

---

## 1. Pre-flight

- [x] **Pre-flight: record import baseline and test suite status**
  - Scope: no code edits; reads only
  - Change: Capture current state of the public import contract and test suite so later tasks can diff against a known-good baseline.
  - Done when:
    - `.ralph/baselines/split-package-import.txt` exists containing the output of `python -c "from src.agent import ProcurementState, StateDeps, agent; print(type(ProcurementState), type(agent))"` run from `agent/` directory
    - `.ralph/baselines/split-package-files.txt` exists containing the output of `ls -la agent/src/agent.py` confirming the single file exists
    - `.ralph/baselines/split-package-readme.md` exists listing: (a) import test passes, (b) `agent.py` exists, (c) count of test files in `test/` directory
  - Stop and hand off if: the import command fails or raises an error (indicates environment is already broken).

## 2. Shared Contracts — Data Models and Prompt

- [ ] **Extract `models.py`, `prompt.py`, and `metrics.py` into the new package**
  - Scope: `agent/src/agent/models.py` (new), `agent/src/agent/prompt.py` (new), `agent/src/agent/metrics.py` (new), `agent/src/agent/__init__.py` (new)
  - Change: The four leaf submodules with no intra-package imports are created inside `agent/src/agent/`. The `__init__.py` re-exports `ProcurementState` and `StateDeps` so downstream imports resolve immediately.
  - Done when:
    - `agent/src/agent/__init__.py` exists and contains `from src.agent.models import ProcurementState` and `from pydantic_ai.ag_ui import StateDeps`
    - `agent/src/agent/models.py` contains `ProcurementCode`, `AmbiguityInfo`, `ProcurementState` with all methods
    - `agent/src/agent/prompt.py` contains `STATIC_SYSTEM_PROMPT` string literal
    - `agent/src/agent/metrics.py` contains `DisambiguationMetrics`, `get_disambiguation_metrics`, `log_disambiguation_metrics_summary`, and the `disambiguation_logger` setup
    - `python -c "from src.agent.models import ProcurementState, ProcurementCode, AmbiguityInfo"` succeeds from `agent/` directory
    - `python -c "from src.agent.prompt import STATIC_SYSTEM_PROMPT"` succeeds from `agent/` directory
    - `python -c "from src.agent.metrics import DisambiguationMetrics"` succeeds from `agent/` directory
  - Stop and hand off if: `ProcurementState` has a dependency not listed in design.md D3 (would create an unexpected import cycle).

## 3. Matching Engine

- [ ] **Extract `matching.py` into the new package**
  - Scope: `agent/src/agent/matching.py` (new)
  - Change: The component matching/extraction logic is in its own file, importing from `models.py` only.
  - Done when:
    - `agent/src/agent/matching.py` contains: `parse_code_generation_rules`, `find_component_matches`, `_get_filter_reason`, `extract_components_from_description`, `get_component_extraction_results`, `validate_options_similarity_threshold`, `detect_explicit_guess_permission`, `calculate_semantic_similarity`
    - `python -c "from src.agent.matching import find_component_matches, extract_components_from_description"` succeeds from `agent/` directory
    - `python -c "import ast; ast.parse(open('agent/src/agent/matching.py').read()); print('syntax ok')"` succeeds
  - Stop and hand off if: `matching.py` requires imports from `tools.py` (would create a circular dependency requiring design.md revision).

## 4. Agent Tools

- [ ] **Extract `tools.py` into the new package**
  - Scope: `agent/src/agent/tools.py` (new)
  - Change: All agent tool functions are in their own file, importing from `models.py`, `matching.py`, and `metrics.py`.
  - Done when:
    - `agent/src/agent/tools.py` contains: `read_code_generation_file`, `clarify_components`, `save_procurement_code`, `reset_conversation`, `get_rag_tool`, `query_rag_system`, `get_citation_sources`, `detect_component_ambiguity`, `format_guess_notification`
    - `python -c "import ast; ast.parse(open('agent/src/agent/tools.py').read()); print('syntax ok')"` succeeds
    - `python -c "from src.agent.models import ProcurementState; from src.agent.matching import find_component_matches; from src.agent.tools import detect_component_ambiguity"` succeeds from `agent/` directory
    - RAG tool module-level initialization (`rag_engine_tool = get_rag_tool()`) is present in `tools.py`
  - Stop and hand off if: a tool function requires importing from `model.py` (would create a circular dependency).

## 5. Agent Instantiation Wire-Up

- [ ] **Extract `model.py` and finalize `__init__.py` re-exports**
  - Scope: `agent/src/agent/model.py` (new), `agent/src/agent/__init__.py` (update)
  - Change: The `LoggingOpenAIModel`, `model` instance, and `agent` instance are wired in `model.py`. The `__init__.py` re-exports `agent` so `from src.agent import agent` resolves.
  - Done when:
    - `agent/src/agent/model.py` contains `LoggingOpenAIModel` class, `load_dotenv()` call, env-var loading, `model` instance, `agent` instance
    - `agent/src/agent/__init__.py` contains `from src.agent.model import agent` and `__all__ = ["ProcurementState", "StateDeps", "agent"]`
    - `python -c "from src.agent import ProcurementState, StateDeps, agent; print(type(agent))"` succeeds from `agent/` directory and prints `<class 'pydantic_ai.agent.Agent'>`
  - Stop and hand off if: `model.py` fails to import `tools.py` functions (missing symbol from step 4).

## 6. Delete Old File and Clean Cache

- [ ] **Delete `agent/src/agent.py` and clean `__pycache__`**
  - Scope: `agent/src/agent.py` (delete), `agent/src/__pycache__/` (delete contents)
  - Change: The old monolithic file is gone; only the package directory `agent/src/agent/` exists. Stale bytecode is removed.
  - Done when:
    - `test -f agent/src/agent.py` returns non-zero (file does not exist)
    - `test -d agent/src/agent` returns zero (package directory exists)
    - `agent/src/__pycache__/` contains no files matching `agent.*.pyc`
    - `python -c "from src.agent import ProcurementState, StateDeps, agent; print('OK')"` succeeds from `agent/` directory
  - Stop and hand off if: import fails after deletion (indicates incomplete migration — restore `agent.py` from git and review missing symbols).

## 7. Final Integrated Quality Gate

- [ ] **Verify application starts and health check passes**
  - Scope: no code edits; runtime verification only
  - Change: Confirm the application starts and serves requests with the new package structure.
  - Done when:
    - `python -c "from src.agent.models import ProcurementState; from src.agent.matching import find_component_matches; from src.agent.tools import clarify_components; from src.agent.metrics import DisambiguationMetrics; from src.agent.prompt import STATIC_SYSTEM_PROMPT; from src.agent.model import agent; print('all submodules import OK')"` succeeds from `agent/` directory with no `ImportError` or circular-import `RuntimeWarning`
    - `python -c "from src.agent import ProcurementState, StateDeps, agent; app = agent.to_ag_ui(deps=StateDeps(state=ProcurementState())); print('app created:', type(app))"` succeeds from `agent/` directory
    - `python -c "import importlib; specs = ['src.agent.models', 'src.agent.matching', 'src.agent.tools', 'src.agent.metrics', 'src.agent.prompt', 'src.agent.model']; [importlib.import_module(s) for s in specs]; print('all 6 submodules imported')"` succeeds with no warnings
    - Diff `.ralph/baselines/split-package-readme.md` baseline matches: import contract still resolves same types
  - Stop and hand off if: any `ImportError` or `RuntimeWarning` for circular imports is raised (do not proceed — review the import DAG against design.md D3).
