## Why

The agent currently relies on voluntary compliance to call `read_code_generation_file` before generating codes. Under conversational pressure, the LLM may skip reading the rules file, leading to inaccurate procurement codes that don't match the current CODE_GENERATION.md specifications. This enforcement is critical for accuracy since rules may change and need to be re-injected into the active context window on every request.

## What Changes

- Add `rules_loaded_this_turn` flag to `ProcurementState` that resets per request
- Modify `read_code_generation_file` tool to set the flag when successfully executed
- Add validation in `save_procurement_code` tool to check the flag and reject saves if rules weren't loaded
- Change `read_code_generation_file` to raise exceptions on failure instead of returning error strings
- Update system prompt to reflect the new enforced workflow

## Capabilities

### New Capabilities
(None - this change modifies existing behavior)

### Modified Capabilities

- `procurement-agent`: Add requirement to enforce that `read_code_generation_file` MUST be called before `save_procurement_code`. The agent cannot skip reading rules or save codes without loading them first.

## Impact

- **Code**: `agent/src/agent.py` - modifications to `ProcurementState`, `read_code_generation_file`, and `save_procurement_code` functions
- **State**: New per-request state tracking for rules loading
- **Error Handling**: Improved error visibility through exceptions instead of silent error strings
- **Backward Compatibility**: **BREAKING** - agents that previously skipped file-read will now be blocked from saving codes
