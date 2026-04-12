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
