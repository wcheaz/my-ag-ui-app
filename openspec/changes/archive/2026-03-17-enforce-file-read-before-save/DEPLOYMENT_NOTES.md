# Deployment Notes: Enforce File Read Before Save

## Breaking Change Alert

This deployment introduces a **BREAKING CHANGE** for agents that skip the file-read step before saving procurement codes. Previously compliant agents will continue to work without changes.

## What Changed

The procurement agent now **enforces** the requirement to call `read_code_generation_file` before calling `save_procurement_code`. This is no longer a voluntary workflow step but a mandatory, programmatic requirement.

### Technical Changes

1. **New State Tracking**: Added `rules_loaded_this_turn` flag to `ProcurementState`
2. **File Read Enforcement**: `read_code_generation_file` now sets the flag on successful execution
3. **Save Validation**: `save_procurement_code` now blocks saves when rules haven't been loaded
4. **Error Handling**: Improved from silent error strings to visible exceptions

## Why This Change Was Necessary

Previously, the agent relied on voluntary compliance to read the `CODE_GENERATION.md` file before generating codes. Under conversational pressure or in long conversations, the LLM would sometimes skip reading the rules file, leading to:

- Inaccurate procurement codes that don't match current specifications
- Stale rules being used when `CODE_GENERATION.md` has been updated
- Inconsistent behavior across different agent interactions

This enforcement ensures accuracy and reliability by guaranteeing that the most current rules are always used for code generation.

## Impact on Existing Agents

### Affected Agents
- Agents that sometimes skip `read_code_generation_file` and proceed directly to code generation and saving
- Agents that rely on cached rules from previous requests

**Result**: These agents will now be blocked from saving codes with the error:
```
ERROR: You must call read_code_generation_file before saving a code.
```

### Unaffected Agents
- Agents that already follow the correct workflow: `read_file → generate_code → save_code`
- Agents that call `read_code_generation_file` on every request before saving

**Result**: These agents will continue to work exactly as before.

## Migration Guide

### If Your Agent is Affected

1. **Ensure File Read on Every Request**: Modify your agent to always call `read_code_generation_file` at the beginning of each code generation session, before any code generation or saving.

2. **Handle New Exceptions**: The `read_code_generation_file` tool now raises exceptions instead of returning error strings:
   - `FileNotFoundError` when `CODE_GENERATION.md` is not found
   - `Exception` when file read encounters other errors

3. **Update Error Handling**: Update your agent's error handling to catch these exceptions appropriately.

### Example Migration

**Before (will now fail):**
```
# Agent skips file read
code = generate_procurement_code(request)
save_procurement_code(code)  # ERROR: Must call read_code_generation_file first
```

**After (correct workflow):**
```
# Agent reads rules first
rules = read_code_generation_file()  # May raise FileNotFoundError
code = generate_procurement_code(rules)
save_procurement_code(code)  # Success!
```

## Testing Your Agent

After deploying this change, test your agent with these scenarios:

1. **Complete Workflow**: `read_file → generate_code → save_code` (should succeed)
2. **Skipped File Read**: `generate_code → save_code` (should fail with clear error)
3. **File Not Found**: Attempt to read non-existent `CODE_GENERATION.md` (should raise FileNotFoundError)
4. **Multi-Request**: Verify rules are re-read on each new request

## Deployment Checklist

- [ ] Update agent documentation to reflect the enforced workflow
- [ ] Test existing agents for compatibility
- [ ] Update agent error handling for new exception types
- [ ] Monitor deployment for any unexpected errors
- [ ] Provide support for affected agent developers

## Support

If your agent is affected by this change and you need assistance with migration:

1. Check the error messages for clear guidance
2. Review the updated system prompt for workflow instructions
3. Contact the development team with specific error scenarios

## Future Considerations

This enforcement is the first step in ensuring procurement code accuracy. Future improvements may include:

- Additional validation of generated codes
- Enhanced error handling and recovery
- Performance optimizations for frequent file reads

---