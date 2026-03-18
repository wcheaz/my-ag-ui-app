## Why

The current [`load_env()`](agent.py:16-34) function in [`agent.py`](agent.py) manually parses `.env` files, which handles basic cases but misses edge cases like multiline values, quoted strings with embedded `=`, and other complex environment variable formats. This creates maintenance burden and potential for parsing errors. Using the industry-standard `python-dotenv` library provides robust, well-tested parsing that handles all edge cases and respects existing environment variables.

## What Changes

- Remove the custom [`load_env()`](agent.py:16-34) function (~20 lines) from [`agent.py`](agent.py)
- Add `python-dotenv` as a dependency in [`agent/pyproject.toml`](agent/pyproject.toml)
- Replace manual environment loading with `from dotenv import load_dotenv; load_dotenv()`
- Update imports in [`agent.py`](agent.py) to use the new library

## Capabilities

### New Capabilities
(None - this is a code cleanup/dependency change)

### Modified Capabilities
(None - this change only affects implementation, not spec-level behavior)

## Impact

- **Code**: [`agent.py`](agent.py) - remove `load_env()` function, add `load_dotenv()` import and call
- **Dependencies**: [`agent/pyproject.toml`](agent/pyproject.toml) - add `python-dotenv` package
- **Behavior**: No functional changes - environment variables will be loaded identically, but with more robust parsing
- **Testing**: Existing tests should pass without modification since the behavior remains the same
