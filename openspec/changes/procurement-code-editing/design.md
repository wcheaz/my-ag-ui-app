## Context

The procurement code generation system currently supports two state mutations: appending new codes via the `save_procurement_code` backend agent tool, and deleting codes via index-based filter in the UI component. There is no mechanism to modify an existing code's `code` or `description` field in-place.

`ProcurementCode` in both TypeScript (`src/lib/types.ts:3`) and Python (`agent/src/agent/models.py:5`) has only `code: str` and `description: str`. No stable identifier exists, so codes can only be referenced by array index, which shifts on deletion.

The dkp-demo reference project (`hidden/PROCUREMENT-CODE-EDITING.md`) has already solved this pattern with: stable numeric IDs, ID backfill via `useMemo`, a `modify_design_entry` frontend tool, ID display in the UI, and agent prompt documentation. We adapt that proven approach.

## Goals / Non-Goals

**Goals:**

- Enable the agent to modify any previously generated code's `code` or `description` by referencing a stable ID.
- Provide a stable 1-based numeric ID for each `ProcurementCode` that survives additions, deletions, and reordering.
- Preserve list order when modifying codes (no implicit reordering).
- Maintain backward compatibility with existing state that lacks `id` fields via automatic backfill.

**Non-Goals:**

- Drag-and-drop reordering of codes.
- Bulk edit operations (modify multiple codes in one call).
- History, undo, or audit trail for modifications.
- Changes to `save_procurement_code` enforcement logic beyond adding ID assignment.
- Changes to download/export formats beyond ensuring they tolerate the new `id` field.

## Decisions

### Decision 1: Frontend tool (`useFrontendTool`) for `modify_procurement_code`

**Choice:** Implement as a frontend tool in `page.tsx`, not a backend agent tool.

**Rationale:** The modify operation is a pure state mutation — no enforcement gates, no validation, no disambiguation checks. Frontend tools have direct `setState` access, avoiding the need to construct and return `StateSnapshotEvent`. The dkp-demo project validated this pattern and abandoned the backend agent tool approach for state mutations due to unreliable propagation.

**Alternatives considered:**
- Backend agent tool returning `StateSnapshotEvent` (like `save_procurement_code`) — more complex, unnecessary for a simple mutation, proven problematic in dkp-demo.
- Shared helper module — over-engineering for a single tool.

### Decision 2: 1-based sequential integer IDs

**Choice:** Each `ProcurementCode` gets a stable `id: number` starting at 1, monotonically increasing. IDs are never reused after deletion.

**Rationale:** Matches the dkp-demo convention. 1-based IDs are human-friendly in the UI (`#1`, `#2`) and in agent communication. The "never reuse" rule prevents ambiguity — if code `#3` is deleted, the next new code gets `#4`, never `#3` again.

**Algorithm for new ID assignment:**
```
next_id = max(existing_ids, default=0) + 1
```

### Decision 3: ID backfill via `useMemo` + auto-correct

**Choice:** Add a `useMemo` in `YourMainContent` (page.tsx) that detects codes with `id == null || id === 0` and assigns the next available ID to each, then calls `setState` to persist the backfill.

**Rationale:** Existing state loaded from CopilotKit may contain codes without `id` fields (created before this change). The `useMemo` runs on every render, backfills missing IDs, and writes back via `setState`. After the first render, all codes have IDs and no further backfill occurs.

**Algorithm:**
```
codes = state.procurement_codes ?? []
if any code has id == null or id === 0:
    next_id = max(all ids, default=0)
    for each code with missing id:
        next_id += 1
        assign next_id to that code
    setState with backfilled array
```

### Decision 4: Modify tool lookup by ID, not index

**Choice:** `modify_procurement_code` takes `code_id: number` (required) and finds the target by `id` field equality. Returns an error string if not found, listing valid IDs.

**Rationale:** Index-based lookup would be fragile — the agent might have stale index knowledge. ID-based lookup is deterministic regardless of prior deletions or additions.

**Parameter contract:**
- `code_id` (required, number): The stable ID of the code to modify.
- `new_code` (optional, string): New code string. At least one of `new_code` or `new_description` must be provided.
- `new_description` (optional, string): New description. At least one of `new_code` or `new_description` must be provided.

**Return values:**
- Success: `"Procurement code #<id> updated successfully."`
- Error (no fields): `"Error: at least one of new_code or new_description must be provided."`
- Error (not found): `"Error: code_id <id> not found. Valid IDs: [<list>]."`

### Decision 5: Order preservation during modify

**Choice:** The modify handler spreads the current array, replaces only the target entry at its found index, and calls `setState` with the new array. No reordering occurs.

**Rationale:** Users and the agent expect codes to remain in their original order after a modification. The spread-and-replace-at-index pattern is immutable and preserves all positions.

### Decision 6: ID assignment in `save_procurement_code`

**Choice:** In `agent/src/agent/tools.py` line 1123, compute the next ID before creating the `ProcurementCode`:
```python
new_id = max((c.id for c in ctx.deps.state.procurement_codes), default=0) + 1
new_code = ProcurementCode(id=new_id, code=code, description=description)
```

**Rationale:** Ensures the backend tool assigns IDs at creation time. If the frontend backfill has already assigned IDs to existing codes, the backend's `max + 1` will correctly continue the sequence. If a code somehow arrives without an ID, the frontend backfill handles it on next render.

### Decision 7: Delete by ID, not index

**Choice:** Change the delete button in `procurement-codes.tsx` from `filter((_, i) => i !== index)` to `filter((c) => c.id !== item.id)`. Change `key` from `index` to `item.id`.

**Rationale:** Index-based delete is fragile when the list changes between renders. ID-based delete is deterministic. Using `item.id` as `key` gives React a stable identity for each list item.

### Decision 8: `useCopilotReadable` uses backfilled codes

**Choice:** Update `useCopilotReadable` to serialize the `codesWithIds` array (output of the backfill `useMemo`) instead of the raw `state.procurement_codes`.

**Rationale:** The agent needs to see IDs to reference them in `modify_procurement_code` calls. Without this, the agent would see codes without IDs and could not construct a valid `code_id` parameter.

### Decision 9: Agent prompt documentation

**Choice:** Add a `## MODIFYING EXISTING CODES` section to `agent/src/agent/prompt.py` that documents `modify_procurement_code`, its parameters, and the distinction from `save_procurement_code` (modify = update existing, save = append new).

**Rationale:** The agent needs explicit knowledge of the modify tool in its system prompt to decide when and how to use it. Without prompt documentation, the LLM would not know the tool exists or how to call it.

## Risks / Trade-offs

**Risk: Race between backend `save_procurement_code` and frontend backfill** → Both use `max(existing_ids) + 1`. Since `save_procurement_code` runs server-side and the frontend backfill runs client-side, there is no race — the backend appends with an ID, the frontend receives it via `StateSnapshotEvent`, and the backfill only activates if any code lacks an ID.

**Risk: `id` field leaks into download exports** → The TXT download uses `item.code - item.description` (explicit field formatting), so `id` is already excluded. The CSV/Excel exports use `Code` and `Description` columns (explicit mapping), so `id` is already excluded. No changes needed to export logic.

**Risk: State snapshot size increases** → Adding a single `id: number` field per code is negligible. No mitigation needed.

**Risk: Backfill triggers extra renders** → The backfill `useMemo` + `setState` auto-correct pattern causes one extra render on first load if codes lack IDs. After that, all codes have IDs and no further re-renders occur. Acceptable trade-off.

## Open Questions

None. All design decisions are resolved.
