# CopilotKit Runtime SSE Proxy Analysis

## Task 3.1: Investigate CopilotKit runtime SSE proxy behavior

### SSE Flow Analysis

#### (a) How SSE events flow from agent → HttpAgent → CopilotKit runtime → NextResponse

The complete SSE flow chain is:

1. **Agent Pod**: FastAPI application with PydanticAI AG-UI integration
   - Agent runs on port 8000 with uvicorn
   - Uses `agent.to_ag_ui()` to create the AG-UI app
   - SSE streaming is handled by PydanticAI's AG-UI protocol

2. **HttpAgent**: `@ag-ui/client` HTTP agent implementation
   - Located in `src/app/api/copilotkit/route.ts:18`
   - Configured with URL: `process.env.AGENT_URL || "http://localhost:8000/"`
   - In Kubernetes, this connects to `http://agent-service:8000/`
   - The HttpAgent makes HTTP requests to the agent endpoint

3. **CopilotKit Runtime**: `@copilotkit/runtime` integration
   - Located in `src/app/api/copilotkit/route.ts:15-20`
   - Creates a `CopilotRuntime` instance with the HttpAgent
   - Uses `ExperimentalEmptyAdapter` for single-agent setup

4. **Next.js API Route**: `copilotRuntimeNextJSAppRouterEndpoint`
   - Located in `src/app/api/copilotkit/route.ts:41-48`
   - Uses `copilotRuntimeNextJSAppRouterEndpoint()` to create the handler
   - Returns `handleRequest(req)` which processes the request and streams SSE
   - The handler returns a `NextResponse` that should stream the SSE events

5. **Next.js Standalone Server**: Production server
   - Configured in `next.config.ts:4` with `output: "standalone"`
   - Bundles `@copilotkit/runtime` via `serverExternalPackages`
   - Runs as `node server.js` in the Docker container

The complete flow:
```
Browser → NGINX Ingress → Frontend Service → CopilotKit Route → HttpAgent → Agent Service → Agent Pod
                                     ↑                                          ↓
NextResponse ← copilotRuntimeNextJSAppRouterEndpoint ← CopilotRuntime ← SSE Stream
```

#### (b) Whether any buffering occurs in this chain

**Potential buffering points identified:**

1. **NGINX Ingress**: 
   - Already configured with SSE annotations in `k8s/ingress.yaml:26-30`
   - `proxy-buffering: "off"` and `proxy-request-buffering: "off"` should prevent buffering
   - However, NGINX may still buffer under certain conditions

2. **Next.js Standalone Server**:
   - **HIGH RISK**: Next.js standalone server is known to handle streaming differently than dev server
   - The standalone server (`server.js` from `.next/standalone`) may buffer responses by default
   - No explicit streaming configuration in `next.config.ts`

3. **CopilotKit Runtime**:
   - The `copilotRuntimeNextJSAppRouterEndpoint` may have internal buffering
   - No explicit streaming configuration visible in the route setup

4. **HttpAgent**:
   - The `@ag-ui/client` HttpAgent may buffer responses before streaming
   - Version 0.0.48 is being used - need to verify if this version properly handles SSE

#### (c) Whether Next.js App Router streaming is correctly configured

**Current Configuration Issues:**

1. **Missing Streaming Configuration**:
   - `next.config.ts` has no streaming-related settings
   - No explicit configuration for SSE or long-lived connections
   - The `output: "standalone"` setting may affect streaming behavior

2. **Potential Next.js Standalone Issues**:
   - Next.js standalone server is known to have different streaming behavior than dev server
   - The standalone server may not properly flush SSE events to the client
   - No custom server configuration for streaming in the Dockerfile

3. **Missing Response Headers**:
   - The API route doesn't explicitly set SSE headers like `Content-Type: text/event-stream`
   - No explicit `Cache-Control: no-cache` or `Connection: keep-alive` headers
   - These headers may be handled internally by CopilotKit but not visible in the code

#### (d) Configuration options that control streaming behavior

**Identified Configuration Points:**

1. **Next.js Configuration** (`next.config.ts`):
   ```typescript
   const nextConfig: NextConfig = {
     output: "standalone",
     serverExternalPackages: ["@copilotkit/runtime"],
     // Missing streaming configuration:
     // - experimental: { streaming: true }
     // - httpAgentOptions: { keepAlive: true }
     // - etc.
   };
   ```

2. **CopilotKit Runtime Configuration** (`src/app/api/copilotkit/route.ts`):
   ```typescript
   const runtime = new CopilotRuntime({
     agents: {
       my_agent: new HttpAgent({ url: process.env.AGENT_URL || "http://localhost:8000/" }),
     },
     // Missing streaming configuration options
   });
   
   export const POST = async (req: NextRequest) => {
     const { handleRequest } = copilotRuntimeNextJSAppRouterEndpoint({
       runtime,
       serviceAdapter,
       endpoint: "/api/copilotkit",
       // Missing streaming configuration
     });
     return handleRequest(req);
   };
   ```

3. **Agent Configuration** (`agent/src/main.py`):
   ```python
   if __name__ == "__main__":
     uvicorn.run("main:app", host="0.0.0.0", port=3000, reload=True)
     # Missing streaming configuration:
     # - timeout settings
     # - workers configuration
     # - keep-alive settings
   ```

4. **Agent Dockerfile** (`agent/Dockerfile`):
   ```dockerfile
   CMD ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
   # Missing streaming configuration:
   # --timeout-keep-alive 300
   # --workers 1
   # --limit-concurrency 100
   ```

### Root Cause Hypothesis

Based on this analysis, the most likely root cause is:

**Next.js Standalone Server Buffering**: The Next.js standalone server (`output: "standalone"`) is likely buffering the SSE response instead of streaming it incrementally. This is a known issue with Next.js standalone mode where streaming responses behave differently than in the development server.

The NGINX annotations are already in place and should prevent buffering at the ingress level. The agent appears to be working correctly based on health checks. The issue is most likely in the CopilotKit runtime → Next.js standalone server interaction.

### Recommended Next Steps

1. **Immediate**: Add explicit streaming configuration to `next.config.ts`
2. **Investigation**: Check if `@copilotkit/runtime` v1.54.0 has known streaming issues with standalone mode
3. **Testing**: Create a minimal SSE endpoint to isolate whether the issue is CopilotKit or Next.js
4. **Configuration**: Add SSE headers and streaming timeouts to the CopilotKit route