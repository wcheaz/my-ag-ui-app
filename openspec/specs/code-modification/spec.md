# code-modification Specification

## Purpose
Defines the agent's ability to modify existing procurement codes in-place via a frontend tool, with stable ID-based lookup and order preservation.

## Requirements
### Requirement: In-place code modification via agent tool
The system SHALL provide a `modify_procurement_code` frontend tool (`useFrontendTool`) that allows the agent to update a previously generated procurement code's `code` field, `description` field, or both, without changing the code's position in the list.

#### Scenario: Agent modifies a code's description only
- **WHEN** the agent calls `modify_procurement_code` with `code_id` set to a valid existing ID and `new_description` set to a non-empty string
- **THEN** the code with that ID SHALL have its `description` updated to the provided value, its `code` unchanged, its list position unchanged, and all other codes untouched

#### Scenario: Agent modifies a code's code string only
- **WHEN** the agent calls `modify_procurement_code` with `code_id` set to a valid existing ID and `new_code` set to a non-empty string
- **THEN** the code with that ID SHALL have its `code` updated to the provided value, its `description` unchanged, its list position unchanged, and all other codes untouched

#### Scenario: Agent modifies both code and description
- **WHEN** the agent calls `modify_procurement_code` with `code_id` set to a valid existing ID, `new_code` set to a non-empty string, and `new_description` set to a non-empty string
- **THEN** the code with that ID SHALL have both `code` and `description` updated, its list position unchanged, and all other codes untouched

#### Scenario: Agent calls modify with no update fields
- **WHEN** the agent calls `modify_procurement_code` with `code_id` set to a valid ID but neither `new_code` nor `new_description` provided
- **THEN** the tool SHALL return an error string indicating that at least one of `new_code` or `new_description` must be provided, and the state SHALL remain unchanged

#### Scenario: Agent references a non-existent code ID
- **WHEN** the agent calls `modify_procurement_code` with a `code_id` that does not match any existing code's `id`
- **THEN** the tool SHALL return an error string listing all valid IDs and the state SHALL remain unchanged

### Requirement: Stable ID-based lookup for modification
The `modify_procurement_code` tool SHALL locate the target code by its stable `id` field, not by array index.

#### Scenario: Lookup after prior deletions
- **GIVEN** codes with IDs 1, 2, and 3 exist, and code #2 has been deleted
- **WHEN** the agent calls `modify_procurement_code` with `code_id` 3
- **THEN** code #3 SHALL be found and updated correctly despite the gap in the ID sequence

### Requirement: Order preservation during modification
When a code is modified, its position in the `procurement_codes` array SHALL NOT change. No implicit reordering SHALL occur.

#### Scenario: Middle item modified preserves order
- **GIVEN** codes with IDs [1, 2, 3] in that order
- **WHEN** code #2 is modified
- **THEN** the resulting array order SHALL still be [1, 2, 3] with code #2's updated fields

### Requirement: Agent prompt documents the modify tool
The agent system prompt SHALL include a section documenting `modify_procurement_code`, its parameters (`code_id`, `new_code`, `new_description`), and the distinction from `save_procurement_code` (modify updates existing, save appends new).

#### Scenario: Agent knows when to modify vs save
- **WHEN** a user asks to change an existing code
- **THEN** the agent SHALL call `modify_procurement_code` and NOT `save_procurement_code`

#### Scenario: Agent knows when to save vs modify
- **WHEN** a user asks to generate a new code
- **THEN** the agent SHALL call `save_procurement_code` and NOT `modify_procurement_code`
