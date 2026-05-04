## Why

The agent's SSE (Server-Sent Events) streaming response is broken in the Kubernetes deployment. When a user submits a procurement request at `http://my-ag-ui-app.local/`, the agent acknowledges the request and begins processing, but the response stream stops prematurely — no procurement code is returned. The same request works correctly in local development (`npm run start` + agent on `localhost:8000`), where the agent produces a complete response with full analysis and procurement code. A previous fix attempt added NGINX ingress SSE annotations to `k8s/ingress.yaml` but the issue persists.

## What Changes

- Create a diagnostic script that tests each hop in the SSE streaming chain (agent pod → agent service → frontend pod → NGINX ingress → browser) to isolate the exact failure point
- Diagnose why the agent's streaming response is truncated or lost in the K8s deployment despite the NGINX SSE annotations being in place
- Implement the fix once the root cause is identified (which may involve: CopilotKit runtime SSE proxy configuration, Next.js API route streaming settings, NGINX ingress configuration refinement, agent container tuning, or K8s service/deployment timeout settings)
- Create a verification test that confirms end-to-end SSE streaming works in the K8s deployment by submitting a real procurement request and validating a complete response

## Capabilities

### New Capabilities
- `sse-streaming-debug`: Diagnostic capability for identifying and fixing SSE streaming failures in the Kubernetes deployment. Covers scripted probing of each hop in the SSE chain, root cause identification, fix implementation, and end-to-end verification.

### Modified Capabilities
- `ingress-setup`: Ingress configuration may need additional or corrected annotations for SSE support beyond the annotations already added (proxy-buffering, proxy-read-timeout, etc. may be insufficient or incorrectly applied).
- `agent-k8s-deployment`: Agent deployment may need resource limit adjustments, environment variable additions, or uvicorn configuration changes to support long-running SSE connections.

## Impact

- **K8s manifests**: `k8s/ingress.yaml`, `k8s/agent-deployment.yaml`, and/or `k8s/deployment.yaml` may be modified
- **Application code**: `src/app/api/copilotkit/route.ts` (CopilotKit runtime configuration) and/or `agent/src/main.py` (uvicorn settings) may need changes for streaming support
- **Dependencies**: Possible addition of streaming-related configuration to Next.js or uvicorn
- **No database or schema changes**: This is a connectivity/streaming configuration issue
- **No breaking changes**: Fixes are additive — no existing functionality is removed

## Non-Goals

- Changes to the agent's business logic or disambiguation workflow
- Performance optimization of the agent's LLM calls
- CI/CD pipeline changes
- New deploy scripts (existing pipeline is sufficient)
- Changes to the local development configuration (it already works)
- Production scaling or autoscaling
- Network policies or service mesh

## Human Handoff

After the fix is implemented and verified in code, the following manual steps are required to deploy to the cluster:

1. Rebuild and push the affected container images (agent and/or frontend) following the existing Multipass VM pipeline
2. Apply updated K8s manifests via `multipass transfer` + `microk8s kubectl apply`
3. Verify the fix by accessing `http://my-ag-ui-app.local/` and submitting a procurement request
4. Check ingress controller logs for any remaining SSE-related errors
