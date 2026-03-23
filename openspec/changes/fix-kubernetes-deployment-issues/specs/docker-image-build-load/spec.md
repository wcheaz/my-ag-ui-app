# Docker Image Build and Load

## Purpose

Capability for building Docker images and loading them into multipass VM's container runtime. This enables deployment process to build application images locally and transfer them to VM for Kubernetes deployment, supporting both Docker and containerd runtimes.

## MODIFIED Requirements

### Requirement: Docker image build
The deployment process SHALL build a Docker image from the project's Dockerfile after validating that package.json and package-lock.json are synchronized.

#### Scenario: Successful image build with validated dependencies
- **WHEN** deployment script executes docker build command
- **AND** package.json and package-lock.json are validated as synchronized
- **THEN** script SHALL build an image named my-ag-ui-app:latest
- **AND** script SHALL use Dockerfile in project root
- **AND** script SHALL log build progress
- **AND** script SHALL use npm ci for clean installation
- **AND** script SHALL log that dependencies were installed from lock file

#### Scenario: Image build failure with dependency sync error
- **WHEN** deployment script validates dependencies
- **AND** package.json and package-lock.json are out of sync
- **THEN** script SHALL NOT proceed with docker build
- **AND** script SHALL log dependency sync error with context
- **AND** script SHALL provide instructions to run npm install to fix issue
- **AND** script SHALL exit with a non-zero status code

#### Scenario: Image build failure with npm ci fallback
- **WHEN** docker build executes npm ci
- **AND** npm ci fails due to lock file sync issues
- **THEN** Dockerfile SHALL automatically fall back to npm install
- **AND** build SHALL log that fallback to npm install was triggered
- **AND** build SHALL continue with dependency installation
- **AND** build SHALL complete successfully if npm install succeeds

#### Scenario: Image build failure
- **WHEN** docker build command fails
- **AND** failure is not related to dependency synchronization
- **THEN** script SHALL log build error with context
- **AND** script SHALL exit with a non-zero status code
- **AND** script SHALL NOT proceed with deployment

### Requirement: Docker image load into container runtime
The deployment process SHALL verify the appropriate container runtime (Docker or containerd) is available in multipass VM before loading the built Docker image. For microk8s deployments, containerd SHALL be used as the primary target runtime.

#### Scenario: Successful image load into containerd for microk8s
- **WHEN** deployment script executes image load command
- **AND** microk8s is detected as the Kubernetes distribution
- **AND** containerd tools (ctr or crictl) are available in VM
- **THEN** script SHALL save image using docker save
- **THEN** script SHALL transfer image file to VM using multipass transfer
- **THEN** script SHALL import image into containerd namespace
- **AND** script SHALL verify image is available in containerd
- **AND** script SHALL log successful load with container runtime type

#### Scenario: Successful image load into Docker daemon
- **WHEN** deployment script executes image load command
- **AND** Docker is installed in VM
- **AND** Docker daemon is running in VM
- **AND** containerd is not the target runtime
- **THEN** script SHALL save image using docker save
- **THEN** script SHALL pipe image to multipass exec with docker load
- **AND** script SHALL verify image is available in Docker
- **AND** script SHALL log successful load with container runtime type

#### Scenario: Image load failure due to containerd tools not available
- **WHEN** deployment script attempts to execute image load command
- **AND** microk8s is detected as the Kubernetes distribution
- **AND** neither ctr nor crictl is available in VM
- **THEN** script SHALL log a clear error that containerd tools are not available
- **AND** script SHALL provide instructions to install containerd tools
- **AND** script SHALL exit with a non-zero status code
- **AND** script SHALL NOT attempt to restart deployment

#### Scenario: Image load failure due to Docker not installed in VM
- **WHEN** deployment script attempts to execute image load command
- **AND** Docker is not installed in VM
- **AND** Docker is the target runtime
- **THEN** script SHALL log a clear error that Docker is not available in VM
- **AND** script SHALL provide instructions to install Docker in VM
- **AND** script SHALL exit with a non-zero status code
- **AND** script SHALL NOT attempt to restart deployment

#### Scenario: Image load failure due to Docker daemon not running in VM
- **WHEN** deployment script attempts to execute image load command
- **AND** Docker is installed in VM
- **AND** Docker daemon is not running in VM
- **AND** Docker is the target runtime
- **THEN** script SHALL log a clear error that Docker daemon is not running
- **AND** script SHALL provide instructions to start Docker daemon
- **AND** script SHALL exit with a non-zero status code
- **AND** script SHALL NOT attempt to restart deployment

#### Scenario: Image load failure
- **WHEN** the image load command fails
- **AND** container runtime is available in VM
- **AND** failure is not related to container runtime availability
- **THEN** script SHALL log load error with context
- **AND** script SHALL exit with a non-zero status code
- **AND** script SHALL NOT attempt to restart deployment

#### Scenario: Container runtime availability verification before image load
- **WHEN** deployment script is about to load image
- **THEN** script SHALL detect which container runtime to use (Docker or containerd)
- **AND** script SHALL verify appropriate runtime tools are available in VM
- **AND** script SHALL verify container runtime is operational
- **AND** script SHALL log container runtime type and status
- **AND** script SHALL proceed with image load only if runtime is available

### Requirement: Pod restart with new image
The deployment process SHALL restart the Kubernetes deployment to trigger pod recreation with the newly loaded image.

#### Scenario: Successful deployment restart
- **WHEN** deployment script restarts deployment
- **THEN** script SHALL use kubectl rollout restart command
- **AND** script SHALL wait for the new pod to be created
- **AND** script SHALL verify pod status changes from ImagePullBackOff to Running

#### Scenario: Deployment restart failure
- **WHEN** deployment restart command fails
- **THEN** script SHALL log restart error with context
- **AND** script SHALL provide recovery suggestions
- **AND** script SHALL exit with a non-zero status code

### Requirement: Pod health verification
The deployment process SHALL verify that the pod passes readiness and liveness probes.

#### Scenario: Pod becomes healthy
- **WHEN** pod starts successfully
- **THEN** script SHALL verify pod status is Running
- **AND** script SHALL verify readiness probe passes
- **AND** script SHALL verify liveness probe passes
- **AND** script SHALL log successful health check

#### Scenario: Pod fails health checks
- **WHEN** pod fails readiness or liveness probes
- **THEN** script SHALL log which probe failed
- **AND** script SHALL provide pod logs for debugging
- **AND** script SHALL exit with a non-zero status code

### Requirement: Application accessibility verification
The deployment process SHALL verify that the application is accessible via the ingress endpoint.

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
