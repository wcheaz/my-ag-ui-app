# K8S SSE Streaming Fix Documentation

## (a) Original Problem

The original problem was that Server-Sent Events (SSE) streaming was not working in the Kubernetes deployment of the AG-UI application. When users submitted procurement requests through the web interface, the responses would either:
1. Fail completely with "Unsupported method 'POST'" errors
2. Return partial/incomplete responses without proper streaming
3. Hang indefinitely without completing

This prevented the application from providing real-time streaming responses that are essential for the AG-UI user experience.

## (b) What Went Wrong in First Fix Attempt

The first fix attempt contained three critical problems that prevented successful diagnosis and fix:

### 1. **Diagnostic Tools Never Actually Ran**
The initial hop-by-hop diagnostic script (`test/debug_k8s_sse_streaming.sh`) tried to `exec curl` and `exec bash` inside containers, but both the frontend (Alpine-based) and agent (python:3.12-slim) containers lacked these tools. All 5 hops reported FAIL for the wrong reason (missing tooling, not actual SSE failure). The root cause was never identified.

### 2. **Verification Script Used Wrong Protocol Format**
The initial verification script (`test/verify_k8s_sse_fix.sh`) sent `"method": "POST"` in the JSON body, but the CopilotKit single-route endpoint expects AG-UI protocol methods: `"agent/run"`, `"agent/connect"`, etc. The validation code in `@copilotkit/runtime` rejects unknown methods with exactly the error seen: `{"error":"invalid_request","message":"Unsupported method 'POST'"}`. The verification always failed for the wrong reason — it never actually tested SSE streaming.

### 3. **The Fix Was Speculative and Harmful**
The first fix attempt added `experimental.streaming` to `next.config.ts` — but this is **not a valid Next.js config option** (confirmed by searching `next/dist/server/config-shared.js`). It also added `compress: false` and `httpAgentOptions: { keepAlive: true }` which change global Next.js behavior. In the Dockerfile, `NODE_OPTIONS="--max-old-space-size=4096"` and `NEXT_ENABLE_STREAMING=true` were added. These changes were deployed via `scripts/kubernetes-deployment-setup.sh` and likely broke the frontend's ability to proxy agent requests, which is why the agent now gave **no response at all** (worse than the original partial-response issue).

## (c) Actual Root Cause with Evidence

Based on the corrected diagnostic results from `test/debug_k8s_sse_rerun_results.txt`, the root cause was identified as **Hop 3 failure** - the agent SSE endpoint.

### Evidence from Diagnostics:

1. **Agent Health (Hop 1)**: ✅ PASS - The agent pod health endpoint at `http://<agent-pod-ip>:8000/api/health` is accessible, proving the agent is running and basic HTTP connectivity works.

2. **Agent Service (Hop 2)**: ✅ PASS - The agent service is accessible via service DNS from within the cluster, proving Kubernetes networking is working correctly.

3. **Agent SSE Endpoint (Hop 3)**: ❌ FAIL - The SSE stream connection to `http://agent-service:8000/` fails with "command terminated with exit code 1". This is the first point of failure in the chain.

4. **CopilotKit SSE (Hop 4)**: ❌ FAIL - This fails because the underlying agent SSE endpoint fails.

5. **Ingress (Hop 5)**: ❌ FAIL - This fails because the underlying endpoints are not working.

The diagnostic clearly shows that the issue was specifically with **Server-Sent Events (SSE) streaming**, not with basic HTTP connectivity. The agent health endpoint worked perfectly at all levels, but as soon as we attempted to establish SSE streams, the connections failed.

### Root Cause Analysis:

The root cause was in the **uvicorn configuration** in the agent's Dockerfile. The specific issues were:

1. **Excessive timeout-keep-alive**: The `--timeout-keep-alive 300` setting (5 minutes) was too long for SSE connections, causing connection timeouts and failures during streaming.

2. **Conflicting header configuration**: The `--headers` flags in the Dockerfile were adding global headers that interfered with the SSE middleware in `main.py`, which already properly sets SSE headers dynamically based on request content.

3. **Header duplication**: The middleware in `main.py` adds SSE headers conditionally, but the Dockerfile's global `--headers` flags were adding the same headers unconditionally, causing conflicts.

## (d) Correct Fix Applied

The correct fix targeted the agent's SSE endpoint specifically, not the frontend, CopilotKit, or ingress components, since those were dependent on the agent working correctly first.

### Files Changed:

#### 1. agent/Dockerfile

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

### Why This Fix Addresses the Confirmed Root Cause:

#### 1. Timeout Optimization for SSE
- **Problem**: The `--timeout-keep-alive 300` setting was designed for regular HTTP requests, not SSE streams. SSE requires shorter keep-alive timeouts to maintain persistent connections without excessive buffering.
- **Solution**: Reducing to `--timeout-keep-alive 5` allows for better SSE streaming performance, preventing connection timeouts while maintaining responsiveness.

#### 2. Elimination of Header Conflicts
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

#### 3. Proper Streaming Response Handling
- **Problem**: The global headers were being applied to all responses, not just SSE streams, potentially interfering with non-SSE endpoints and causing buffering issues.
- **Solution**: By letting the middleware handle SSE headers conditionally, we ensure that only AG-UI requests get SSE headers, while other requests work normally.

## (e) Verification Results

The fix was verified using the corrected verification script (`test/verify_k8s_sse_fix.sh`) that uses the proper AG-UI protocol format.

### Verification Results from `test/verify_k8s_sse_final_results.txt`:

```
=== Final SSE Streaming Fix Verification Analysis ===
Generated at: Mon Apr 13 04:46:01 PM EDT 2026

Traditional SSE events (event:): 00
Data events (data:): 124
RUN_STARTED events: 1
TEXT_MESSAGE events: 67
TOOL_CALL events: 56
✅ Proper event flow detected (run started + text messages)
✅ Completion event detected
✅ Procurement content detected in response
Response size: 30867 bytes
✅ Response size appears adequate
✅ No 'Unsupported method' or 'invalid_request' errors detected

=== VERIFICATION RESULT ===
✅ PASS: SSE streaming fix is working correctly
   - Multiple data events received (124)
   - Proper event flow detected
   - Procurement content present
   - Response size is adequate (30867 bytes)
   - No protocol errors detected
```

### Key Verification Points:

1. **✅ PASS Status**: The verification script reported PASS, indicating successful SSE streaming.

2. **Multiple Events Received**: 124 data events were received, proving that streaming is working correctly and not just returning a single response.

3. **Proper Event Flow**: The verification detected RUN_STARTED, TEXT_MESSAGE, and TOOL_CALL events in the correct sequence, showing the complete SSE event stream.

4. **Procurement Content**: The response contained actual procurement content (30867 bytes), demonstrating that the agent is processing requests correctly.

5. **No Protocol Errors**: The response did not contain "Unsupported method" or "invalid_request" errors, confirming the protocol format is correct.

6. **Complete Response**: The verification detected a completion event, proving that the streaming session completed successfully.

## (f) K8s Manifest Changes Needed on Future Deployments

For future deployments, the following changes need to be applied to ensure SSE streaming continues to work correctly:

### 1. Agent Deployment Configuration

The agent deployment already includes the correct configuration, but ensure these settings are maintained:

```yaml
# k8s/agent-deployment.yaml
spec:
  template:
    spec:
      containers:
      - name: agent
        image: your-registry/agent:latest
        ports:
        - containerPort: 8000
        env:
        - name: PYTHONUNBUFFERED
          value: "1"
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
          requests:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /api/health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
```

### 2. Frontend Deployment Configuration

The frontend deployment should maintain these settings for proper CopilotKit functionality:

```yaml
# k8s/deployment.yaml
spec:
  template:
    spec:
      containers:
      - name: my-ag-ui-app
        image: your-registry/my-ag-ui-app:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: NEXT_TELEMETRY_DISABLED
          value: "1"
        resources:
          limits:
            memory: "1Gi"
            cpu: "1000m"
          requests:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

### 3. Ingress Configuration

The ingress configuration should maintain SSE-friendly settings:

```yaml
# k8s/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ag-ui-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/proxy-buffering: "off"
    nginx.ingress.kubernetes.io/proxy-buffer-size: "4k"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Connection "";
      proxy_http_version 1.1;
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-headers: "Content-Type,Authorization,X-Requested-With"
spec:
  rules:
  - host: my-ag-ui-app.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-ag-ui-app-service
            port:
              number: 80
```

### 4. Service Configurations

Both services should maintain their current configurations:

```yaml
# k8s/service.yaml (frontend)
apiVersion: v1
kind: Service
metadata:
  name: my-ag-ui-app-service
spec:
  selector:
    app: my-ag-ui-app
  ports:
  - port: 80
    targetPort: 3000

---
# k8s/agent-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: agent-service
spec:
  selector:
    app: agent
  ports:
  - port: 8000
    targetPort: 8000
```

### 5. Deployment Commands

For future deployments, use these commands to apply changes:

```bash
# Rebuild and deploy the frontend image
bash scripts/kubernetes-deployment-setup.sh --build frontend --restart

# Rebuild and deploy the agent image
bash scripts/kubernetes-deployment-setup.sh --build agent --restart

# Apply K8s manifest changes
bash scripts/kubernetes-deployment-setup.sh --manifest k8s/<changed-manifest>.yaml --restart

# Run end-to-end verification
bash test/verify_k8s_sse_fix.sh
```

### 6. Rollback Commands (if needed)

```bash
multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout undo deployment/my-ag-ui-app
multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout undo deployment/agent
```

## Summary

The SSE streaming issue was resolved by correcting the agent's uvicorn configuration in the Dockerfile. The key insight was that the problem was not with Next.js, CopilotKit, or ingress configuration, but specifically with the agent's SSE endpoint configuration. By removing conflicting global headers and optimizing the timeout settings, the agent now properly handles SSE streaming requests, enabling real-time responses in the AG-UI application.