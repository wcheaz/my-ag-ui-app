# SSE Connectivity Analysis

## Diagnostic Results Summary

Based on the diagnostic results, **ALL hops are failing** due to a common root cause.

### Test Results

| Hop | Status | Details |
|-----|--------|---------|
| 1. Agent pod health | ❌ FAIL | curl not found in container |
| 2. Agent service from frontend | ❌ FAIL | curl not found in container |
| 3. Agent SSE endpoint | ❌ FAIL | bash not found in container |
| 4. CopilotKit SSE endpoint | ❌ FAIL | bash not found in container |
| 5. External path through ingress | ❌ FAIL | Unable to test external connectivity |

## Root Cause Analysis

### Failing Hop: All Hops (Container Tooling Issue)

**Error/Behavior Observed:**
- All diagnostic tests fail because essential tools are missing from containers
- Error messages consistently show: `"curl": executable file not found in $PATH`
- Error messages also show: `"bash": executable file not found in $PATH`
- This prevents any meaningful connectivity testing from within the containers

### Likely Root Cause: Container Image Configuration

The root cause is **container image configuration**:
- The containers are built with minimal base images (likely Alpine or similar)
- These minimal images do not include `curl`, `bash`, or other standard debugging tools
- Without these tools, we cannot exec into containers to perform connectivity tests
- This prevents proper diagnosis of the actual SSE streaming issue

### Technical Details

**Container Build Issue:**
```
OCI runtime exec failed: exec failed: unable to start container process: exec: "curl": executable file not found in $PATH
OCI runtime exec failed: exec failed: unable to start container process: exec: "bash": executable file not found in $PATH
```

This affects both:
- Agent container (likely Python-based with minimal base image)
- Frontend container (likely Node.js/Next.js with minimal base image)

**Impact:**
- Cannot perform intra-cluster connectivity testing
- Cannot debug service-to-service communication
- Cannot isolate whether the SSE issue is network-related or protocol-related
- Cannot verify health endpoints are working properly

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

### Short-term Fix: Add debugging tools to containers
1. **Agent container**: Update `agent/Dockerfile` to include curl:
   ```dockerfile
   RUN apt-get update && apt-get install -y curl  # For Debian/Ubuntu
   # OR
   RUN apk add --no-cache curl  # For Alpine
   ```

2. **Frontend container**: Update `Dockerfile` to include curl:
   ```dockerfile
   RUN apt-get update && apt-get install -y curl  # For Debian/Ubuntu
   # OR
   RUN apk add --no-cache curl  # For Alpine
   ```

### Long-term Fix: Implement proper health check endpoints
Since we cannot rely on curl in production containers, implement proper health check endpoints:
1. **Agent**: Ensure `/api/health` endpoint exists and returns proper HTTP status
2. **Frontend**: Create `/api/health` endpoint for the Next.js app
3. **Kubernetes**: Use proper liveness and readiness probes in deployments

### Alternative Testing Approach
If adding curl is not desirable, create a dedicated debugging pod with curl:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: debug-pod
spec:
  containers:
  - name: debug
    image: curlimages/curl
    command: ["sleep", "3600"]
```

## Next Steps
1. Apply the short-term fix by adding curl to both containers
2. Rebuild and redeploy the containers
3. Re-run the diagnostic script to identify the actual SSE streaming issues
4. Based on those results, implement the appropriate SSE streaming fix

## Verification
The fix should be verified by:
1. Running the diagnostic script again - all hops should show PASS status
2. Confirming curl is available in both agent and frontend containers
3. Being able to exec into containers and run connectivity tests
4. Once basic connectivity is established, proceed with SSE streaming diagnosis