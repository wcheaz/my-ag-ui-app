# Replace Proverbs with Procurement Codes

## Effect
Replaces the demonstrative "Proverbs" feature with a functional "Procurement Codes" list, allowing the agent to generate and store procurement codes based on user input.

## Motivation
The current "Proverbs" feature is a placeholder. The user wants to use the agent for generating procurement codes. Storing these codes alongside their source descriptions provides a useful history and context for the user.

## Implementation Strategy
1. Modify `AgentState` (frontend) and `ProcurementState` (backend) to store a list of procurement codes instead of proverbs.
2. Refactor `src/components/proverbs.tsx` into `src/components/procurement-codes.tsx` to display the new data structure.
3. Update `src/app/page.tsx` to integrate the new component and initial state.
