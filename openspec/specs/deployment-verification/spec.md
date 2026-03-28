## ADDED Requirements

### Requirement: Kubernetes secrets YAML is validated before application
The setup-k8s-secrets.sh script SHALL validate the generated secrets.yaml file using kubectl apply --dry-run=server before attempting to apply it to the cluster.

#### Scenario: Secrets validation passes with valid YAML
- **WHEN** secrets.yaml is generated with valid Kubernetes configuration
- **THEN** kubectl apply --dry-run=server succeeds
- **AND** script proceeds to apply secrets
- **AND** secrets are applied to cluster

#### Scenario: Secrets validation fails with invalid YAML
- **WHEN** secrets.yaml contains invalid Kubernetes configuration
- **THEN** kubectl apply --dry-run=server fails
- **AND** script exits with error code 1
- **AND** error message indicates validation failure
- **AND** deployment stops

### Requirement: Image registry verification handles catalog delays
The push-docker-image.sh script SHALL implement retry logic with exponential backoff when verifying image presence in registry catalog, accounting for catalog update delays.

#### Scenario: Image verification succeeds after retry
- **WHEN** image is pushed to registry but not yet in catalog
- **THEN** verification retries with exponential backoff
- **AND** verification succeeds after catalog updates
- **AND** deployment proceeds

#### Scenario: Image verification fails after maximum retries
- **WHEN** image verification fails after maximum retry attempts
- **THEN** script logs verification failure
- **AND** script exits with error code 1
- **AND** deployment stops
- **AND** error message includes manual verification steps

### Requirement: Pod startup is verified before marking deployment successful
The deploy-to-k8s.sh script SHALL verify that pods reach Running state and pass readiness checks before marking deployment as successful.

#### Scenario: Pod reaches Running state successfully
- **WHEN** deployment is applied
- **THEN** script polls pod status every 5 seconds
- **AND** script waits up to 5 minutes for Running state
- **AND** script verifies readiness probe passes
- **AND** deployment is marked successful

#### Scenario: Pod fails to reach Running state
- **WHEN** pod does not reach Running state within timeout
- **THEN** script logs pod status and events
- **AND** script exits with error code 1
- **AND** error message includes pod details and failure reason
- **AND** deployment stops

### Requirement: Deployment manifest is validated before application
The deploy-to-k8s.sh script SHALL validate the deployment.yaml manifest using kubectl apply --dry-run=server before applying it to the cluster.

#### Scenario: Manifest validation passes
- **WHEN** deployment.yaml contains valid Kubernetes configuration
- **THEN** kubectl apply --dry-run=server succeeds
- **AND** script proceeds to apply deployment
- **AND** deployment is applied to cluster

#### Scenario: Manifest validation fails
- **WHEN** deployment.yaml contains invalid Kubernetes configuration
- **THEN** kubectl apply --dry-run=server fails
- **AND** script exits with error code 1
- **AND** error message indicates validation failure
- **AND** deployment stops

### Requirement: Registry connectivity is verified before image operations
The deployment pipeline SHALL verify that the Microk8s registry is accessible and responding before attempting to push or pull images.

#### Scenario: Registry connectivity verified successfully
- **WHEN** registry is accessible at localhost:32000
- **THEN** curl request to registry succeeds
- **AND** registry returns valid JSON response
- **AND** deployment proceeds with image operations

#### Scenario: Registry connectivity fails
- **WHEN** registry is not accessible
- **THEN** curl request to registry fails
- **AND** script exits with error code 1
- **AND** error message indicates registry connectivity failure
- **AND** deployment stops
