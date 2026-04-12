# K8S SSE Streaming Analysis

## Diagnostic Results Summary

The diagnostic script tested SSE connectivity at each hop in the Kubernetes deployment. All hops show successful basic connectivity, but SSE streaming fails due to protocol-level issues.

### Test Results

| Hop | Status | Details |
|-----|--------|---------|
| 1. Agent pod health | ✅ PASS | Agent health endpoint accessible from within agent |
| 2. Agent service from frontend | ✅ PASS | Agent service accessible from frontend pod |
| 3. Agent SSE endpoint | ⚠️ CONNECTED | Returns 422 (invalid request format) but connection works |
| 4. CopilotKit SSE endpoint | ⚠️ CONNECTED | Returns 400 (bad request) but connection works |
| 5. External path through ingress | ⚠️ CONNECTED | Returns 400 (missing method field) but connection works |

## Root Cause Analysis

### Failing Hop: SSE Protocol Handling (Multiple Hops)

**Error/Behavior Observed:**
- All basic HTTP connectivity works (health endpoints return 200)
- SSE endpoints accept connections but return protocol errors:
  - Agent root endpoint: HTTP 422 (Unprocessable Entity)
  - CopilotKit endpoint: HTTP 400 (Bad Request)
  - External ingress: HTTP 400 (Missing method field)

### Likely Root Cause: CopilotKit Runtime SSE Proxy Buffering

The root cause appears to be in the CopilotKit runtime SSE proxy behavior in the Next.js standalone server. Here's the evidence:

1. **Basic connectivity works at all hops**: This rules out network issues, firewall problems, or service discovery failures.

2. **Agent accepts connections but returns 422**: The agent's AG-UI endpoint is reachable but expects a specific protocol format. The 422 response indicates the agent is processing the request but rejecting it due to invalid format.

3. **CopilotKit returns 400**: The CopilotKit route is receiving requests but rejecting them, suggesting the request format doesn't match what CopilotKit expects.

4. **External path also fails**: The issue persists through the full path, confirming it's not an intra-cluster networking problem.

The most likely issue is that the **CopilotKit runtime's `copilotRuntimeNextJSAppRouterEndpoint` is buffering SSE responses** when running in Next.js standalone mode. In local development, Next.js dev server handles streaming correctly, but the standalone server has different default behaviors.

### Technical Details

**SSE Flow:**
```
Browser → NGINX Ingress → Frontend Service → CopilotKit Route → HttpAgent → Agent Service
```

**Critical Point:** The CopilotKit route (`src/app/api/copilotkit/route.ts`) uses:
```typescript
export const POST = async (req: NextRequest) => {
  const { handleRequest } = copilotRuntimeNextJSAppRouterEndpoint({
    runtime,
    serviceAdapter,
    endpoint: "/api/copilotkit",
  });
  return handleRequest(req);
};
```

The `handleRequest` function is supposed to stream SSE events, but Next.js standalone server may be buffering the entire response before sending it to the client.

## Recommended Fix

1. **Investigate CopilotKit/Next.js streaming configuration**:
   - Check if `copilotRuntimeNextJSAppRouterEndpoint` needs specific streaming configuration for standalone mode
   - Verify Next.js standalone server SSE support
   - Check if additional headers or response configuration is needed

2. **Alternative approaches**:
   - Add explicit SSE streaming headers to the CopilotKit route
   - Configure Next.js to disable response buffering for SSE endpoints
   - Implement a custom SSE proxy that bypasses Next.js if needed

3. **Next steps**:
   - Examine the `@copilotkit/runtime` implementation for standalone mode compatibility
   - Check Next.js configuration for streaming in standalone builds
   - Test with a simple SSE endpoint to isolate CopilotKit vs Next.js issues

## Verification

The fix should be verified by:
1. Running the diagnostic script again - all SSE endpoints should return 200 with proper streaming headers
2. Submitting a real procurement request and receiving a complete SSE stream with procurement code
3. Comparing the response length and content to local development behavior