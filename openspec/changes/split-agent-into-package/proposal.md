## Why

`agent/src/agent.py` is 3254 lines and growing. It contains data models, business logic, agent tools, system prompt, model initialization, disambiguation metrics, and component matching — all in one flat file. This makes navigation slow, diffs noisy, and targeted testing impossible. Splitting it into a Python package preserves all existing behavior while making each concern independently maintainable and testable.

## What Changes

- Convert `agent/src/agent.py` (single module) into `agent/src/agent/` (Python package directory) with focused submodules
- `__init__.py` re-exports `ProcurementState`, `StateDeps`, and `agent` so `from src.agent import ProcurementState, StateDeps, agent` continues to work identically
- Move each logical group (models, tools, matching logic, metrics, system prompt, model wrapper) into its own module within the package
- Delete the original `agent.py` file — Python resolves `src.agent` to the package's `__init__.py`

## Non-goals

- No behavioral changes to any agent tool, prompt, or workflow
- No new public API surface — only internal reorganization
- No changes to `main.py`, Dockerfile, or deployment configuration
- No renaming of symbols or refactoring of function signatures
- No addition of new tests beyond verifying the import contract

## Capabilities

### New Capabilities

- `agent-package-structure`: Defines the module layout, import contract (`from src.agent import ProcurementState, StateDeps, agent`), and the rule that all symbols previously importable from `src.agent` remain importable after the split.

### Modified Capabilities

_(None — no spec-level behavior changes.)_

## Impact

- **`agent/src/agent.py`**: Deleted and replaced by `agent/src/agent/` package directory
- **`agent/src/main.py`**: No changes needed — import path `from src.agent import ...` is preserved by `__init__.py` re-exports
- **Internal imports**: Submodules within the new package import from each other (e.g., `tools.py` imports `ProcurementState` from `models.py`)
- **Tests**: Any test importing from `src.agent` continues to work; a smoke test verifies the import contract
- **Docker / deployment**: No impact — the Dockerfile copies `agent/src/` recursively, which covers both file and directory forms
