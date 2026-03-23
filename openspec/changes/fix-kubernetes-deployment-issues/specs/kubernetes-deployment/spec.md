# Kubernetes Deployment

## Purpose

Capability for deploying application containers to Kubernetes using microk8s, including deployment manifests, services, and configuration management. Supports both registry-pulled and locally imported containerd images.

## MODIFIED Requirements

### Requirement: System must provide Kubernetes deployment manifest
The system SHALL provide a deployment.yaml manifest that defines how application container is deployed in Kubernetes, including replicas, resource limits, health checks, and image pull policy.

#### Scenario: Deployment manifest is valid
- **WHEN** `microk8s kubectl apply -f deployment.yaml` is executed
- **THEN** Kubernetes creates deployment without errors
- **AND** deployment is in "Available" state

#### Scenario: Deployment creates correct number of replicas
- **WHEN** deployment is applied
- **THEN** it creates specified number of replica pods
- **AND** all pods are running and ready

#### Scenario: Deployment uses correct image pull policy
- **WHEN** deployment manifest is examined
- **THEN** it includes `imagePullPolicy: Never` for locally imported images
- **AND** it prevents Kubernetes from attempting to pull from external registries
- **AND** it allows Kubernetes to use images already available in containerd

### Requirement: Deployment must include resource limits
The system SHALL configure CPU and memory requests and limits for deployment to prevent resource exhaustion and ensure fair resource allocation.

#### Scenario: Resource limits are set
- **WHEN** deployment manifest is examined
- **THEN** it includes `resources.requests.cpu` and `resources.requests.memory`
- **AND** it includes `resources.limits.cpu` and `resources.limits.memory`

#### Scenario: Pods respect resource limits
- **WHEN** pods are running
- **THEN** they do not exceed configured CPU and memory limits
- **AND** Kubernetes enforces limits

### Requirement: Deployment must include health checks
The system SHALL configure liveness and readiness probes to ensure Kubernetes can detect and restart unhealthy pods, and only route traffic to ready pods.

#### Scenario: Liveness probe is configured
- **WHEN** deployment manifest is examined
- **THEN** it includes a `livenessProbe` section
- **AND** probe checks `/health` endpoint
- **AND** it has appropriate failure thresholds and intervals

#### Scenario: Readiness probe is configured
- **WHEN** deployment manifest is examined
- **THEN** it includes a `readinessProbe` section
- **AND** probe checks `/health` endpoint
- **AND** it has appropriate failure thresholds and intervals

#### Scenario: Unhealthy pods are restarted
- **WHEN** a pod becomes unhealthy (fails liveness probe)
- **THEN** Kubernetes restarts pod automatically
- **AND** pod returns to a healthy state

### Requirement: Deployment must use environment variables and secrets
The system SHALL configure environment variables for application using Kubernetes secrets for sensitive data and ConfigMaps for non-sensitive configuration, referencing .env.example for required variables.

#### Scenario: Environment variables are configured
- **WHEN** deployment manifest is examined
- **THEN** it includes environment variable references from secrets or ConfigMaps
- **AND** sensitive variables (API keys, tokens) use Kubernetes secrets
- **AND** non-sensitive variables use ConfigMaps or direct values

#### Scenario: .env.example is available as reference
- **WHEN** .env.example file is examined
- **THEN** it lists all required environment variables
- **THEN** it can be read by ralph-loop automation
- **AND** it provides documentation for each variable

#### Scenario: Secrets are created and applied
- **WHEN** deployment script is executed
- **THEN** Kubernetes secrets are created from provided values
- **AND** secrets are applied to cluster before deployment
- **AND** secrets are not logged or exposed in plain text

### Requirement: System must provide Kubernetes service manifest
The system SHALL provide a service.yaml manifest that defines how application is exposed within the cluster, including port configuration and selector.

#### Scenario: Service manifest is valid
- **WHEN** `microk8s kubectl apply -f service.yaml` is executed
- **THEN** Kubernetes creates service without errors
- **AND** service is in "Active" state

#### Scenario: Service routes traffic to pods
- **WHEN** traffic is sent to service
- **THEN** it is correctly routed to application pods
- **AND** application responds to requests

### Requirement: Service must use correct port configuration
The system SHALL configure service to listen on port 80 (for ingress) and forward to port 3000 (application port).

#### Scenario: Service exposes correct ports
- **WHEN** service manifest is examined
- **THEN** it specifies `port: 80` (service port)
- **AND** it specifies `targetPort: 3000` (container port)

#### Scenario: Service accepts connections on configured port
- **WHEN** connections are made to service on port 80
- **THEN** they are forwarded to application on port 3000
- **AND** application responds correctly

### Requirement: System must provide Kubernetes ingress manifest
The system SHALL provide an ingress.yaml manifest that defines how application is exposed externally, including host rules and path routing.

#### Scenario: Ingress manifest is valid
- **WHEN** `microk8s kubectl apply -f ingress.yaml` is executed
- **THEN** Kubernetes creates ingress without errors
- **AND** ingress is in "Ready" state

#### Scenario: Ingress exposes application externally
- **WHEN** ingress is configured
- **THEN** application is accessible from outside cluster
- **AND** HTTP requests are routed to service

### Requirement: Ingress must use correct routing configuration
The system SHALL configure ingress to route traffic from host to application service, with appropriate path rules.

#### Scenario: Ingress routes to correct service
- **WHEN** ingress manifest is examined
- **THEN** it specifies correct service name
- **AND** it specifies correct service port (80)

#### Scenario: Ingress handles path routing
- **WHEN** requests are made to ingress host
- **THEN** they are routed to application service
- **AND** application receives the requests correctly

### Requirement: System must use microk8s as Kubernetes distribution
The system SHALL use microk8s as the Kubernetes distribution, configured with appropriate add-ons for application.

#### Scenario: Microk8s is installed and running
- **WHEN** deployment script is executed
- **THEN** microk8s is installed in VM
- **AND** microk8s is in "Ready" state
- **AND** required add-ons (dns, storage, ingress) are enabled

#### Scenario: Microk8s add-ons are enabled
- **WHEN** `microk8s status` is checked
- **THEN** dns add-on is enabled
- **AND** storage add-on is enabled
- **AND** ingress add-on is enabled

### Requirement: System must handle container image deployment
The system SHALL build container image and deploy it to Kubernetes cluster using containerd for microk8s deployments, either importing locally built images or pulling from a registry.

#### Scenario: Container image is built
- **WHEN** deployment script is executed
- **THEN** Docker image is built successfully
- **AND** image is tagged appropriately

#### Scenario: Container image is imported into containerd for microk8s
- **WHEN** deployment is applied to microk8s cluster
- **AND** imagePullPolicy is set to Never
- **THEN** Kubernetes cluster uses image imported into containerd
- **AND** pods start with the locally imported image
- **AND** no attempt is made to pull from external registry

#### Scenario: Container image is available to cluster
- **WHEN** deployment is applied
- **THEN** Kubernetes cluster can access container image from containerd
- **AND** pods start with the correct image
- **AND** pods do not enter ImagePullBackOff state

### Requirement: System must provide deployment verification
The system SHALL include verification steps to ensure deployment is successful, including pod status checks, image availability verification in containerd, and application access tests.

#### Scenario: Deployment status is verified
- **WHEN** deployment is complete
- **THEN** all pods are in "Running" state
- **AND** all pods are "Ready"
- **AND** deployment is "Available"

#### Scenario: Image availability in containerd is verified
- **WHEN** deployment is initiated
- **THEN** script SHALL verify image exists in containerd namespace
- **AND** script SHALL confirm image tag matches deployment manifest
- **AND** script SHALL log image availability before attempting deployment

#### Scenario: Application access is verified
- **WHEN** application is accessed via ingress
- **THEN** it responds with HTTP 200 status
- **AND** application content is displayed correctly
