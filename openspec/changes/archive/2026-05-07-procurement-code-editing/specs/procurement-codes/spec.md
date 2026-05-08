## MODIFIED Requirements

### Requirement: Procurement Codes UI
The application SHALL provide a user interface to display generated procurement codes to the user.

#### Scenario: Displaying Procurement Codes
- **Requirement:** The UI SHALL display a list of generated procurement codes in a specialized card component.
- **Requirement:** Each list item SHALL show the stable `id` as a visible badge (e.g., `#1`, `#2`), the `code`, and the `description`.
- **Requirement:** The UI SHALL allow the user to remove individual code items from the list by ID, not by array index.
- **Requirement:** The default empty state message SHALL be relevant to procurement (e.g., "No procurement codes generated yet...").
- **Requirement:** Each list item SHALL use its stable `id` as the React `key` prop, not the array index.

### Requirement: App State Schema
The application state SHALL store procurement codes with stable numeric identifiers.

#### Scenario: Storing Codes
- **Requirement:** `AgentState` SHALL store `procurement_codes` as a list of objects, each containing `id` (number, 1-based, never reused), `code` (string), and `description` (string).
- **Requirement:** The `id` field SHALL be assigned at creation time by the backend `save_procurement_code` tool using `max(existing_ids, default=0) + 1`.
- **Requirement:** IDs SHALL NOT be reused after deletion. If code #3 is deleted, the next new code SHALL receive ID 4 or higher, never 3.

## ADDED Requirements

### Requirement: ID backfill for existing state
The frontend SHALL automatically assign stable IDs to any procurement code that lacks an `id` field or has `id` equal to 0 or null. This backfill SHALL occur on every render via a `useMemo` hook that detects missing IDs and persists them via `setState`.

#### Scenario: State loaded without IDs
- **GIVEN** the state contains procurement codes without `id` fields (e.g., from a session started before this change)
- **WHEN** the component renders
- **THEN** the backfill logic SHALL assign sequential IDs starting from `max(existing_ids, default=0) + 1` and call `setState` with the updated array

#### Scenario: State already has IDs
- **GIVEN** all procurement codes already have non-zero, non-null `id` fields
- **WHEN** the component renders
- **THEN** no backfill SHALL occur and no extra `setState` call SHALL be made

### Requirement: Agent state visibility includes IDs
The `useCopilotReadable` hook SHALL serialize the backfilled codes array (with IDs) so the agent can see each code's ID and reference it when calling `modify_procurement_code`.

#### Scenario: Agent sees code IDs
- **GIVEN** codes with IDs 1, 2, and 3 exist
- **WHEN** the agent reads the procurement codes state
- **THEN** the serialized JSON SHALL include the `id` field for each code

### Requirement: Delete by ID
The delete button in the procurement codes UI SHALL filter by the code's `id` field, not by array index.

#### Scenario: Deleting a code preserves correct item
- **GIVEN** codes with IDs [1, 2, 3] in that order
- **WHEN** the user clicks delete on code #2
- **THEN** the resulting array SHALL contain codes with IDs [1, 3] in that order, with no other changes

### Requirement: ID assignment in save_procurement_code
The backend `save_procurement_code` tool SHALL assign the next available ID when creating a new `ProcurementCode`.

#### Scenario: New code gets next ID
- **GIVEN** existing codes have IDs [1, 3, 5] (gaps from deletions)
- **WHEN** `save_procurement_code` creates a new code
- **THEN** the new code SHALL receive ID 6

#### Scenario: First code gets ID 1
- **GIVEN** no codes exist
- **WHEN** `save_procurement_code` creates the first code
- **THEN** the new code SHALL receive ID 1
