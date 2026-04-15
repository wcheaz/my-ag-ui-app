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
