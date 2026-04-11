## Context

The application has two runtime components:

1. **Frontend** — Next.js app (`my-ag-ui-app`) serving the UI and CopilotKit runtime. Currently deployed to K8s with 3 replicas. Listens on port 3000.
2. **Backend agent** — FastAPI app (`agent`) providing the AI chat agent via the AG-UI protocol. Runs via uvicorn on port 8000. **Not deployed to K8s.**

The frontend's CopilotKit route (`src/app/api/copilotkit/route.ts`) connects to the agent at `process.env.AGENT_URL` with fallback `http://localhost:8000/`. In the K8s pod, `localhost:8000` has nothing listening, causing `ECONNREFUSED`.

Existing K8s resources:
- `k8s/deployment.yaml` — frontend only, no env vars, no secret mounts
- `k8s/service.yaml` — ClusterIP, port 80 → 3000
- `k8s/ingress.yaml` — nginx ingress for `my-ag-ui-app.local`
- `k8s/secrets.yaml` — Secret `my-ag-ui-app-secrets` + ConfigMap `my-ag-ui-app-config` (defined but never mounted)

Existing agent containerization:
- `agent/Dockerfile` — production-ready (non-root user, uv, uvicorn on port 8000)
- `docker-compose.yml` — defines both services with `AGENT_URL=http://agent:8000/`

## Goals / Non-Goals

**Goals:**
- Deploy the agent as a standalone Kubernetes Deployment with 1 replica
- Expose the agent via a ClusterIP Service at `agent-service:8000` (cluster-internal only)
- Wire the frontend deployment to reach the agent via Kubernetes DNS (`http://agent-service:8000/`)
- Mount existing secrets/configmaps into both frontend and agent pods
- Add liveness and readiness probes to the agent deployment using its existing `/api/health` endpoint

**Non-Goals:**
- Horizontal autoscaling or multi-replica agent deployment
- CI/CD pipeline for agent image builds
- Ingress or external exposure of the agent
- Network policies, service mesh, or pod security policies
- Changes to application source code
- Agent image build/push automation (manual human handoff step)

## Decisions

### D1: Agent as a separate Deployment (not a sidecar)

**Decision**: Deploy the agent as its own Deployment, not as a sidecar container in the frontend pod.

**Rationale**: The docker-compose architecture already models them as separate services. A separate Deployment allows independent scaling, rolling updates, and resource allocation. The agent has different resource characteristics (Python/ML workload vs Node.js frontend).

**Alternatives considered**:
- Sidecar in the same pod: Couples lifecycle of both services, prevents independent scaling, makes the 3-replica frontend deployment spawn 3 agent instances unnecessarily.
- Job or CronJob: Not appropriate — the agent is a long-running HTTP server.

### D2: ClusterIP Service for the agent

**Decision**: Use a `ClusterIP` Service named `agent-service` on port 8000.

**Rationale**: The agent only needs to be reachable from frontend pods within the cluster. No external traffic should reach the agent directly. Kubernetes DNS resolves `agent-service.default.svc.cluster.local` to the service, and short name `agent-service` works within the same namespace.

**Alternatives considered**:
- NodePort: Exposes agent outside the cluster — unnecessary security exposure.
- Headless Service: Not needed since we want standard load-balancing (even with 1 replica, this keeps the pattern consistent for future scaling).

### D3: Reuse existing Secret and ConfigMap

**Decision**: Both frontend and agent deployments mount the existing `my-ag-ui-app-secrets` Secret and `my-ag-ui-app-config` ConfigMap via `envFrom`.

**Rationale**: The Secret already contains `openai-api-key`, `openai-base-url`, `openai-model`, `embedding-model`, `logfire-token` — all required by the agent. The ConfigMap has `llm-max-tokens` and `llm-context-window`. Rather than create agent-specific secrets, reuse the existing ones. Both services need the same LLM credentials.

### D4: Single replica for the agent

**Decision**: Deploy exactly 1 replica of the agent.

**Rationale**: The agent is stateless per-request (no persistent connections or session affinity needed). For the initial migration, 1 replica is sufficient. Scaling can be added later without manifest redesign.

### D5: Health probes via /api/health

**Decision**: Configure liveness and readiness probes on the agent deployment hitting `GET /api/health` on port 8000.

**Rationale**: The agent already exposes `/api/health` (defined in `agent/src/main.py`), returning `{"status": "healthy"}` with HTTP 200. This is the same pattern used by the frontend's health checks.

**Probe configuration**:
- `initialDelaySeconds: 10` — gives uvicorn time to start
- `periodSeconds: 15`
- `failureThreshold: 3`
- `timeoutSeconds: 5`

### D6: AGENT_URL set as literal env var

**Decision**: Set `AGENT_URL=http://agent-service:8000/` as a plain `value` in the frontend deployment's `env` section (not derived from a ConfigMap).

**Rationale**: The service name and port are stable infrastructure details. They should not change between environments within the same cluster. If multi-environment support is needed later, this can be moved to a ConfigMap.

### D7: Agent image tag follows existing convention

**Decision**: Agent image is `localhost:32000/agent:latest`, matching the existing pattern `localhost:32000/my-ag-ui-app:latest`.

**Rationale**: The local MicroK8s registry is already enabled and the frontend image uses this registry. Consistency reduces operational confusion.

## Risks / Trade-offs

- **[Risk] Agent pod OOM on large LLM context** → The agent loads LlamaIndex and may use significant memory. Mitigation: Set memory limits in the deployment (`requests: 256Mi`, `limits: 512Mi`) and monitor. Adjust after observing real usage.
- **[Risk] Secrets contain stale API keys** → The Secret `my-ag-ui-app-secrets` was created previously but never actively consumed. Keys may have rotated. Mitigation: Human handoff step includes verifying secrets are current before applying.
- **[Risk] Single replica = single point of failure for chat** → If the agent pod dies, chat is unavailable until restart. Mitigation: Liveness probe enables automatic restart. Multi-replica scaling is a non-goal for now but requires only changing `replicas`.
- **[Risk] `localhost:32000` registry is not HA** → If the MicroK8s registry pod restarts, images must be re-pushed. Mitigation: This is the existing pattern for the frontend; no regression introduced.
- **[Trade-off] Using `envFrom` mounts all keys from Secret/ConfigMap** → Both frontend and agent receive all env vars, even if some are only relevant to one service. This is acceptable because no keys conflict and the operational simplicity outweighs the minor noise.

## Migration Plan

1. **Prerequisites** (human handoff):
   - Build and push agent image: `docker build -t localhost:32000/agent:latest ./agent && docker push localhost:32000/agent:latest`
   - Verify secrets are applied: `microk8s kubectl get secret my-ag-ui-app-secrets -o yaml`
2. **Apply agent manifests**: `microk8s kubectl apply -f k8s/agent-deployment.yaml && microk8s kubectl apply -f k8s/agent-service.yaml`
3. **Update frontend**: `microk8s kubectl apply -f k8s/deployment.yaml` (updated manifest with AGENT_URL and envFrom)
4. **Verify**: `microk8s kubectl rollout status deployment/agent && microk8s kubectl rollout status deployment/my-ag-ui-app`
5. **E2E test**: Submit a chat prompt at `http://my-ag-ui-app.local/` and confirm a response
6. **Rollback**: If agent fails, `microk8s kubectl rollout undo deployment/agent`. If frontend breaks, `microk8s kubectl rollout undo deployment/my-ag-ui-app`. The previous frontend manifest (without env vars) is the rollback state.

## Open Questions

None. All decisions are resolved.
