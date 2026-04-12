# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

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

## Specifications

agent-k8s-deployment/spec.md
## MODIFIED Requirements

### Requirement: Agent deployment must support long-running SSE connections
The agent Deployment SHALL be configured with uvicorn settings appropriate for SSE streaming, including sufficient timeout values and keep-alive configuration. The resource limits SHALL accommodate the memory requirements of LLM processing during streaming.

#### Scenario: Agent uvicorn allows long-running connections
- **WHEN** the agent container starts
- **THEN** uvicorn is configured with appropriate timeout settings for SSE
- **AND** the uvicorn process does not kill idle connections prematurely

#### Scenario: Agent pod has sufficient memory for streaming
- **WHEN** the agent processes a procurement request
- **THEN** the pod does not exceed its memory limit
- **AND** no OOMKilled events appear in pod status
- **AND** `kubectl describe pod <agent-pod>` shows no memory-related restarts

#### Scenario: Agent container logs show complete request processing
- **WHEN** a procurement request is submitted to the K8s deployment
- **THEN** agent pod logs show the request being received
- **AND** agent pod logs show the full processing pipeline (rules loaded, components clarified, code generated)
- **AND** agent pod logs show the response being sent (not interrupted)

ingress-setup/spec.md
## MODIFIED Requirements

### Requirement: Ingress must support SSE streaming without buffering or truncation
The ingress SHALL be configured with NGINX annotations that disable response buffering, disable request buffering, extend read and send timeouts to 3600 seconds, and set the connection proxy header to keep-alive. These annotations MUST be applied correctly and the NGINX ingress controller MUST reload the configuration after changes.

#### Scenario: Ingress SSE annotations are present and correct
- **WHEN** `k8s/ingress.yaml` is examined
- **THEN** it includes `nginx.ingress.kubernetes.io/proxy-buffering: "off"`
- **AND** it includes `nginx.ingress.kubernetes.io/proxy-request-buffering: "off"`
- **AND** it includes `nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"`
- **AND** it includes `nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"`
- **AND** it includes `nginx.ingress.kubernetes.io/connection-proxy-header: "keep-alive"`

#### Scenario: Ingress does not buffer SSE responses
- **WHEN** SSE events are streamed from the frontend through the ingress
- **THEN** each event arrives at the client immediately (not batched)
- **AND** no events are lost due to buffering

#### Scenario: Ingress does not timeout during long agent processing
- **WHEN** the agent takes more than 60 seconds to produce a response
- **THEN** the ingress connection remains open
- **AND** the SSE stream continues without interruption

#### Scenario: Ingress annotations are verified as active on the cluster
- **WHEN** `multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe ingress my-ag-ui-app-ingress` is executed
- **THEN** all SSE-related annotations appear in the output
- **AND** the ingress shows the updated configuration

sse-streaming-debug/spec.md
## ADDED Requirements

### Requirement: SSE streaming MUST work end-to-end through the Kubernetes deployment
The system SHALL ensure that Server-Sent Events from the agent reach the browser without truncation, buffering, or timeout when accessed through the Kubernetes deployment at `http://my-ag-ui-app.local/`. The complete agent response (including procurement code and justification) MUST be delivered to the user.

#### Scenario: Agent streams complete response through Kubernetes
- **WHEN** a user submits a procurement material description at `http://my-ag-ui-app.local/`
- **THEN** the agent acknowledges the request
- **AND** the agent processes the request with full analysis
- **AND** the agent streams the complete response including procurement code and justification
- **AND** the browser receives all SSE events without truncation

#### Scenario: SSE response matches local development behavior
- **WHEN** the same procurement request is submitted in both local dev and Kubernetes
- **THEN** the Kubernetes response contains the same procurement code as the local response
- **AND** both responses include complete analysis and justification

### Requirement: System MUST provide diagnostic script for SSE chain verification
The system SHALL provide a script (`test/debug_k8s_sse_streaming.sh`) that tests SSE connectivity at each hop in the chain: agent pod health, agent service SSE, frontend-to-agent proxy, and ingress. The script MUST produce a report identifying which hop (if any) fails.

#### Scenario: Diagnostic script tests agent pod health
- **WHEN** `test/debug_k8s_sse_streaming.sh` is executed
- **THEN** it tests `GET /api/health` on the agent pod IP directly
- **AND** reports success or failure with HTTP status code

#### Scenario: Diagnostic script tests agent service SSE
- **WHEN** `test/debug_k8s_sse_streaming.sh` is executed
- **THEN** it tests SSE connectivity to `agent-service:8000` from within a frontend pod
- **AND** reports whether SSE events are received

#### Scenario: Diagnostic script tests CopilotKit proxy
- **WHEN** `test/debug_k8s_sse_streaming.sh` is executed
- **THEN** it tests `POST /api/copilotkit` on the frontend pod
- **AND** reports whether the CopilotKit runtime proxies SSE events correctly

#### Scenario: Diagnostic script produces a summary report
- **WHEN** `test/debug_k8s_sse_streaming.sh` completes all hops
- **THEN** it outputs a summary table showing pass/fail for each hop
- **AND** it identifies the specific hop where SSE streaming breaks (if any)

### Requirement: System MUST provide verification test for SSE streaming fix
The system SHALL provide a test (`test/verify_k8s_sse_fix.sh`) that submits a real procurement request to the Kubernetes deployment and validates the response contains a complete procurement code.

#### Scenario: Verification test confirms complete response
- **WHEN** `test/verify_k8s_sse_fix.sh` is executed
- **THEN** it submits a test procurement request to `http://my-ag-ui-app.local/`
- **AND** it validates the response contains SSE events
- **AND** it validates the response is not truncated (ends with a terminal event)
- **AND** it exits with code 0 on success

#### Scenario: Verification test detects truncated response
- **WHEN** the agent response is truncated or missing in Kubernetes
- **THEN** `test/verify_k8s_sse_fix.sh` exits with non-zero code
- **AND** it reports which validation failed



## Design

## Context

The application has two components deployed to Kubernetes:

1. **Frontend** — Next.js app (`my-ag-ui-app`) with 3 replicas on port 3000. The CopilotKit runtime at `src/app/api/copilotkit/route.ts` uses `HttpAgent` from `@ag-ui/client` to proxy agent requests.
2. **Agent** — FastAPI app (`agent`) with 1 replica on port 8000. Uses PydanticAI's AG-UI protocol for SSE streaming.

In K8s, the SSE request path is:

```
Browser → NGINX Ingress → Frontend Service (:80→:3000) → CopilotKit Route (/api/copilotkit)
  → HttpAgent → Agent Service (:8000) → Agent Pod → SSE stream back through same chain
```

In local dev, the path is:

```
Browser → Next.js dev server (:3000) → CopilotKit Route → HttpAgent → Agent (:8000) → SSE stream back
```

The key difference: in K8s, the browser connection passes through NGINX Ingress, and the CopilotKit runtime proxies SSE through a Next.js API route running inside a container.

**Previous fix attempt**: Added NGINX ingress annotations for SSE support (`proxy-buffering: off`, `proxy-read-timeout: 3600`, etc.) in `k8s/ingress.yaml`. The issue persists.

**Agent container**: Runs uvicorn on port 8000 with default settings. No explicit streaming or timeout configuration.

**Frontend container**: Next.js standalone server. No custom server configuration for SSE or long-lived connections.

## Goals / Non-Goals

**Goals:**
- Identify the exact hop where SSE streaming breaks in the K8s deployment
- Fix the streaming issue so the K8s deployment produces complete agent responses identical to local dev
- Verify the fix works end-to-end with a real procurement request

**Non-Goals:**
- Optimizing agent LLM response time
- Changes to agent business logic or disambiguation workflow
- CI/CD pipeline modifications
- Local development configuration changes
- Autoscaling or production hardening

## Decisions

### D1: Diagnostic approach — probe each hop independently

**Decision**: Create a shell script that tests SSE connectivity at each hop in the chain, starting from inside the cluster and working outward.

**Rationale**: The failure could be at any point in the chain. By testing each hop independently (agent pod directly, agent service, frontend-to-agent proxy, ingress), we can pinpoint the exact failure point without guessing.

**Diagnostic hops to test**:
1. **Agent pod health**: `curl http://<agent-pod-ip>:8000/api/health` from within a frontend pod
2. **Agent SSE endpoint directly**: `curl -N -H "Accept: text/event-stream" http://agent-service:8000/` from within a frontend pod
3. **CopilotKit proxy**: `curl -N -X POST http://localhost:3000/api/copilotkit` from within a frontend pod
4. **Ingress**: `curl -N http://my-ag-ui-app.local/api/copilotkit` from the host

**Alternatives considered**:
- Guess and fix based on the NGINX hypothesis alone: Already tried and failed. The issue may be upstream.
- Add debug logging to the agent code: Useful but slower and requires rebuilding the agent image.

### D2: Investigation scope includes CopilotKit runtime proxy behavior

**Decision**: Investigate whether the `@ag-ui/client` `HttpAgent` or the CopilotKit runtime's `copilotRuntimeNextJSAppRouterEndpoint` is buffering or misconfiguring the SSE proxy between frontend and agent.

**Rationale**: The CopilotKit route (`src/app/api/copilotkit/route.ts`) uses `handleRequest(req)` which returns a `NextResponse`. In local dev, Next.js handles this differently than in a containerized standalone production build. The standalone Next.js server may have different default buffering behavior. Additionally, the `@ag-ui/client` `HttpAgent` internally makes HTTP requests to the agent — if it doesn't handle SSE correctly, the stream breaks.

**Alternatives considered**:
- Assume the issue is purely NGINX: Already disproven by the failed fix attempt.
- Assume the issue is the agent container: The agent health check passes and the agent code hasn't changed between local and K8s.

### D3: Investigation scope includes Next.js standalone server streaming behavior

**Decision**: Investigate whether the Next.js standalone server (used in the Docker container) handles SSE responses differently than the Next.js dev server.

**Rationale**: The Dockerfile uses `next build` producing a standalone output. The standalone server (`server.js` from `.next/standalone`) may not propagate SSE headers or flush events the same way as the dev server. This is a known issue with Next.js standalone mode and streaming.

### D4: Agent uvicorn configuration may need tuning

**Decision**: Check whether uvicorn's default settings (worker count, timeout, keep-alive) are appropriate for long-running SSE connections in a container.

**Rationale**: The agent Dockerfile runs `uvicorn src.main:app --host 0.0.0.0 --port 8000` with no additional flags. Default uvicorn timeout is 0 (no timeout for HTTP), but the ASGI framework or the PydanticAI AG-UI implementation may have its own timeouts.

### D5: Fix will be minimal and targeted

**Decision**: Once the root cause is identified, implement the smallest possible fix rather than a broad refactoring.

**Rationale**: The streaming works locally, so the agent code and CopilotKit configuration are fundamentally correct. The fix should address only the K8s-specific behavioral difference.

## Risks / Trade-offs

- **[Risk] Root cause may require changes to multiple layers** → If the issue spans both Next.js standalone behavior and NGINX configuration, the fix will touch multiple files. Mitigation: Each fix is independently verifiable.
- **[Risk] CopilotKit library may have a known SSE bug** → If the `@ag-ui/client` or `@copilotkit/runtime` has a streaming bug in production mode, the fix may require a library upgrade or workaround. Mitigation: Check CopilotKit GitHub issues and changelogs.
- **[Risk] Next.js standalone mode may not support SSE proxy correctly** → If Next.js standalone server buffers all responses, the fix may require switching to a custom server or adding middleware. Mitigation: Research Next.js streaming support in standalone mode.
- **[Trade-off] Diagnostic script adds no permanent production value** → The script is throwaway but necessary to avoid blind guessing. It will be placed in `test/` per project conventions.
- **[Risk] Agent may be running out of memory during streaming** → The agent deployment has 2Gi memory limit. LLM processing with LlamaIndex + embeddings may exceed this during streaming. Mitigation: Check agent pod memory usage and OOM events during diagnosis.

## Open Questions

None. All investigation paths are defined. The root cause will be determined by the diagnostic tasks.

## Current Task Context

## Current Task
- 1.1 Collect current cluster state — create script `test/check_k8s_cluster_state.sh` that runs through `multipass exec my-ag-ui-app-k8s` and captures: (a) `microk8s kubectl get pods -o wide` for all pods, (b) `microk8s kubectl describe deployment agent` and `microk8s kubectl describe deployment my-ag-ui-app`, (c) `microk8s kubectl get ingress -o yaml` to verify SSE annotations are present, (d) `microk8s kubectl logs <agent-pod> --tail=50` for recent agent logs, (e) `microk8s kubectl logs -n ingress <ingress-controller-pod> --tail=50` for ingress controller logs, (f) `microk8s kubectl describe pod <agent-pod>` to check for OOMKilled or restart events. Output all results to a single report.
