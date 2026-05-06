## 1. Type Models

- [x] 1.1 Add `id: number` field to `ProcurementCode` in `src/lib/types.ts` and add `id: int = 0` field to `ProcurementCode` in `agent/src/agent/models.py`
  - TypeScript: `id: number` (required, no default)
  - Python: `id: int = 0` (defaults to 0, backfilled at runtime)
  - Done when: both type definitions compile without errors and existing code still type-checks (`npx tsc --noEmit` for TS, `python -c "from agent.models import ProcurementCode"` for Python)
  - Stop and hand off if: type changes break unrelated modules that reference `ProcurementCode`

## 2. Backend ID Assignment

- [x] 2.1 Update `save_procurement_code` in `agent/src/agent/tools.py` to assign stable IDs to newly created codes
  - Before the existing `ProcurementCode(code=code, description=description)` call at line ~1123, compute `new_id = max((c.id for c in ctx.deps.state.procurement_codes), default=0) + 1`
  - Pass `id=new_id` to the `ProcurementCode` constructor
  - Do NOT change any enforcement logic, validation, or disambiguation checks
  - Done when: `save_procurement_code` creates codes with monotonically increasing IDs; existing enforcement checks still pass; `python -c "from agent.tools import save_procurement_code"` succeeds

## 3. Frontend Backfill, Modify Tool, and State Visibility

- [x] 3.1 In `src/app/page.tsx` inside `YourMainContent`, add ID backfill `useMemo`, add `modify_procurement_code` frontend tool via `useFrontendTool`, and update `useCopilotReadable` to serialize backfilled codes
  - **Backfill `useMemo`**: Compute `codesWithIds` from `state.procurement_codes` — detect codes with `id == null || id === 0`, assign `max(existing_ids, default=0) + 1` to each, return backfilled array. Auto-correct state if backfill was needed.
  - **`modify_procurement_code` frontend tool**: Parameters: `code_id` (required, number), `new_code` (optional, string), `new_description` (optional, string). Lookup by ID in `codesWithIds`. Return error if not found (list valid IDs) or if neither field provided. On success: spread array, replace target entry, `setState`. Return success/error string.
  - **`useCopilotReadable`**: Change `value` from `JSON.stringify(state.procurement_codes ?? [])` to `JSON.stringify(codesWithIds ?? [])`. Update description to mention IDs.
  - Add `useMemo` to the import from `"react"`.
  - Done when: TypeScript compiles (`npx tsc --noEmit`); backfill assigns IDs to codes missing them; modify tool updates only the target code by ID without reordering; `useCopilotReadable` exposes IDs to the agent
  - Stop and hand off if: `useFrontendTool` or `useMemo` import fails (CopilotKit version issue)

## 4. UI Component Updates

- [x] 4.1 Update `src/components/procurement-codes.tsx` to display ID badges, use ID-based delete, and use stable React keys
  - Change `key={index}` to `key={item.id ?? index}` in the map
  - Add an ID badge `<span>` before the code badge in each item (e.g., `<span className="pc-id-badge">#{item.id}</span>`)
  - Change delete handler from `filter((_, i) => i !== index)` to `filter((c) => c.id !== item.id)`
  - Optional: add `.pc-id-badge` styling in `src/components/procurement-codes.css` to visually distinguish from the code badge
  - Done when: UI renders ID badges visible on each code card; deleting a code removes the correct item by ID; React keys are stable across renders; `npx tsc --noEmit` passes
  - Stop and hand off if: CSS class conflicts with existing badge styling require design input

## 5. Agent Prompt

- [x] 5.1 Add `## MODIFYING EXISTING CODES` section to `agent/src/agent/prompt.py` documenting the `modify_procurement_code` tool
  - Document tool name, parameters (`code_id` required, `new_code` optional, `new_description` optional), and the constraint that at least one of `new_code`/`new_description` must be provided
  - Explicitly distinguish from `save_procurement_code`: modify updates existing code by ID, save appends a new code
  - State that the agent should only modify the specific code requested, not others
  - Done when: prompt loads without syntax errors; the agent can articulate when to use modify vs save based on the prompt alone
  - Stop and hand off if: prompt structure changes affect existing workflow steps
