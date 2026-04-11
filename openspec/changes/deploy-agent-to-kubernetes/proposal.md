## Why

The Kubernetes deployment is incomplete: only the frontend was migrated, while the backend agent service (FastAPI/uvicorn) was left behind. This causes every chat-agent request to fail with `ECONNREFUSED` in the K8s deployment because the frontend pods have no agent to reach. The application's core feature — the conversational procurement agent — is entirely non-functional in the cluster.

## What Changes

- Create a Kubernetes Deployment manifest for the agent service (`k8s/agent-deployment.yaml`)
- Create a Kubernetes ClusterIP Service manifest for the agent (`k8s/agent-service.yaml`)
- Update the frontend deployment (`k8s/deployment.yaml`) to set the `AGENT_URL` environment variable pointing to the in-cluster agent service (`http://agent-service:8000/`)
- Update the frontend deployment to mount the existing `my-ag-ui-app-secrets` Secret and `my-ag-ui-app-config` ConfigMap via `envFrom`
- Update the agent deployment to mount the same Secret and ConfigMap via `envFrom` so it has access to `openai-api-key`, `openai-base-url`, `openai-model`, `embedding-model`, `logfire-token`, `llm-max-tokens`, and `llm-context-window`

## Capabilities

### New Capabilities
- `agent-k8s-deployment`: Kubernetes manifests and configuration for deploying the backend agent service as a pod with proper service discovery, health checks, and secret mounting.

### Modified Capabilities
- `kubernetes-deployment`: Frontend deployment gains `AGENT_URL` environment variable and `envFrom` references to secrets/configmaps. This is a requirement-level change because the deployment spec now MUST include environment configuration that was previously absent.

## Impact

- **Kubernetes manifests**: `k8s/deployment.yaml` updated; `k8s/agent-deployment.yaml` and `k8s/agent-service.yaml` created
- **Container images**: Agent image must be built and pushed to the local registry at `localhost:32000/agent:latest`
- **Runtime**: Frontend pods will connect to `http://agent-service:8000/` instead of `http://localhost:8000/`
- **Secrets**: Existing `k8s/secrets.yaml` (Secret + ConfigMap) will be actively consumed by both frontend and agent deployments
- **No code changes**: This change is entirely infrastructure/manifest-level. No application source code (`src/`, `agent/src/`) is modified.

## Non-Goals

- Production-grade scaling or autoscaling for the agent (single replica is sufficient for initial migration)
- CI/CD pipeline changes for automated agent image builds
- Changes to the agent application code or its dependencies
- Changes to the ingress configuration (agent is cluster-internal only)
- Network policies or service mesh configuration
- Monitoring/alerting beyond the existing logfire instrumentation

## Human Handoff

After this change is implemented, the following manual steps are required before the chat agent works in the cluster:

1. **Build and push the agent image**: `docker build -t localhost:32000/agent:latest ./agent && docker push localhost:32000/agent:latest` (or the equivalent via the project's deploy scripts)
2. **Apply secrets** (if not already applied): `microk8s kubectl apply -f k8s/secrets.yaml`
3. **Apply new manifests**: `microk8s kubectl apply -f k8s/agent-deployment.yaml && microk8s kubectl apply -f k8s/agent-service.yaml`
4. **Rollout frontend**: `microk8s kubectl rollout restart deployment/my-ag-ui-app` to pick up the new `AGENT_URL` env var
5. **End-to-end verification**: Open `http://my-ag-ui-app.local/`, submit a chat prompt, confirm a response is received
