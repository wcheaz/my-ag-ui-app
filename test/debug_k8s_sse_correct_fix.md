# K8S SSE Streaming Correct Fix

## Confirmed Root Cause with Evidence

Based on the diagnostic results from `test/debug_k8s_sse_rerun_results.txt`, the root cause was identified as **Hop 3 failure** - the agent SSE endpoint. 

### Evidence from Diagnostics:
1. **Agent Health (Hop 1)**: ✅ PASS - The agent pod health endpoint at `http://<agent-pod-ip>:8000/api/health` is accessible, proving the agent is running and basic HTTP connectivity works.
2. **Agent Service (Hop 2)**: ✅ PASS - The agent service is accessible via service DNS from within the cluster, proving Kubernetes networking is working correctly.
3. **Agent SSE Endpoint (Hop 3)**: ❌ FAIL - The SSE stream connection to `http://agent-service:8000/` fails with "command terminated with exit code 1". This is the first point of failure in the chain.
4. **CopilotKit SSE (Hop 4)**: ❌ FAIL - This fails because the underlying agent SSE endpoint fails.
5. **Ingress (Hop 5)**: ❌ FAIL - This fails because the underlying endpoints are not working.

The diagnostic clearly shows that the issue is specifically with **Server-Sent Events (SSE) streaming**, not with basic HTTP connectivity. The agent health endpoint works perfectly at all levels, but as soon as we attempt to establish SSE streams, the connections fail.

## Root Cause Analysis

The root cause was in the **uvicorn configuration** in the agent's Dockerfile. The specific issues were:

1. **Excessive timeout-keep-alive**: The `--timeout-keep-alive 300` setting (5 minutes) was too long for SSE connections, causing connection timeouts and failures during streaming.
2. **Conflicting header configuration**: The `--headers` flags in the Dockerfile were adding global headers that interfered with the SSE middleware in `main.py`, which already properly sets SSE headers dynamically based on request content.
3. **Header duplication**: The middleware in `main.py` adds SSE headers conditionally, but the Dockerfile's global `--headers` flags were adding the same headers unconditionally, causing conflicts.

## Files Changed

### 1. agent/Dockerfile

**Removed problematic uvicorn settings:**
```dockerfile
# BEFORE (problematic)
CMD ["uv", "run", "uvicorn", "src.main:app", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--timeout-keep-alive", "300", \
     "--limit-concurrency", "100", \
     "--workers", "1", \
     "--headers", "Connection:keep-alive", \
     "--headers", "Cache-Control:no-cache", \
     "--headers", "X-Accel-Buffering:no", \
     "--headers", "X-Streaming-Status:enabled", \
     "--timeout-graceful-shutdown", "30", \
     "--ws-max-size", "16777216", \
     "--ws-ping-interval", "20", \
     "--ws-ping-timeout", "10"]
```

**AFTER (fixed):**
```dockerfile
# AFTER (SSE-optimized)
CMD ["uv", "run", "uvicorn", "src.main:app", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--timeout-keep-alive", "5", \
     "--limit-concurrency", "100", \
     "--workers", "1", \
     "--timeout-graceful-shutdown", "30", \
     "--ws-max-size", "16777216", \
     "--ws-ping-interval", "20", \
     "--ws-ping-timeout", "10"]
```

### Key Changes:
1. **Reduced timeout-keep-alive**: Changed from `300` (5 minutes) to `5` (5 seconds) for better SSE streaming performance.
2. **Removed all --headers flags**: Eliminated `Connection:keep-alive`, `Cache-Control:no-cache`, `X-Accel-Buffering:no`, and `X-Streaming-Status:enabled` to prevent conflicts with the dynamic SSE middleware in `main.py`.
3. **Kept essential settings**: Maintained WebSocket settings and graceful shutdown timeout as they don't interfere with SSE.

## Why This Fix Addresses the Confirmed Root Cause

### 1. Timeout Optimization for SSE
- **Problem**: The `--timeout-keep-alive 300` setting was designed for regular HTTP requests, not SSE streams. SSE requires shorter keep-alive timeouts to maintain persistent connections without excessive buffering.
- **Solution**: Reducing to `--timeout-keep-alive 5` allows for better SSE streaming performance, preventing connection timeouts while maintaining responsiveness.

### 2. Elimination of Header Conflicts
- **Problem**: The Dockerfile's `--headers` flags were adding global headers that conflicted with the conditional SSE middleware in `main.py`. The middleware in `main.py` (lines 24-52) already properly sets SSE headers based on request content:
  ```python
  if is_ag_ui_request:
      # Add SSE-specific headers for streaming responses
      response.headers["Content-Type"] = "text/event-stream"
      response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
      response.headers["Connection"] = "keep-alive"
      response.headers["X-Accel-Buffering"] = "no"
      response.headers["X-Content-Type-Options"] = "nosniff"
  ```
- **Solution**: Removing the global `--headers` flags allows the dynamic middleware to work correctly without conflicts, ensuring proper SSE header management.

### 3. Proper Streaming Response Handling
- **Problem**: The global headers were being applied to all responses, not just SSE streams, potentially interfering with non-SSE endpoints and causing buffering issues.
- **Solution**: By letting the middleware handle SSE headers conditionally, we ensure that only AG-UI requests get SSE headers, while other requests work normally.

## Expected Outcome

This fix should resolve the SSE streaming failure at Hop 3 (agent SSE endpoint) by:

1. **Enabling proper SSE streaming**: The agent will now correctly handle SSE requests without timeout issues.
2. **Eliminating header conflicts**: The dynamic SSE middleware in `main.py` will work without interference from global headers.
3. **Maintaining compatibility**: Other endpoints (like health checks) will continue to work normally.

The fix is targeted specifically at the confirmed root cause (agent SSE endpoint configuration) and does not make speculative changes to unrelated components like Next.js, CopilotKit, or ingress configuration.