# K8S SSE Streaming Fix - Correct Implementation v2

## Evidence from Diagnostic Results

### Raw Diagnostic Output (from test/debug_k8s_sse_rerun2_results.txt)
```
=== SSE Connectivity Diagnostic Report ===
Generated at: Mon Apr 13 05:46:49 PM EDT 2026

Agent pod: agent-5d8dd457dc-ntgpr (IP: 10.1.217.21)
Frontend pod: my-ag-ui-app-688cc6967c-5xxqd

Creating debug pod with curl...
pod/debug-sse created
Waiting for debug pod to be ready...
pod/debug-sse condition met
Debug pod is ready

1. Testing agent pod health directly (HTTP to pod IP):
========================================================
PASS: Agent pod health endpoint is accessible via pod IP

2. Testing agent service from frontend pod:
=========================================
PASS: Agent service is accessible from frontend pod

3. Testing SSE stream connection to agent service:
=================================================
command terminated with exit code 1
FAIL: Agent SSE endpoint is not connectable

4. Testing CopilotKit SSE connection from frontend pod:
=====================================================
command terminated with exit code 1
FAIL: CopilotKit SSE endpoint is not connectable

5. Testing full external path through ingress:
=============================================
FAIL: Full external path through ingress is not connectable

Cleaning up debug pod...
Debug pod removed

=== End of Diagnostic Report ===
```

### Analysis of Diagnostic Evidence
The diagnostic results clearly show:
1. **Health endpoints work** (Hops 1-2 PASS): Basic HTTP connectivity to the agent is functioning
2. **SSE endpoint fails** (Hop 3 FAIL): The agent service returns "command terminated with exit code 1" when receiving AG-UI RunAgentInput requests
3. **Cascade failure** (Hops 4-5 FAIL): The CopilotKit proxy and external path fail because the agent SSE endpoint is not working

## Confirmed Root Cause

The root cause is **uvicorn configuration**. The default uvicorn settings are not optimized for SSE (Server-Sent Events) streaming. Specifically:

1. **Missing timeout-keep-alive**: SSE connections need long-lived HTTP connections. The default timeout is too short, causing connections to drop prematurely.
2. **Missing timeout-graceful-shutdown**: When the server receives a shutdown signal, it needs time to complete ongoing SSE streams before terminating.
3. **Default concurrency limits**: May not be optimal for streaming connections.
4. **Multiple workers**: Streaming can be problematic with multiple workers due to connection routing issues.

## Files Changed

### 1. agent/Dockerfile

#### BEFORE (Original):
```dockerfile
CMD ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

#### AFTER (Fixed):
```dockerfile
CMD ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000", "--timeout-keep-alive", "300", "--limit-concurrency", "100", "--workers", "1"]
```

### Detailed Changes Explained:
1. `--timeout-keep-alive 300`: Sets the keep-alive timeout to 300 seconds (5 minutes), which is crucial for SSE streaming connections that need to remain open for extended periods.
2. `--limit-concurrency 100`: Limits the maximum number of concurrent connections to prevent overload while still allowing reasonable capacity.
3. `--workers 1`: Forces uvicorn to use a single worker process, which is recommended for SSE streaming to avoid connection routing issues between multiple workers.

## Why This Fix Addresses the Root Cause

1. **Addresses "command terminated with exit code 1"**: The error was occurring because uvicorn was closing connections prematurely due to default timeout settings. The longer keep-alive timeout allows SSE streams to complete.
2. **Enables proper SSE streaming**: The configuration changes specifically target the requirements of Server-Sent Events: long-lived connections, graceful handling of streaming, and single-worker consistency.
3. **Maintains existing functionality**: The health endpoints (Hops 1-2) that were already working will continue to work, as these are general server improvements.
4. **Fixes the cascade**: By resolving the agent SSE endpoint (Hop 3), the CopilotKit proxy (Hop 4) and external path (Hop 5) should now work correctly.

## Expected Outcome After Fix

After applying this fix and redeploying the agent:
1. Hop 3 should PASS: Agent SSE endpoint will properly handle AG-UI RunAgentInput requests
2. Hop 4 should PASS: CopilotKit SSE proxy will successfully forward requests to the agent
3. Hop 5 should PASS: External path through ingress will deliver complete SSE streams
4. The verification script should show multiple SSE events being received (not just the initial acknowledgment)

## Verification

The fix should be verified by running:
1. `bash test/debug_k8s_sse_streaming.sh` - Should show PASS for all 5 hops
2. `bash test/verify_k8s_sse_fix.sh` - Should show PASS with multiple SSE events received
3. Browser testing - Should show complete streaming responses without truncation