## MODIFIED Requirements

### Requirement: Docker image load into VM
The deployment process SHALL verify Docker is available in multipass VM before tagging and pushing the built Docker image to the local microk8s registry at localhost:32000. Docker availability includes both Docker CLI installation and daemon operational status.

#### Scenario: Successful image tag and push with Docker available
- **WHEN** deployment script executes image tag command within VM
- **AND** Docker is installed in VM
- **AND** Docker daemon is running in VM
- **THEN** script SHALL tag the image as localhost:32000/my-ag-ui-app:latest within VM
- **THEN** script SHALL push the tagged image to the local microk8s registry
- **AND** script SHALL verify image is available in the registry
- **AND** script SHALL log to successful tag and push

#### Scenario: Image tag failure due to Docker not installed in VM
- **WHEN** deployment script attempts to execute image tag command
- **AND** Docker is not installed in VM
- **THEN** script SHALL log a clear error that Docker is not available in VM
- **AND** script SHALL provide instructions to install Docker in VM
- **AND** script SHALL exit with a non-zero status code
- **AND** script SHALL NOT attempt to restart deployment

#### Scenario: Image tag failure due to Docker daemon not running in VM
- **WHEN** deployment script attempts to execute image tag command
- **AND** Docker is installed in VM
- **AND** Docker daemon is not running in VM
- **THEN** script SHALL log a clear error that Docker daemon is not running
- **AND** script SHALL provide instructions to start Docker daemon
- **AND** script SHALL exit with a non-zero status code
- **AND** script SHALL NOT attempt to restart deployment

#### Scenario: Image tag or push failure
- **WHEN** image tag or push command fails
- **AND** Docker is available in VM
- **AND** failure is not related to Docker availability
- **THEN** script SHALL log error with context
- **AND** script SHALL exit with a non-zero status code
- **AND** script SHALL NOT attempt to restart deployment

#### Scenario: Docker availability verification before image operations
- **WHEN** deployment script is about to tag or push image
- **THEN** script SHALL verify Docker CLI is available in VM
- **AND** script SHALL verify Docker daemon is running in VM
- **AND** script SHALL log Docker availability status
- **AND** script SHALL proceed with image operations only if Docker is available

### Requirement: Pod restart with new image
The deployment process SHALL restart Kubernetes deployment to trigger pod recreation with the newly pushed registry image.

#### Scenario: Successful deployment restart
- **WHEN** deployment script restarts deployment
- **THEN** script SHALL use kubectl rollout restart command
- **AND** script SHALL wait for new pod to be created
- **AND** script SHALL verify that pod successfully pulls image from localhost:32000/my-ag-ui-app:latest
- **AND** script SHALL verify pod status reaches Running state without ImagePullBackOff errors

#### Scenario: Deployment restart failure
- **WHEN** deployment restart command fails
- **THEN** script SHALL log restart error with context
- **AND** script SHALL provide recovery suggestions
- **AND** script SHALL exit with a non-zero status code

### Requirement: Pod health verification
The deployment process SHALL verify that pod passes readiness and liveness probes after successfully pulling the image from the local registry.

#### Scenario: Pod becomes healthy
- **WHEN** pod starts successfully
- **THEN** script SHALL verify pod status is Running
- **AND** script SHALL verify readiness probe passes
- **AND** script SHALL verify liveness probe passes
- **AND** script SHALL log to successful health check

#### Scenario: Pod fails health checks
- **WHEN** pod fails readiness or liveness probes
- **THEN** script SHALL log which probe failed
- **AND** script SHALL provide pod logs for debugging
- **AND** script SHALL exit with a non-zero status code

### Requirement: Application accessibility verification
The deployment process SHALL verify that the application is accessible via ingress endpoint after pods are running with the local registry image.

#### Scenario: Application is accessible
- **WHEN** deployment script tests ingress endpoint
- **THEN** script SHALL verify application responds to HTTP requests
- **AND** script SHALL log accessible URL
- **AND** script SHALL confirm successful deployment

#### Scenario: Application is not accessible
- **WHEN** ingress endpoint is not accessible
- **THEN** script SHALL log accessibility failure
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL suggest checking ingress configuration
