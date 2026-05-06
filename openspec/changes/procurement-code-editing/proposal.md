## Why

Once procurement codes are generated, the agent has no way to modify them. The only mutations available are "append a new code" (via `save_procurement_code`) and "delete a code" (via the UI delete button). If a user asks to change a code's value or description, the agent cannot comply. Additionally, codes lack stable identifiers, so neither the agent nor the user can reference a specific code by a durable handle — only by array position, which shifts on deletion.

This change enables the agent to edit existing codes in-place and gives both the agent and the UI a stable ID system for referencing them.

## What Changes

- **BREAKING**: Add a required `id: number` field to `ProcurementCode` in both TypeScript and Python type definitions.
- Add a `modify_procurement_code` frontend tool (`useFrontendTool`) that allows the agent to update a code's `code` or `description` by stable ID without shifting list order.
- Add ID backfill logic in `page.tsx` so existing codes in state that lack an `id` field are assigned one automatically on render.
- Update `save_procurement_code` backend tool to assign the next available ID when creating a new code.
- Update `useCopilotReadable` to expose IDs so the agent can identify and reference codes.
- Update the UI component to display ID badges (e.g., `#1`, `#2`) on each code card.
- Update the agent system prompt to document the modify tool and its parameters.
- Switch the delete handler from index-based to ID-based filtering.

## Capabilities

### New Capabilities

- `code-modification`: In-place editing of previously generated procurement codes via an agent-callable tool, with stable ID-based lookup, order preservation, and validation feedback.

### Modified Capabilities

- `procurement-codes`: The `ProcurementCode` type gains a required `id` field; the UI must display IDs; the agent must be able to see IDs in state and reference them when modifying codes.

## Non-goals

- No drag-and-drop reordering of codes.
- No bulk edit operations.
- No history or undo for modifications.
- No changes to the download/export feature beyond ensuring it still works with the new `id` field.
- No changes to `save_procurement_code` enforcement logic (validation, disambiguation) — only adding ID assignment.

## Scope — First Rollout

The first rollout covers the full change: stable IDs, backfill, modify tool, UI badges, prompt update, and delete-by-ID. There are no phased gates or rollout dependencies — all parts are needed for the feature to be useful.

## Impact

- **Types**: `src/lib/types.ts` (ProcurementCode), `agent/src/agent/models.py` (ProcurementCode Pydantic model)
- **Frontend**: `src/app/page.tsx` (useMemo backfill, useFrontendTool, useCopilotReadable update), `src/components/procurement-codes.tsx` (ID badges, delete-by-ID), `src/components/procurement-codes.css` (optional badge styling)
- **Backend**: `agent/src/agent/tools.py` (ID assignment in save_procurement_code), `agent/src/agent/prompt.py` (modify tool documentation)
- **Backward compatibility**: Existing state snapshots without `id` fields will be backfilled automatically. No data migration needed.
