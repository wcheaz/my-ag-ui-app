# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

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

## Specifications



## Design

## Context

The codebase contains TWO manual `.env` parsers that handle basic cases but miss edge cases.

**Parser 1: [`load_env()`](agent.py:90-106) in [`agent.py`](agent.py)**
- Searches multiple directory paths for `.env` file
- Reads file line by line
- Splits on first `=` character
- Strips quotes from values
- Only sets environment variables if they don't already exist

**Parser 2: `load_env_file()` in [`agent/src/rag/settings.py`](agent/src/rag/settings.py:8-26)**
- Searches specific directory paths for `.env` file
- Reads file line by line
- Splits on first `=` character
- Strips quotes from values
- Only sets environment variables if they don't already exist

**Current Limitations (both parsers):**
- No support for multiline values
- No support for quoted strings containing `=` characters
- No support for comments after values
- No support for variable expansion (`${VAR}`)
- No support for export statements
- Fragile parsing that can break on edge cases
- ~40 lines of custom code to maintain (20 lines per parser)

**Why This Matters:**
Environment variable parsing is a critical bootstrap operation. Failures here prevent the agent from starting. The manual parser works for simple cases but lacks robustness and maintainability compared to battle-tested libraries.

## Goals / Non-Goals

**Goals:**
- Replace manual `.env` parsing with `python-dotenv` library
- Maintain backward compatibility with existing `.env` files
- Reduce code maintenance burden
- Improve parsing robustness for edge cases
- Ensure environment variables are loaded before any other code runs

**Non-Goals:**
- Changing the `.env` file format or location
- Modifying how environment variables are used throughout the codebase
- Adding new environment variable features (validation, type conversion, etc.)
- Changing the search paths for `.env` files

## Decisions

### 1. Use `python-dotenv` Library

**Decision:** Use `python-dotenv` instead of custom parsing or alternatives.

**Rationale:**
- **Industry Standard:** `python-dotenv` is the de facto standard for Python `.env` parsing with 10M+ weekly downloads
- **Battle-Tested:** Handles all edge cases (multiline values, quoted strings, comments, variable expansion)
- **Zero Configuration:** Drop-in replacement with `load_dotenv()` call
- **Maintained:** Active development, security updates, and bug fixes
- **Lightweight:** Single dependency, no transitive dependencies

**Alternatives Considered:**
- **Keep Custom Parser:** Rejected - maintenance burden, fragile, missing features
- **`environs` Library:** Rejected - overkill, adds validation/type conversion we don't need
- **`python-decouple` Library:** Rejected - heavier dependency, more complex API
- **`configparser` Module:** Rejected - requires INI format, not `.env` compatible

### 2. Import and Call Pattern

**Decision:** Import `load_dotenv` at module level and call immediately after import in both locations.

**Rationale:**
- **Simplicity:** Single function call replaces 40+ lines of custom code (20 lines per parser)
- **Early Loading:** Ensures environment variables are available for all subsequent code
- **Explicit:** Makes environment loading visible and intentional
- **No Side Effects:** `load_dotenv()` is idempotent and safe to call multiple times
- **Consistency:** Using same library in both locations prevents path resolution issues

**Implementation:**
```python
# In agent.py
from dotenv import load_dotenv

load_dotenv()  # Load .env file, respecting existing env vars

# In agent/src/rag/settings.py
from dotenv import load_dotenv

def init_settings():
    load_dotenv()  # Load .env file, respecting existing env vars
    # Rest of init_settings() implementation...
```

### 3. Dependency Management

**Decision:** Add `python-dotenv` to [`agent/pyproject.toml`](agent/pyproject.toml) dependencies.

**Rationale:**
- **Project Standard:** Uses existing dependency management workflow
- **Version Pinning:** Can pin to specific version for reproducibility
- **Development vs Production:** Can add to dev dependencies if needed for testing
- **Documentation:** Single source of truth for all dependencies

### 4. Path Resolution

**Decision:** Let `python-dotenv` handle path resolution automatically.

**Rationale:**
- **Default Behavior:** `load_dotenv()` searches current directory and parent directories by default
- **Simpler Code:** No need to maintain custom path search logic
- **Standard Convention:** Matches expected `.env` file locations
- **Fallback:** Can pass explicit path if needed with `dotenv_path` parameter

**Current Path Search Behavior:**
The current [`load_env()`](agent.py:90-106) searches:
1. `os.path.join(os.getcwd(), ".env")`
2. `os.path.join(os.getcwd(), "..", ".env")`
3. `os.path.join(os.path.dirname(__file__), "..", ".env")`
4. `os.path.join(os.path.dirname(__file__), "..", "..", ".env")`

`python-dotenv` default search covers most of these cases. If needed, we can add explicit path:
```python
from pathlib import Path
load_dotenv(dotenv_path=Path(__file__).parent.parent / ".env")
```

## Risks / Trade-offs

### Risk 1: Breaking Existing `.env` Files

**Risk:** Some `.env` files might use syntax that `python-dotenv` doesn't support, or vice versa.

**Mitigation:**
- **Compatibility:** `python-dotenv` is highly compatible with basic `.env` syntax
- **Testing:** Test with existing `.env` files before deployment
- **Documentation:** Document any syntax requirements if discovered
- **Fallback:** Keep old code commented out temporarily for rollback

**Likelihood:** Low - `python-dotenv` supports standard `.env` syntax widely used in industry.

### Risk 2: Different Path Resolution

**Risk:** `python-dotenv` might find `.env` in different location than custom parser.

**Mitigation:**
- **Testing:** Verify `.env` loading in development environment
- **Explicit Path:** If needed, pass explicit path to `load_dotenv()`
- **Logging:** Add debug logging to confirm which `.env` file was loaded
- **Environment Check:** Verify critical environment variables are set after loading

**Likelihood:** Medium - path search logic differs, but default behavior usually works.

### Risk 3: Dependency Version Conflicts

**Risk:** `python-dotenv` might conflict with other dependencies or have security vulnerabilities.

**Mitigation:**
- **Version Pinning:** Pin to known-good version in `pyproject.toml`
- **Security Scanning:** Check for vulnerabilities before deployment
- **Testing:** Run full test suite after adding dependency
- **Monitoring:** Watch for dependency updates and security advisories

**Likelihood:** Low - `python-dotenv` is a mature, widely-used library.

### Trade-off: Additional Dependency

**Trade-off:** Adding `python-dotenv` increases dependency count and attack surface.

**Justification:**
- **Minimal Risk:** Single, well-maintained dependency with no transitive deps
- **High Value:** Replaces fragile custom code with robust, tested implementation
- **Standard Practice:** Using industry-standard libraries is better than maintaining custom implementations
- **Net Benefit:** Reduced maintenance burden and improved reliability outweighs dependency cost

## Migration Plan

### Deployment Steps

1. **Add Dependency**
   ```bash
   cd agent
   poetry add python-dotenv
   # or
   pip install python-dotenv
   ```
   Add to [`agent/pyproject.toml`](agent/pyproject.toml):
   ```toml
   [tool.poetry.dependencies]
   python-dotenv = "^1.0.0"
   ```

2. **Update [`agent.py`](agent.py)**
   - Remove `load_env()` function (lines 90-106)
   - Add import: `from dotenv import load_dotenv`
   - Replace `load_env()` call (line 109) with `load_dotenv()`

3. **Update [`agent/src/rag/settings.py`](agent/src/rag/settings.py)**
   - Remove `load_env_file()` function (lines 8-26)
   - Add import: `from dotenv import load_dotenv`
   - Replace `load_env_file()` call in `init_settings()` with `load_dotenv()`

3. **Test Locally**
   - Verify agent starts successfully
   - Confirm environment variables are loaded
   - Check that all tools work correctly
   - Test with various `.env` file formats
   - Test that both agent.py and rag/settings.py load environment correctly

4. **Commit Changes**
   - Commit dependency update
   - Commit code changes
   - Update CHANGELOG if applicable

### Rollback Strategy

**If Issues Arise:**
1. **Revert Code:** Restore original [`load_env()`](agent.py:90-106) function and call in [`agent.py`](agent.py)
2. **Revert Code:** Restore original `load_env_file()` function and call in [`agent/src/rag/settings.py`](agent/src/rag/settings.py)
3. **Remove Dependency:** Remove `python-dotenv` from [`agent/pyproject.toml`](agent/pyproject.toml)
4. **Redeploy:** Deploy previous working version
5. **Investigate:** Debug why `python-dotenv` failed before retrying

**Rollback Time:** < 5 minutes (simple git revert and redeploy)

### Validation Checklist

- [ ] Agent starts without errors
- [ ] Environment variables are loaded correctly
- [ ] All existing tests pass
- [ ] Manual testing with real `.env` file
- [ ] No performance degradation
- [ ] No security vulnerabilities in new dependency

## Open Questions

None - this is a straightforward refactoring with clear implementation path.

**Decision Point:** Should we add explicit path to `load_dotenv()` or rely on default behavior?

**Recommendation:** Start with default behavior. If `.env` file isn't found in expected location, add explicit path parameter. This follows "simplicity first" principle and avoids premature optimization.

## Current Task Context

## Current Task
- 4.4 Test edge cases (multiline values, quoted strings with =, comments)
## Completed Tasks for Git Commit
- [x] 1.1 Add python-dotenv to agent/pyproject.toml dependencies
- [x] 1.2 Install python-dotenv in development environment
- [x] 2.1 Remove custom load_env function from agent.py (lines 90-106)
- [x] 2.2 Add from dotenv import load_dotenv import to agent.py imports section
- [x] 2.3 Replace load_env call with load_dotenv call at line 109
- [x] 2.4 Remove comment about manual env loading (lines 87-88)
- [x] 2.5 Remove custom load_env_file function from agent/src/rag/settings.py (lines 8-26)
- [x] 2.6 Add from dotenv import load_dotenv import to agent/src/rag/settings.py
- [x] 2.7 Replace load_env_file call with load_dotenv call in agent/src/rag/settings.py init_settings function
- [x] 3.1 Verify agent starts without errors after changes
- [x] 3.2 Confirm environment variables are loaded correctly from .env file
- [x] 3.3 Test that all agent tools work correctly with loaded environment variables
- [x] 3.4 Test with various .env file formats (simple values, quoted values, comments)
- [x] 3.5 Run existing test suite to ensure no regressions
- [x] 4.1 Verify no performance degradation in agent startup time
- [x] 4.2 Check for security vulnerabilities in python-dotenv dependency
- [x] 4.3 Confirm backward compatibility with existing .env files
