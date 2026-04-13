Ralph iteration 40: Fix K8S agent SSE streaming with proper response headers

Tasks completed:
- [x] 10.1 Based on the confirmed root cause from task 9.1, implement the targeted fix. The fix MUST address the specific hop that fails, not make speculative changes to unrelated config. Document the change in `test/debug_k8s_sse_correct_fix.md` with: (a) confirmed root cause with evidence from diagnostics, (b) exact files changed with diffs, (c) why this fix addresses the confirmed root cause.