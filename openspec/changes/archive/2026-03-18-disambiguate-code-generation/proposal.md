## Why

Users currently discover incorrect procurement codes only after they've been generated and saved, creating a poor user experience. The agent often attempts to infer or guess ambiguous inputs instead of asking for clarification, leading to inaccurate codes that require regeneration and correction.

## What Changes

- Implement a confirm-before-generate pattern for ambiguous code generation inputs
- Add a disambiguation workflow that identifies when multiple component matches exist
- Require explicit user confirmation before generating codes when any component is ambiguous
- Only allow the agent to make guesses when the user explicitly states they don't know
- Implement iterative clarification - if the user's answer remains ambiguous, ask again for more specific information
- Update the agent's workflow to parse user descriptions, identify component matches, and surface options before calling save_procurement_code

## Capabilities

### New Capabilities
- `code-disambiguation`: A capability that provides structured disambiguation for code generation components, including parsing user descriptions, identifying multiple plausible matches for each component, and presenting options to users for confirmation before generation

### Modified Capabilities
- `procurement-agent`: Modify the agent's workflow to enforce the confirm-before-generate pattern, requiring all components to be unambiguous before proceeding with code generation

## Impact

- **Agent Behavior**: The agent will no longer silently guess or infer ambiguous inputs; it must explicitly ask for clarification
- **User Experience**: Users will see clarification prompts with options before any code is generated, reducing the need for corrections
- **Tool Flow**: The agent workflow will include a new disambiguation step between parsing the user's description and calling save_procurement_code
- **Code Generation Logic**: May need a new disambiguation tool or enhanced prompt patterns to support the confirm-before-generate workflow
- **Testing**: Will require new test cases covering ambiguous inputs and the clarification flow