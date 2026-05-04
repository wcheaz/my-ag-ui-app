# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

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

## Specifications

agent-k8s-deployment/spec.md
## ADDED Requirements

### Requirement: Agent must have a Kubernetes Deployment manifest
The system SHALL provide `k8s/agent-deployment.yaml` that deploys the agent container as a Kubernetes Deployment with 1 replica, using image `localhost:32000/agent:latest` on port 8000.

#### Scenario: Agent deployment manifest is valid
- **WHEN** `microk8s kubectl apply -f k8s/agent-deployment.yaml` is executed
- **THEN** Kubernetes creates the `agent` Deployment without errors
- **AND** the deployment reaches the "Available" state

#### Scenario: Agent deployment creates one running pod
- **WHEN** the agent deployment is applied
- **THEN** exactly 1 pod with label `app: agent` is created
- **AND** the pod is in "Running" state and "Ready"

#### Scenario: Agent pod uses correct container image
- **WHEN** the agent pod is inspected
- **THEN** its container image is `localhost:32000/agent:latest`
- **AND** it exposes port 8000

### Requirement: Agent deployment must mount secrets and config via envFrom
The agent Deployment SHALL mount all keys from `my-ag-ui-app-secrets` Secret and `my-ag-ui-app-config` ConfigMap as environment variables using `envFrom`.

#### Scenario: Agent pod has secret environment variables
- **WHEN** agent deployment manifest is examined
- **THEN** it includes `envFrom` with `secretRef.name: my-ag-ui-app-secrets`
- **AND** it includes `envFrom` with `configMapRef.name: my-ag-ui-app-config`

#### Scenario: Agent pod receives required env vars at runtime
- **WHEN** an agent pod is running
- **THEN** the environment contains `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL`, `EMBEDDING_MODEL`, `LOGFIRE_TOKEN`
- **AND** the environment contains `LLM_MAX_TOKENS`, `LLM_CONTEXT_WINDOW`

### Requirement: Agent deployment must include health probes
The agent Deployment SHALL configure liveness and readiness probes targeting `GET /api/health` on port 8000, with `initialDelaySeconds: 10`, `periodSeconds: 15`, `failureThreshold: 3`, and `timeoutSeconds: 5`.

#### Scenario: Liveness probe is configured on agent deployment
- **WHEN** `k8s/agent-deployment.yaml` is examined
- **THEN** it includes a `livenessProbe` section with `httpGet` path `/api/health` and port 8000
- **AND** `initialDelaySeconds` is 10, `periodSeconds` is 15, `failureThreshold` is 3

#### Scenario: Readiness probe is configured on agent deployment
- **WHEN** `k8s/agent-deployment.yaml` is examined
- **THEN** it includes a `readinessProbe` section with `httpGet` path `/api/health` and port 8000
- **AND** `initialDelaySeconds` is 10, `periodSeconds` is 15, `failureThreshold` is 3

#### Scenario: Unhealthy agent pod is restarted
- **WHEN** an agent pod fails the liveness probe 3 consecutive times
- **THEN** Kubernetes restarts the pod automatically

### Requirement: Agent deployment must include resource limits
The agent Deployment SHALL configure memory requests of 256Mi, memory limits of 512Mi, and CPU requests/limits appropriate for a Python/ML workload.

#### Scenario: Agent resource requests and limits are set
- **WHEN** `k8s/agent-deployment.yaml` is examined
- **THEN** it includes `resources.requests.memory` of at least 256Mi
- **AND** it includes `resources.limits.memory` of at least 512Mi
- **AND** it includes `resources.requests.cpu` and `resources.limits.cpu`

### Requirement: Agent must have a Kubernetes ClusterIP Service
The system SHALL provide `k8s/agent-service.yaml` that creates a ClusterIP Service named `agent-service` in the `default` namespace, selecting pods with label `app: agent`, mapping port 8000 to targetPort 8000.

#### Scenario: Agent service manifest is valid
- **WHEN** `microk8s kubectl apply -f k8s/agent-service.yaml` is executed
- **THEN** Kubernetes creates the `agent-service` Service without errors
- **AND** the service is in the "Active" state

#### Scenario: Agent service selects agent pods
- **WHEN** the agent service manifest is examined
- **THEN** its selector matches `app: agent`
- **AND** it maps `port: 8000` to `targetPort: 8000`
- **AND** its type is `ClusterIP`

#### Scenario: Agent service is resolvable via Kubernetes DNS
- **WHEN** a frontend pod resolves `agent-service` via DNS
- **THEN** it resolves to the agent service IP
- **AND** connections to `agent-service:8000` reach the agent pod

### Requirement: Agent service MUST NOT be exposed externally
The agent service SHALL be ClusterIP-only with no ingress, NodePort, or LoadBalancer. The agent MUST only be reachable from within the cluster.

#### Scenario: Agent service has no external exposure
- **WHEN** the agent service manifest is examined
- **THEN** its type is `ClusterIP`
- **AND** there is no ingress manifest referencing `agent-service`
- **AND** no NodePort or LoadBalancer is configured

kubernetes-deployment/spec.md
## MODIFIED Requirements

### Requirement: Deployment must use environment variables and secrets
The system SHALL configure environment variables for the application using Kubernetes secrets for sensitive data and ConfigMaps for non-sensitive configuration, referencing .env.example for required variables. The frontend deployment manifest MUST include an `env` entry setting `AGENT_URL` to `http://agent-service:8000/` and MUST mount all keys from `my-ag-ui-app-secrets` Secret and `my-ag-ui-app-config` ConfigMap via `envFrom`.

#### Scenario: Environment variables are configured
- **WHEN** deployment manifest is examined
- **THEN** it includes environment variable references from secrets or ConfigMaps
- **AND** sensitive variables (API keys, tokens) use Kubernetes secrets
- **AND** non-sensitive variables use ConfigMaps or direct values

#### Scenario: AGENT_URL is set in frontend deployment
- **WHEN** `k8s/deployment.yaml` is examined
- **THEN** it includes an `env` entry with `name: AGENT_URL` and `value: "http://agent-service:8000/"`
- **AND** the value is a literal string (not derived from a ConfigMap or Secret)

#### Scenario: Frontend deployment mounts secrets via envFrom
- **WHEN** `k8s/deployment.yaml` is examined
- **THEN** it includes `envFrom` with `secretRef.name: my-ag-ui-app-secrets`
- **AND** it includes `envFrom` with `configMapRef.name: my-ag-ui-app-config`

#### Scenario: Frontend pod receives secrets at runtime
- **WHEN** a frontend pod is running
- **THEN** the environment contains `AGENT_URL` equal to `http://agent-service:8000/`
- **AND** the environment contains `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL` from the mounted Secret (keys MUST be in SCREAMING_SNAKE_CASE)

#### Scenario: .env.example is available as reference
- **WHEN** .env.example file is examined
- **THEN** it lists all required environment variables
- **THEN** it can be read by ralph-loop automation
- **AND** it provides documentation for each variable

#### Scenario: Secrets are created and applied
- **WHEN** deployment script is executed
- **THEN** Kubernetes secrets are created from provided values
- **AND** secrets are applied to the cluster before deployment
- **AND** secrets are not logged or exposed in plain text



## Design

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

## Current Task Context

## Current Task
- 0.1 Update `k8s/setup-secrets.sh` — rename all Secret keys from kebab-case to SCREAMING_SNAKE_CASE: `openai-api-key` → `OPENAI_API_KEY`, `openai-base-url` → `OPENAI_BASE_URL`, `openai-model` → `OPENAI_MODEL`, `embedding-model` → `EMBEDDING_MODEL`, `logfire-token` → `LOGFIRE_TOKEN`. Also rename ConfigMap keys: `llm-max-tokens` → `LLM_MAX_TOKENS`, `llm-context-window` → `LLM_CONTEXT_WINDOW`.
