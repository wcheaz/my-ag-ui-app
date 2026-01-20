# Procurement Code Management

## ADDED Requirements
### Requirement: Procurement Codes UI
The application SHALL provide a user interface to display generated procurement codes to the user.

#### Scenario: Displaying Procurement Codes
- **Requirement:** The UI shall display a list of generated procurement codes in a specialized card component.
- **Requirement:** Each list item shall show the `code` and the `description` that generated it.
- **Requirement:** The UI shall allow the user to remove individual code items from the list.
- **Requirement:** The default empty state message shall be relevant to procurement (e.g., "No procurement codes generated yet...").


### Requirement: App State Schema
The application state SHALL be updated to support procurement codes instead of proverbs.

#### Scenario: Storing Codes
- **Requirement:** `AgentState` shall store `procurement_codes` as a list of objects, each containing `code` (string) and `description` (string).
- **Requirement:** The `proverbs` field shall be removed from the state definitions in both frontend types and backend `ProcurementState`.
