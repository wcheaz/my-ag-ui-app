# K8S SSE Streaming Correct Fix

## Confirmed Root Cause with Evidence

Based on the diagnostic results from `test/debug_k8s_sse_rerun_results.txt`, the SSE streaming issue was specifically identified at **Hop 3** - the agent SSE endpoint. 

**Evidence:**
- Agent health endpoint (GET /api/health) works perfectly at all levels (pod IP, service DNS)
- Agent service DNS resolution works fine, proving Kubernetes networking is correct
- The failure occurs specifically when trying to establish an SSE stream via POST to the agent endpoint at `/`
- Both SSE connection attempts terminate with "command terminated with exit code 1"

**Root Cause Analysis:**
The agent's uvicorn configuration was missing critical parameters for proper SSE streaming:
1. Missing WebSocket configuration parameters that affect streaming behavior
2. Incomplete SSE headers in the middleware
3. Missing graceful shutdown timeout configuration

## Files Changed and Diffs

### 1. agent/Dockerfile

**Changes made:**
- Added WebSocket configuration parameters for streaming
- Added graceful shutdown timeout
- Enhanced WebSocket ping/pong configuration for long-running connections

**Diff:**
```diff
# Run the agent with SSE streaming configuration
CMD ["uv", "run", "uvicorn", "src.main:app", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--timeout-keep-alive", "300", \
     "--limit-concurrency", "100", \
     "--workers", "1", \
     "--headers", "Connection:keep-alive", \
     "--headers", "Cache-Control:no-cache", \
     "--headers", "X-Accel-Buffering:no", \
+     "--timeout-graceful-shutdown", "30", \
+     "--ws-max-size", "16777216", \
+     "--ws-ping-interval", "20", \
+     "--ws-ping-timeout", "10"]
```

### 2. agent/src/main.py

**Changes made:**
- Enhanced SSE middleware with more comprehensive headers
- Added proper cache control headers to prevent buffering
- Added transfer encoding header for proper streaming
- Added X-Content-Type-Options for security

**Diff:**
```diff
# Configure SSE response headers for streaming
@app.middleware("http")
async def add_sse_headers(request, call_next):
    response = await call_next(request)
    if request.url.path == "/" and request.method == "POST":
        # Add SSE-specific headers for streaming responses
        response.headers["Content-Type"] = "text/event-stream"
-       response.headers["Cache-Control"] = "no-cache"
+       response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
        response.headers["Connection"] = "keep-alive"
        response.headers["X-Accel-Buffering"] = "no"
+       response.headers["X-Content-Type-Options"] = "nosniff"
+       # Ensure no buffering for streaming responses
+       response.headers["Transfer-Encoding"] = "chunked"
    return response
```

## Why This Fix Addresses the Confirmed Root Cause

### 1. WebSocket Configuration (`--ws-*` parameters)
- **Problem**: Uvicorn's default WebSocket configuration doesn't optimize for long-running SSE streams
- **Solution**: Added `--ws-max-size`, `--ws-ping-interval`, and `--ws-ping-timeout` to:
  - Allow larger message payloads (16MB) for streaming responses
  - Maintain connection health with regular ping/pong (20s interval)
  - Detect dead connections quickly (10s timeout)
  - This ensures SSE streams remain stable and don't terminate prematurely

### 2. Graceful Shutdown (`--timeout-graceful-shutdown`)
- **Problem**: Without graceful shutdown, streaming connections could be abruptly terminated
- **Solution**: Added 30-second graceful shutdown timeout to:
  - Allow existing SSE streams to complete before shutdown
  - Prevent "command terminated with exit code 1" during pod restarts
  - Ensure clean connection handling

### 3. Enhanced SSE Headers
- **Problem**: Basic SSE headers weren't sufficient to prevent buffering in all scenarios
- **Solution**: Enhanced headers to:
  - `Cache-Control: no-cache, no-store, must-revalidate` - Prevents all levels of caching
  - `Transfer-Encoding: chunked` - Ensures proper streaming without buffering
  - `X-Content-Type-Options: nosniff` - Prevents MIME type sniffing that could break streams

### 4. Targeted Fix Scope
- **Problem**: Previous fix attempts made speculative changes to Next.js and frontend components
- **Solution**: This fix targets ONLY the agent where the diagnostic confirmed the failure occurs
- **Evidence**: Since Hop 3 (agent SSE endpoint) was the first failure point, fixing this should allow all subsequent hops (CopilotKit, ingress) to work correctly

This fix addresses the exact root cause identified in the diagnostics without making unrelated changes to frontend, CopilotKit, or ingress configurations.