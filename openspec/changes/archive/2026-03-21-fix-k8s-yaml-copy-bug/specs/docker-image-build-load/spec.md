## ADDED Requirements

### Requirement: Docker image build
The deployment process SHALL build a Docker image from the project's Dockerfile.

#### Scenario: Successful image build
- **WHEN** the deployment script executes the docker build command
- **THEN** the script SHALL build an image named my-ag-ui-app:latest
- **AND** the script SHALL use the Dockerfile in the project root
- **AND** the script SHALL log the build progress

#### Scenario: Image build failure
- **WHEN** the docker build command fails
- **THEN** the script SHALL log the build error with context
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with deployment

### Requirement: Docker image load into VM
The deployment process SHALL load the built Docker image into the multipass VM's Docker daemon.

#### Scenario: Successful image load
- **WHEN** the deployment script executes the image load command
- **THEN** the script SHALL save the image using docker save
- **THEN** the script SHALL pipe the image to multipass exec with docker load
- **AND** the script SHALL verify the image is available in the VM
- **AND** the script SHALL log the successful load

#### Scenario: Image load failure
- **WHEN** the image load command fails
- **THEN** the script SHALL log the load error with context
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT attempt to restart the deployment

### Requirement: Pod restart with new image
The deployment process SHALL restart the Kubernetes deployment to trigger pod recreation with the newly loaded image.

#### Scenario: Successful deployment restart
- **WHEN** the deployment script restarts the deployment
- **THEN** the script SHALL use kubectl rollout restart command
- **AND** the script SHALL wait for the new pod to be created
- **AND** the script SHALL verify the pod status changes from ImagePullBackOff to Running

#### Scenario: Deployment restart failure
- **WHEN** the deployment restart command fails
- **THEN** the script SHALL log the restart error with context
- **AND** the script SHALL provide recovery suggestions
- **AND** the script SHALL exit with a non-zero status code

### Requirement: Pod health verification
The deployment process SHALL verify that the pod passes readiness and liveness probes.

#### Scenario: Pod becomes healthy
- **WHEN** the pod starts successfully
- **THEN** the script SHALL verify the pod status is Running
- **AND** the script SHALL verify readiness probe passes
- **AND** the script SHALL verify liveness probe passes
- **AND** the script SHALL log the successful health check

#### Scenario: Pod fails health checks
- **WHEN** the pod fails readiness or liveness probes
- **THEN** the script SHALL log which probe failed
- **AND** the script SHALL provide pod logs for debugging
- **AND** the script SHALL exit with a non-zero status code

### Requirement: Application accessibility verification
The deployment process SHALL verify that the application is accessible via the ingress endpoint.

#### Scenario: Application is accessible
- **WHEN** the deployment script tests the ingress endpoint
- **THEN** the script SHALL verify the application responds to HTTP requests
- **AND** the script SHALL log the accessible URL
- **AND** the script SHALL confirm successful deployment

#### Scenario: Application is not accessible
- **WHEN** the ingress endpoint is not accessible
- **THEN** the script SHALL log the accessibility failure
- **AND** the script SHALL provide troubleshooting steps
- **AND** the script SHALL suggest checking ingress configuration
