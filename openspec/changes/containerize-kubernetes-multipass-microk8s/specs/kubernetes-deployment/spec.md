## ADDED Requirements

### Requirement: System must provide Kubernetes deployment manifest
The system SHALL provide a deployment.yaml manifest that defines how the application container is deployed in Kubernetes, including replicas, resource limits, and health checks.

#### Scenario: Deployment manifest is valid
- **WHEN** `microk8s kubectl apply -f deployment.yaml` is executed
- **THEN** Kubernetes creates the deployment without errors
- **AND** the deployment is in the "Available" state

#### Scenario: Deployment creates correct number of replicas
- **WHEN** deployment is applied
- **THEN** it creates the specified number of replica pods
- **AND** all pods are running and ready

### Requirement: Deployment must include resource limits
The system SHALL configure CPU and memory requests and limits for the deployment to prevent resource exhaustion and ensure fair resource allocation.

#### Scenario: Resource limits are set
- **WHEN** deployment manifest is examined
- **THEN** it includes `resources.requests.cpu` and `resources.requests.memory`
- **AND** it includes `resources.limits.cpu` and `resources.limits.memory`

#### Scenario: Pods respect resource limits
- **WHEN** pods are running
- **THEN** they do not exceed the configured CPU and memory limits
- **AND** Kubernetes enforces the limits

### Requirement: Deployment must include health checks
The system SHALL configure liveness and readiness probes to ensure Kubernetes can detect and restart unhealthy pods, and only route traffic to ready pods.

#### Scenario: Liveness probe is configured
- **WHEN** deployment manifest is examined
- **THEN** it includes a `livenessProbe` section
- **AND** the probe checks the `/health` endpoint
- **AND** it has appropriate failure thresholds and intervals

#### Scenario: Readiness probe is configured
- **WHEN** deployment manifest is examined
- **THEN** it includes a `readinessProbe` section
- **AND** the probe checks the `/health` endpoint
- **AND** it has appropriate failure thresholds and intervals

#### Scenario: Unhealthy pods are restarted
- **WHEN** a pod becomes unhealthy (fails liveness probe)
- **THEN** Kubernetes restarts the pod automatically
- **AND** the pod returns to a healthy state

### Requirement: System must provide Kubernetes service manifest
The system SHALL provide a service.yaml manifest that defines how the application is exposed within the cluster, including port configuration and selector.

#### Scenario: Service manifest is valid
- **WHEN** `microk8s kubectl apply -f service.yaml` is executed
- **THEN** Kubernetes creates the service without errors
- **AND** the service is in the "Active" state

#### Scenario: Service routes traffic to pods
- **WHEN** traffic is sent to the service
- **THEN** it is correctly routed to the application pods
- **AND** the application responds to requests

### Requirement: Service must use correct port configuration
The system SHALL configure the service to listen on port 80 (for ingress) and forward to port 3000 (application port).

#### Scenario: Service exposes correct ports
- **WHEN** service manifest is examined
- **THEN** it specifies `port: 80` (service port)
- **AND** it specifies `targetPort: 3000` (container port)

#### Scenario: Service accepts connections on configured port
- **WHEN** connections are made to the service on port 80
- **THEN** they are forwarded to the application on port 3000
- **AND** the application responds correctly

### Requirement: System must provide Kubernetes ingress manifest
The system SHALL provide an ingress.yaml manifest that defines how the application is exposed externally, including host rules and path routing.

#### Scenario: Ingress manifest is valid
- **WHEN** `microk8s kubectl apply -f ingress.yaml` is executed
- **THEN** Kubernetes creates the ingress without errors
- **AND** the ingress is in the "Ready" state

#### Scenario: Ingress exposes application externally
- **WHEN** ingress is configured
- **THEN** the application is accessible from outside the cluster
- **AND** HTTP requests are routed to the service

### Requirement: Ingress must use correct routing configuration
The system SHALL configure the ingress to route traffic from the host to the application service, with appropriate path rules.

#### Scenario: Ingress routes to correct service
- **WHEN** ingress manifest is examined
- **THEN** it specifies the correct service name
- **AND** it specifies the correct service port (80)

#### Scenario: Ingress handles path routing
- **WHEN** requests are made to the ingress host
- **THEN** they are routed to the application service
- **AND** the application receives the requests correctly

### Requirement: System must use microk8s as Kubernetes distribution
The system SHALL use microk8s as the Kubernetes distribution, configured with appropriate add-ons for the application.

#### Scenario: Microk8s is installed and running
- **WHEN** deployment script is executed
- **THEN** microk8s is installed in the VM
- **AND** microk8s is in the "Ready" state
- **AND** required add-ons (dns, storage, ingress) are enabled

#### Scenario: Microk8s add-ons are enabled
- **WHEN** `microk8s status` is checked
- **THEN** dns add-on is enabled
- **AND** storage add-on is enabled
- **AND** ingress add-on is enabled

### Requirement: System must handle container image deployment
The system SHALL build the container image and deploy it to the Kubernetes cluster, either using a local registry or loading the image directly into microk8s.

#### Scenario: Container image is built
- **WHEN** deployment script is executed
- **THEN** the Docker image is built successfully
- **AND** the image is tagged appropriately

#### Scenario: Container image is available to cluster
- **WHEN** deployment is applied
- **THEN** the Kubernetes cluster can pull the container image
- **AND** the pods start with the correct image

### Requirement: System must provide deployment verification
The system SHALL include verification steps to ensure the deployment is successful, including pod status checks and application access tests.

#### Scenario: Deployment status is verified
- **WHEN** deployment is complete
- **THEN** all pods are in the "Running" state
- **AND** all pods are "Ready"
- **AND** the deployment is "Available"

#### Scenario: Application access is verified
- **WHEN** application is accessed via ingress
- **THEN** it responds with HTTP 200 status
- **AND** the application content is displayed correctly
