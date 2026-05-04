## Why

The codebase contains TWO manual `.env` parsers that handle basic cases but miss edge cases like multiline values, quoted strings with embedded `=`, and other complex environment variable formats. This creates maintenance burden and potential for parsing errors. Using the industry-standard `python-dotenv` library provides robust, well-tested parsing that handles all edge cases and respects existing environment variables.

**Two Manual Parsers Found:**
1. [`load_env()`](agent.py:90-106) function in [`agent.py`](agent.py) - searches multiple paths for `.env` file
2. `load_env_file()` function in [`agent/src/rag/settings.py`](agent/src/rag/settings.py) - tries to find `.env` in specific directories

## What Changes

- Remove the custom [`load_env()`](agent.py:90-106) function (~20 lines) from [`agent.py`](agent.py)
- Remove the custom `load_env_file()` function (~20 lines) from [`agent/src/rag/settings.py`](agent/src/rag/settings.py)
- Add `python-dotenv` as a dependency in [`agent/pyproject.toml`](agent/pyproject.toml)
- Replace manual environment loading with `from dotenv import load_dotenv; load_dotenv()` in both locations
- Update imports in [`agent.py`](agent.py) and [`agent/src/rag/settings.py`](agent/src/rag/settings.py) to use the new library

## Capabilities

### New Capabilities
(None - this is a code cleanup/dependency change)

### Modified Capabilities
(None - this change only affects implementation, not spec-level behavior)

## Impact

- **Code**: [`agent.py`](agent.py) - remove `load_env()` function, add `load_dotenv()` import and call
- **Code**: [`agent/src/rag/settings.py`](agent/src/rag/settings.py) - remove `load_env_file()` function, add `load_dotenv()` import and call
- **Dependencies**: [`agent/pyproject.toml`](agent/pyproject.toml) - add `python-dotenv` package
- **Behavior**: No functional changes - environment variables will be loaded identically, but with more robust parsing
- **Testing**: Existing tests should pass without modification since the behavior remains the same
