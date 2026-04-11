## Why

The Kubernetes deployment is incomplete: only the frontend was migrated, while the backend agent service (FastAPI/uvicorn) was left behind. This causes every chat-agent request to fail with `ECONNREFUSED` in the K8s deployment because the frontend pods have no agent to reach. The application's core feature — the conversational procurement agent — is entirely non-functional in the cluster.

## What Changes

- Rename Secret keys in `k8s/secrets.yaml` and update `k8s/setup-secrets.sh` from kebab-case to SCREAMING_SNAKE_CASE so `envFrom` mounts env vars matching what the agent code expects (e.g., `OPENAI_API_KEY` instead of `openai-api-key`)
- Create a Kubernetes Deployment manifest for the agent service (`k8s/agent-deployment.yaml`)
- Create a Kubernetes ClusterIP Service manifest for the agent (`k8s/agent-service.yaml`)
- Update the frontend deployment (`k8s/deployment.yaml`) to set the `AGENT_URL` environment variable pointing to the in-cluster agent service (`http://agent-service:8000/`)
- Update the frontend deployment to mount the existing `my-ag-ui-app-secrets` Secret and `my-ag-ui-app-config` ConfigMap via `envFrom`
- Update the agent deployment to mount the same Secret and ConfigMap via `envFrom` so it has access to `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL`, `EMBEDDING_MODEL`, `LOGFIRE_TOKEN`, `LLM_MAX_TOKENS`, and `LLM_CONTEXT_WINDOW`

## Capabilities

### New Capabilities
- `agent-k8s-deployment`: Kubernetes manifests and configuration for deploying the backend agent service as a pod with proper service discovery, health checks, and secret mounting.

### Modified Capabilities
- `kubernetes-deployment`: Frontend deployment gains `AGENT_URL` environment variable and `envFrom` references to secrets/configmaps. This is a requirement-level change because the deployment spec now MUST include environment configuration that was previously absent.

## Impact

- **Secret key names**: `k8s/secrets.yaml` and `k8s/setup-secrets.sh` must rename keys from kebab-case to SCREAMING_SNAKE_CASE (e.g., `openai-api-key` → `OPENAI_API_KEY`). This is required because `envFrom` uses the key names as env var names, and the agent code reads `os.getenv("OPENAI_API_KEY")` etc. After renaming, secrets must be re-applied to the cluster before the agent deployment will work.
- **Kubernetes manifests**: `k8s/deployment.yaml` updated; `k8s/agent-deployment.yaml` and `k8s/agent-service.yaml` created
- **Container images**: Agent image must follow the existing Multipass VM pipeline (build on host → save to tar → `multipass transfer` to VM → `docker load` in VM → tag as `localhost:32000/agent:latest` → push from within VM to microk8s registry)
- **Runtime**: Frontend pods will connect to `http://agent-service:8000/` instead of `http://localhost:8000/`
- **Secrets**: Existing `k8s/secrets.yaml` (Secret + ConfigMap) will be actively consumed by both frontend and agent deployments
- **Deploy scripts**: Agent image build/transfer/tag/push must follow the same pattern as `deploy_scripts/build-docker-image.sh` (which currently only handles the frontend)
- **No code changes**: This change is entirely infrastructure/manifest-level. No application source code (`src/`, `agent/src/`) is modified.

## Non-Goals

- Production-grade scaling or autoscaling for the agent (single replica is sufficient for initial migration)
- CI/CD pipeline changes for automated agent image builds
- New deploy scripts for the agent image (human handoff covers the manual steps following the existing pattern)
- Changes to the agent application code or its dependencies
- Changes to the ingress configuration (agent is cluster-internal only)
- Network policies or service mesh configuration
- Monitoring/alerting beyond the existing logfire instrumentation

## Human Handoff

After this change is implemented, the following manual steps are required before the chat agent works in the cluster. All `microk8s kubectl` commands must be run through the Multipass VM (`multipass exec my-ag-ui-app-k8s -- microk8s kubectl ...`).

The VM name is `my-ag-ui-app-k8s` (set by `VM_NAME` in `deploy_scripts/common.sh`).

### 1. Fix Secret key names (prerequisite)

The existing `k8s/secrets.yaml` stores keys in kebab-case (e.g., `openai-api-key`) but the agent code reads SCREAMING_SNAKE_CASE env vars (e.g., `OPENAI_API_KEY`). If Task 0 was not completed during implementation, rename the keys now:

```bash
# Edit k8s/setup-secrets.sh to use SCREAMING_SNAKE_CASE keys, then regenerate:
bash k8s/setup-secrets.sh
multipass transfer k8s/secrets.yaml my-ag-ui-app-k8s:/home/ubuntu/secrets.yaml
multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/secrets.yaml
```

### 2. Build the agent image on the host

```bash
docker build -t agent:latest ./agent
```

### 3. Transfer image to the Multipass VM

Following the same pattern as `deploy_scripts/build-docker-image.sh`:

```bash
IMAGE_ID=$(docker images agent:latest --format "{{.ID}}" | head -n1)
docker save "$IMAGE_ID" -o ./agent.tar
multipass transfer ./agent.tar my-ag-ui-app-k8s:/tmp/
multipass exec my-ag-ui-app-k8s -- docker load -i /tmp/agent.tar
```

### 4. Tag and push in the VM

```bash
VM_IMAGE_ID=$(multipass exec my-ag-ui-app-k8s -- docker images --format "{{.ID}}" | head -n1)
multipass exec my-ag-ui-app-k8s -- docker tag "$VM_IMAGE_ID" localhost:32000/agent:latest
multipass exec my-ag-ui-app-k8s -- docker push localhost:32000/agent:latest
```

### 5. Apply secrets (if not already applied)

```bash
multipass transfer k8s/secrets.yaml my-ag-ui-app-k8s:/home/ubuntu/secrets.yaml
multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/secrets.yaml
```

### 6. Transfer and apply agent manifests

```bash
multipass transfer k8s/agent-deployment.yaml my-ag-ui-app-k8s:/home/ubuntu/agent-deployment.yaml
multipass transfer k8s/agent-service.yaml my-ag-ui-app-k8s:/home/ubuntu/agent-service.yaml
multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/agent-deployment.yaml
multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/agent-service.yaml
```

### 7. Transfer and apply updated frontend deployment

```bash
multipass transfer k8s/deployment.yaml my-ag-ui-app-k8s:/home/ubuntu/deployment.yaml
multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/deployment.yaml
multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout restart deployment/my-ag-ui-app
```

### 8. Verify

```bash
multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout status deployment/agent
multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout status deployment/my-ag-ui-app
```

### 9. End-to-end test

Open `http://my-ag-ui-app.local/`, submit a chat prompt, confirm a response is received.

### 10. Rollback (if needed)

```bash
multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout undo deployment/agent
multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout undo deployment/my-ag-ui-app
```
