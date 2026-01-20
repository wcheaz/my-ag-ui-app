1. [x] Update `src/lib/types.ts` to define `ProcurementCode` type and update `AgentState`. <!-- id: 0 -->
2. [x] Update `agent/src/agent.py` to update `ProcurementState` definition. <!-- id: 1 -->
3. [x] Create `src/components/procurement-codes.tsx` to display codes and descriptions. <!-- id: 2 -->
4. [x] Update `src/app/page.tsx` to replace `ProverbsCard` with `ProcurementCodes` and update initial state. <!-- id: 3 -->
5. [x] Remove `src/components/proverbs.tsx`. <!-- id: 4 -->
6. [x] Verify the application loads and the new empty state message is displayed. <!-- id: 5 -->
7. [ ] Implement `save_procurement_code` tool in `agent/src/agent.py`. <!-- id: 6 -->
8. [ ] Register `save_procurement_code` tool in `agent`. <!-- id: 7 -->
9. [ ] Update `STATIC_SYSTEM_PROMPT` to use the new tool. <!-- id: 8 -->
10. [ ] Manual test: Generate a code and verify it appears in the list. <!-- id: 9 -->
