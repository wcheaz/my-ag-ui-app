## Why

`agent/src/agent.py` is a 3,254-line single file containing the entire procurement agent: data models, agent tools, component matching logic, disambiguation metrics, system prompt, and agent instantiation. This makes navigation, code review, and targeted testing difficult. The file has grown organically through iterative feature additions (disambiguation workflow, RAG integration, guess-permission handling) that each added hundreds of lines to an already large module.

Splitting into a package lets each concern live in its own file, improving readability without changing any runtime behavior.

## What Changes

- Convert `agent/src/agent.py` (single 3,254-line module) into `agent/src/agent/` (a package directory) with six focused submodules: `models.py`, `matching.py`, `tools.py`, `metrics.py`, `prompt.py`, `model.py`
- Add `agent/src/agent/__init__.py` that re-exports the three public symbols (`ProcurementState`, `StateDeps`, `agent`) so that `from src.agent import ...` works unchanged
- Delete `agent/src/agent.py` and clean `agent/src/__pycache__/`

## Capabilities

### New Capabilities

- `agent-package-structure`: A structural capability defining the package layout, submodule contents, import contract, and no-circular-import requirement for the `agent/src/agent/` package

### Modified Capabilities

_(none — no behavioral changes to any existing capability)_

## Impact

- **Agent source**: `agent/src/agent.py` deleted; six new files created under `agent/src/agent/`
- **Public import API**: Unchanged — `from src.agent import ProcurementState, StateDeps, agent` resolves identically via `__init__.py` re-exports
- **Tests**: Existing test files import from `agent` module; all continue working unchanged
- **Deployment**: No changes to `main.py`, Dockerfile, or configuration

## Scope

- **In scope**: Structural split of `agent/src/agent.py` into `agent/src/agent/` package; `__init__.py` re-exports; `__pycache__` cleanup
- **Out of scope (non-goals)**:
  - No behavioral changes to tools, prompts, or workflow logic
  - No refactoring of function signatures or class methods
  - No changes to `main.py`, `Dockerfile`, or deployment configuration
  - No renaming of public or private symbols
  - No changes to the `rag/` subpackage
  - No new tests beyond a structural import verification test

## First-Rollout Boundaries

This change has a single rollout with no phases:

1. Create the package directory and all six submodules
2. Write `__init__.py` with re-exports
3. Delete `agent/src/agent.py`
4. Clean `agent/src/__pycache__/`
5. Verify: `from src.agent import ProcurementState, StateDeps, agent` succeeds
6. Verify: `uvicorn main:app` starts and `/api/health` returns 200

**Rollback**: `git revert` restores the single-file `agent.py`.
