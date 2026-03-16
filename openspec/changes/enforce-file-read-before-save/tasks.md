## 1. Setup and Bug Fixes

- [x] 1.1 Move `import datetime` statement to the top of `agent/src/agent.py` (currently at line 272, needs to be before line 61 where it's used)
- [x] 1.2 Verify all imports are in the correct order at the top of the file
- [x] 1.3 Test that the datetime import fix resolves the NameError in `read_code_generation_file`

## 2. State Modifications

- [x] 2.1 Add `rules_loaded_this_turn: bool = False` field to the `ProcurementState` class definition
- [x] 2.2 Verify the new field is properly initialized and defaults to False
- [x] 2.3 Test that the flag resets correctly when new state instances are created

## 3. Tool Modifications - read_code_generation_file

- [x] 3.1 Add `ctx.deps.state.rules_loaded_this_turn = True` immediately after successfully reading the file content (after line 88)
- [x] 3.2 Replace the error string return at line 85 with `raise FileNotFoundError("CODE_GENERATION.md not found. Cannot generate codes without rules.")`
- [x] 3.3 Replace the error string return at line 91 with `raise Exception(f"Error reading CODE_GENERATION.md file: {str(e)}")`
- [x] 3.4 Test that the flag is set correctly on successful file read
- [ ] 3.5 Test that exceptions are raised correctly when file is not found
- [ ] 3.6 Test that exceptions are raised correctly when file read fails

## 4. Tool Modifications - save_procurement_code

- [ ] 4.1 Add validation check at the start of `save_procurement_code` function: `if not ctx.deps.state.rules_loaded_this_turn: return "ERROR: You must call read_code_generation_file before saving a code."`
- [ ] 4.2 Test that save is blocked when flag is False
- [ ] 4.3 Test that save succeeds when flag is True
- [ ] 4.4 Verify error message is clear and actionable for the agent

## 5. System Prompt Updates

- [ ] 5.1 Update the `STATIC_SYSTEM_PROMPT` to indicate that the workflow is now enforced programmatically
- [ ] 5.2 Update the "MANDATORY VERIFICATION" section to mention enforcement
- [ ] 5.3 Test that the agent understands the new enforced workflow from the prompt

## 6. Integration Testing

- [ ] 6.1 Test complete workflow: read file → generate code → save code (should succeed)
- [ ] 6.2 Test broken workflow: generate code → save code without reading (should fail with clear error)
- [ ] 6.3 Test multi-request scenario: read and save in first request, verify flag resets for second request
- [ ] 6.4 Test file not found scenario: agent attempts to read non-existent file (should raise exception)
- [ ] 6.5 Test read error scenario: agent encounters read error (should raise exception with details)
- [ ] 6.6 Verify that agents that already follow the workflow correctly continue to work without issues

## 7. Documentation and Cleanup

- [ ] 7.1 Update any relevant documentation to reflect the enforced workflow
- [ ] 7.2 Add comments to the code explaining the enforcement mechanism
- [ ] 7.3 Verify no debug code or .bak files are left in production (per suggestion #4 from SUGGESTIONS.md)
- [ ] 7.4 Create deployment notes explaining the breaking change for agents that skip file-read
