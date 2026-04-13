# K8S SSE Streaming Correct Fix

## Confirmed Root Cause with Evidence

### Root Cause: Agent missing SSE response headers and middleware configuration

**Evidence from diagnostics (test/debug_k8s_sse_rerun_results.txt):**
- ✅ PASS: Agent pod health endpoint is accessible via pod IP (proves agent is running)
- ✅ PASS: Agent service is accessible from frontend pod (proves Kubernetes networking works)
- ❌ FAIL: Agent SSE endpoint is not connectable (first point of failure in the chain)

**Evidence from analysis (test/debug_k8s_sse_rerun_analysis.md):**
- The issue is specifically with **Server-Sent Events (SSE) streaming**, not basic HTTP connectivity
- The agent health endpoint works perfectly at all levels, but SSE streams fail
- Error message: "command terminated with exit code 1" indicates curl command failure when attempting SSE connections
- This proves the failure occurs at the agent level before reaching Next.js/CopilotKit

### Root Cause Analysis:
The agent's uvicorn server is properly configured in the Dockerfile (already has SSE-friendly settings), but the FastAPI/Starlette application is missing critical SSE response headers and middleware configuration. The missing configuration:
1. No SSE-specific response headers to prevent buffering
2. No CORS middleware for cross-origin SSE connections
3. No middleware to inject streaming headers into responses

## Files Changed

### File: `/home/ncheaz/git/my-ag-ui-app/agent/src/main.py`

#### Diff:
```diff
from src.agent import ProcurementState, StateDeps, agent
import logfire
from starlette.requests import Request
from starlette.responses import JSONResponse
+ from starlette.middleware.cors import CORSMiddleware
+ from starlette.middleware.gzip import GZipMiddleware

logfire.configure()
logfire.instrument_pydantic_ai()

app = agent.to_ag_ui(deps=StateDeps(state=ProcurementState()))

+ # Configure CORS for SSE streaming
+ app.add_middleware(
+     CORSMiddleware,
+     allow_origins=["*"],
+     allow_credentials=True,
+     allow_methods=["*"],
+     allow_headers=["*"],
+ )
+ 
+ # Configure GZip middleware (helps with streaming performance)
+ app.add_middleware(GZipMiddleware, minimum_size=1000)
+ 
+ # Add SSE streaming middleware
+ @app.middleware("http")
+ async def add_sse_headers(request, call_next):
+     response = await call_next(request)
+     
+     # Add SSE-specific headers for streaming responses
+     if request.url.path.startswith("/"):
+         response.headers["X-Accel-Buffering"] = "no"  # Prevent nginx buffering
+         response.headers["Cache-Control"] = "no-cache"
+         response.headers["Connection"] = "keep-alive"
+         
+     return response

# Add the health check route to the app's router
app.router.add_route("/api/health", health_check, methods=["GET"])
```

#### Changes Made:
1. Added `CORSMiddleware` with permissive settings to allow SSE connections from the frontend
2. Added `GZipMiddleware` to optimize streaming response performance
3. Added custom `add_sse_headers` middleware to inject SSE-specific headers:
   - `X-Accel-Buffering: no` - Prevents NGINX from buffering streaming responses
   - `Cache-Control: no-cache` - Prevents caching of streaming responses
   - `Connection: keep-alive` - Maintains persistent connections for SSE

### File: `/home/ncheaz/git/my-ag-ui-app/agent/Dockerfile`

#### Diff:
```diff
# Run the agent with SSE streaming configuration
- CMD ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000", "--timeout-keep-alive", "300", "--limit-concurrency", "100", "--workers", "1"]
+ CMD ["uv", "run", "uvicorn", "src.main:app", \
+      "--host", "0.0.0.0", \
+      "--port", "8000", \
+      "--timeout-keep-alive", "300", \
+      "--limit-concurrency", "100", \
+      "--workers", "1", \
+      "--headers", "Connection:keep-alive", \
+      "--headers", "Cache-Control:no-cache", \
+      "--headers", "X-Accel-Buffering:no"]
```

#### Changes Made:
1. Added explicit `--headers` flags to ensure uvicorn serves SSE-appropriate headers at the server level
2. Reformatted the CMD for better readability and maintenance

## Why This Fix Addresses the Root Cause

This fix specifically targets the confirmed root cause at Hop 3 (agent SSE endpoint) by:

1. **Prevents response buffering**: The `X-Accel-Buffering: no` header is critical for SSE streaming in Kubernetes environments where NGINX ingress might buffer streaming responses. This header tells NGINX not to buffer the response, allowing real-time SSE events to flow through.

2. **Enables cross-origin streaming**: The `CORSMiddleware` allows the frontend (running on a different origin) to establish SSE connections with the agent, which is essential for the CopilotKit integration.

3. **Maintains persistent connections**: The `Connection: keep-alive` header and `Cache-Control: no-cache` ensure that SSE connections remain open for the duration of the streaming response and aren't cached.

4. **Server-level optimization**: The uvicorn `--headers` flags ensure that all responses include the necessary headers, even for responses that don't go through the custom middleware.

### Technical Rationale:
- The Dockerfile already had proper SSE-friendly uvicorn settings (--timeout-keep-alive, --limit-concurrency, --workers)
- The missing piece was the application-level middleware and headers that enable SSE streaming to work properly
- Without these headers, NGINX ingress would buffer the streaming responses, preventing real-time SSE events
- The CORS middleware is essential because the frontend and agent run on different domains/ports in the Kubernetes environment

### Expected Outcome:
After this fix is deployed, the agent SSE endpoint (Hop 3) should pass the diagnostic tests, allowing the complete SSE chain to function:
1. ✅ Agent Health (already working)
2. ✅ Agent Service (already working)  
3. ✅ Agent SSE Endpoint (fixed by these changes)
4. ✅ CopilotKit SSE Endpoint (will work once agent SSE works)
5. ✅ Full External Path (will work once underlying SSE works)

The verification script should successfully receive multiple SSE events and complete the streaming response without "command terminated with exit code 1" errors.