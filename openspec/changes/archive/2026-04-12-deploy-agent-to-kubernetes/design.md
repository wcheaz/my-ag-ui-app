## Context

The application has two runtime components:

1. **Frontend** — Next.js app (`my-ag-ui-app`) serving the UI and CopilotKit runtime. Currently deployed to K8s with 3 replicas. Listens on port 3000.
2. **Backend agent** — FastAPI app (`agent`) providing the AI chat agent via the AG-UI protocol. Runs via uvicorn on port 8000. **Not deployed to K8s.**

The frontend's CopilotKit route (`src/app/api/copilotkit/route.ts`) connects to the agent at `process.env.AGENT_URL` with fallback `http://localhost:8000/`. In the K8s pod, `localhost:8000` has nothing listening, causing `ECONNREFUSED`.

**Deployment architecture**: The Kubernetes cluster runs inside a **Multipass VM** named `my-ag-ui-app-k8s` (defined in `deploy_scripts/common.sh` as `VM_NAME`). All `microk8s kubectl` commands must be prefixed with `multipass exec "$VM_NAME" --`. The image pipeline is:

1. Build Docker image on the **host** machine
2. `docker save` to tar on the host
3. `multipass transfer` the tar into the VM
4. `docker load` inside the VM
5. `docker tag` with `localhost:32000/agent:latest` inside the VM
6. `docker push localhost:32000/agent:latest` from within the VM to the microk8s registry

Manifests are also transferred via `multipass transfer` before being applied from inside the VM. This pattern is already established in `deploy_scripts/build-docker-image.sh`, `deploy_scripts/push-docker-image.sh`, and `deploy_scripts/deploy-to-k8s.sh`.

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

### D3: Reuse existing Secret and ConfigMap (with key rename)

**Decision**: Both frontend and agent deployments mount the existing `my-ag-ui-app-secrets` Secret and `my-ag-ui-app-config` ConfigMap via `envFrom`. However, the current keys use kebab-case (`openai-api-key`) which do not match the SCREAMING_SNAKE_CASE env var names the agent code expects (`OPENAI_API_KEY`). The Secret and ConfigMap keys must be renamed to SCREAMING_SNAKE_CASE before `envFrom` can work correctly.

**Rationale**: The Secret already contains the required values — `openai-api-key`, `openai-base-url`, `openai-model`, `embedding-model`, `logfire-token` — and the ConfigMap has `llm-max-tokens` and `llm-context-window`. However, when `envFrom` mounts these keys as environment variables, the variable names will be exactly the key names (e.g., `openai-api-key`). The agent code at `agent/src/rag/settings.py` reads `os.getenv("OPENAI_API_KEY")`, `os.getenv("OPENAI_MODEL")`, etc. — so kebab-case keys will not be found. Renaming the keys to `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL`, `EMBEDDING_MODEL`, `LOGFIRE_TOKEN`, `LLM_MAX_TOKENS`, and `LLM_CONTEXT_WINDOW` in both `k8s/secrets.yaml` and `k8s/setup-secrets.sh` resolves this mismatch. Both services need the same LLM credentials.

**Alternatives considered**:
- Use explicit `env` entries with `valueFrom.secretKeyRef` to map kebab-case keys to SCREAMING_SNAKE_CASE names: More verbose and harder to maintain. Each env var would need a separate mapping entry. Renaming the keys once is simpler.
- Keep kebab-case and change agent code to match: Modifying application source code is a non-goal. The env var names are already SCREAMING_SNAKE_CASE throughout the codebase (`agent/.env`, `k8s/setup-secrets.sh` reads `OPENAI_API_KEY` etc. — the script itself uses SCREAMING_SNAKE_CASE variable names but writes kebab-case keys).

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

### D8: Agent image follows existing Multipass VM transfer pipeline

**Decision**: The agent image follows the exact same build-transfer-tag-push pipeline as the frontend, orchestrated through the Multipass VM.

**Rationale**: The existing `deploy_scripts/build-docker-image.sh` pipeline is:
1. `docker build -t agent:latest ./agent` on host
2. `docker save "$IMAGE_ID" -o ./agent.tar` on host
3. `multipass transfer ./agent.tar my-ag-ui-app-k8s:/tmp/`
4. `multipass exec my-ag-ui-app-k8s -- docker load -i /tmp/agent.tar`
5. `multipass exec my-ag-ui-app-k8s -- docker tag "$VM_IMAGE_ID" localhost:32000/agent:latest`
6. `multipass exec my-ag-ui-app-k8s -- docker push localhost:32000/agent:latest`

This is the only way to get images into the microk8s registry since Docker on the host cannot directly push to `localhost:32000` (that port is only accessible inside the VM).

**Alternatives considered**:
- Building inside the VM: Possible but requires copying the entire `agent/` directory with dependencies into the VM. The host already has Docker and the source, so building on host and transferring is simpler.
- Using a shared registry accessible from host: Would require network reconfiguration. The current approach works without any infrastructure changes.

### D9: Manifests transferred via multipass transfer before apply

**Decision**: All K8s manifests (`agent-deployment.yaml`, `agent-service.yaml`, updated `deployment.yaml`) must be transferred into the VM via `multipass transfer` before applying with `microk8s kubectl`.

**Rationale**: The existing `deploy-to-k8s.sh` already does this for the frontend deployment: `multipass transfer k8s/deployment.yaml "${VM_NAME}:/home/ubuntu/deployment.yaml"`. The agent manifests must follow the same pattern. The VM does not have direct access to the host filesystem.

## Risks / Trade-offs

- **[Risk] Agent pod OOM on large LLM context** → The agent loads LlamaIndex and may use significant memory. Mitigation: Set memory limits in the deployment (`requests: 256Mi`, `limits: 512Mi`) and monitor. Adjust after observing real usage.
- **[Risk] Secrets contain stale API keys** → The Secret `my-ag-ui-app-secrets` was created previously but never actively consumed. Keys may have rotated. Mitigation: Human handoff step includes verifying secrets are current before applying.
- **[Risk] Secret key name mismatch breaks agent startup** → The existing `k8s/secrets.yaml` uses kebab-case keys (`openai-api-key`) but the agent code expects SCREAMING_SNAKE_CASE (`OPENAI_API_KEY`). If keys are not renamed before applying, `envFrom` will set the wrong env var names and the agent will crash on startup with missing API key errors. Mitigation: Task 0 (prerequisite) renames keys in `k8s/secrets.yaml` and `k8s/setup-secrets.sh` before any deployment.
- **[Risk] Single replica = single point of failure for chat** → If the agent pod dies, chat is unavailable until restart. Mitigation: Liveness probe enables automatic restart. Multi-replica scaling is a non-goal for now but requires only changing `replicas`.
- **[Risk] `localhost:32000` registry is not HA** → If the MicroK8s registry pod restarts, images must be re-pushed. Mitigation: This is the existing pattern for the frontend; no regression introduced.
- **[Trade-off] Using `envFrom` mounts all keys from Secret/ConfigMap** → Both frontend and agent receive all env vars, even if some are only relevant to one service. This is acceptable because no keys conflict and the operational simplicity outweighs the minor noise.

## Migration Plan

All `microk8s kubectl` commands go through the Multipass VM: `multipass exec my-ag-ui-app-k8s -- microk8s kubectl ...`.

1. **Prerequisites** (human handoff):
   - Rename Secret and ConfigMap keys in `k8s/secrets.yaml` and `k8s/setup-secrets.sh` from kebab-case to SCREAMING_SNAKE_CASE (e.g., `openai-api-key` → `OPENAI_API_KEY`)
   - Re-apply secrets to cluster: `multipass transfer k8s/secrets.yaml my-ag-ui-app-k8s:/home/ubuntu/secrets.yaml && multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/secrets.yaml`
   - Build agent image on host: `docker build -t agent:latest ./agent`
   - Transfer to VM and load: `docker save <IMAGE_ID> -o ./agent.tar && multipass transfer ./agent.tar my-ag-ui-app-k8s:/tmp/ && multipass exec my-ag-ui-app-k8s -- docker load -i /tmp/agent.tar`
   - Tag and push in VM: `multipass exec my-ag-ui-app-k8s -- docker tag <VM_IMAGE_ID> localhost:32000/agent:latest && multipass exec my-ag-ui-app-k8s -- docker push localhost:32000/agent:latest`
   - Verify secrets are applied: `multipass exec my-ag-ui-app-k8s -- microk8s kubectl get secret my-ag-ui-app-secrets -o yaml`
2. **Transfer and apply agent manifests**:
   - `multipass transfer k8s/agent-deployment.yaml my-ag-ui-app-k8s:/home/ubuntu/agent-deployment.yaml`
   - `multipass transfer k8s/agent-service.yaml my-ag-ui-app-k8s:/home/ubuntu/agent-service.yaml`
   - `multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/agent-deployment.yaml`
   - `multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/agent-service.yaml`
3. **Transfer and apply updated frontend**:
   - `multipass transfer k8s/deployment.yaml my-ag-ui-app-k8s:/home/ubuntu/deployment.yaml`
   - `multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/deployment.yaml`
4. **Verify**: `multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout status deployment/agent && multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout status deployment/my-ag-ui-app`
5. **E2E test**: Submit a chat prompt at `http://my-ag-ui-app.local/` and confirm a response
6. **Rollback**: `multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout undo deployment/agent` and/or `multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout undo deployment/my-ag-ui-app`

## Open Questions

None. All decisions are resolved.
