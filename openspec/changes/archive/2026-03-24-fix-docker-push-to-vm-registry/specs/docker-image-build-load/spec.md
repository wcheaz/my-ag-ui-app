# Docker Image Build and Load

## Purpose

Capability for building Docker images and distributing them to multipass VM's container runtime. This enables deployment process to build application images locally and make them available to Kubernetes via microk8s local registry, using standard Docker push/pull workflow.

## MODIFIED Requirements

### Requirement: Docker image build
The deployment process SHALL build a Docker image from the project's Dockerfile after validating that package.json and package-lock.json are synchronized.

#### Scenario: Successful image build with validated dependencies
- **WHEN** the deployment script executes the docker build command
- **AND** package.json and package-lock.json are validated as synchronized
- **THEN** the script SHALL build an image named my-ag-ui-app:latest
- **AND** the script SHALL use the Dockerfile in the project root
- **AND** the script SHALL log the build progress
- **AND** the script SHALL use npm ci for clean installation
- **AND** the script SHALL log that dependencies were installed from lock file

#### Scenario: Image build failure with dependency sync error
- **WHEN** the deployment script validates dependencies
- **AND** package.json and package-lock.json are out of sync
- **THEN** the script SHALL NOT proceed with docker build
- **AND** the script SHALL log the dependency sync error with context
- **AND** the script SHALL provide instructions to run npm install to fix the issue
- **AND** the script SHALL exit with a non-zero status code

#### Scenario: Image build failure with npm ci fallback
- **WHEN** the docker build executes npm ci
- **AND** npm ci fails due to lock file sync issues
- **THEN** the Dockerfile SHALL automatically fall back to npm install
- **AND** the build SHALL log that fallback to npm install was triggered
- **AND** the build SHALL continue with dependency installation
- **AND** the build SHALL complete successfully if npm install succeeds

#### Scenario: Image build failure
- **WHEN** the docker build command fails
- **AND** the failure is not related to dependency synchronization
- **THEN** the script SHALL log the build error with context
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with deployment

### Requirement: Docker image distribution via local registry
The deployment process SHALL verify microk8s local registry is available and push the built Docker image to it for Kubernetes deployment, executing tag and push operations within the VM.

#### Scenario: Successful image push to microk8s local registry
- **WHEN** deployment script executes image distribution commands
- **AND** microk8s registry is enabled and accessible
- **AND** Docker image is built and tagged for registry within the VM
- **THEN** script SHALL tag image as `localhost:32000/my-ag-ui-app:latest` within the VM
- **THEN** script SHALL push image to microk8s registry from within the VM
- **AND** script SHALL verify image is available in registry
- **AND** script SHALL log successful distribution with registry details

#### Scenario: Image distribution failure due to registry not enabled
- **WHEN** deployment script attempts to push image
- **AND** microk8s registry is not enabled
- **THEN** script SHALL log clear error that registry is not available
- **AND** script SHALL provide instructions to enable registry
- **AND** script SHALL exit with a non-zero status code
- **AND** script SHALL NOT attempt to restart deployment

#### Scenario: Image distribution failure due to Docker daemon not running in VM
- **WHEN** deployment script attempts to tag or push image
- **AND** Docker daemon is not running in the VM
- **THEN** script SHALL log clear error that Docker daemon is not available in VM
- **AND** script SHALL provide instructions to start Docker daemon in VM
- **AND** script SHALL exit with a non-zero status code
- **AND** script SHALL NOT attempt to restart deployment

#### Scenario: Image distribution failure due to registry not accessible
- **WHEN** deployment script attempts to push image
- **AND** microk8s registry is enabled but not accessible
- **THEN** script SHALL log error that registry is not accessible
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL exit with a non-zero status code
- **AND** script SHALL NOT attempt to restart deployment

#### Scenario: Image distribution failure
- **WHEN** the image push command fails
- **AND** registry and Docker daemon are available
- **AND** failure is not related to availability
- **THEN** script SHALL log distribution error with context
- **AND** script SHALL implement retry logic for transient failures
- **AND** script SHALL exit with a non-zero status code after retries exhausted
- **AND** script SHALL NOT attempt to restart deployment

#### Scenario: Registry availability verification before image distribution
- **WHEN** deployment script is about to distribute image
- **THEN** script SHALL verify microk8s registry is enabled
- **AND** script SHALL verify registry is accessible at localhost:32000 within the VM
- **AND** script SHALL verify Docker daemon is running in the VM
- **AND** script SHALL log registry and Docker status
- **AND** script SHALL proceed with distribution only if both are available

### Requirement: Pod restart with new image
The deployment process SHALL restart the Kubernetes deployment to trigger pod recreation with the newly pushed image.

#### Scenario: Successful deployment restart
- **WHEN** the deployment script restarts the deployment
- **THEN** the script SHALL use kubectl rollout restart command
- **AND** the script SHALL wait for the new pod to be created
- **AND** the script SHALL verify that the pod status changes from ImagePullBackOff to Running

#### Scenario: Deployment restart failure
- **WHEN** the deployment restart command fails
- **THEN** the script SHALL log the restart error with context
- **AND** the script SHALL provide recovery suggestions
- **AND** the script SHALL exit with a non-zero status code

### Requirement: Pod health verification
The deployment process SHALL verify that the pod passes readiness and liveness probes.

#### Scenario: Pod becomes healthy
- **WHEN** the pod starts successfully
- **THEN** the script SHALL verify that the pod status is Running
- **AND** the script SHALL verify that the readiness probe passes
- **AND** the script SHALL verify that the liveness probe passes
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
- **THEN** the script SHALL verify that the application responds to HTTP requests
- **AND** the script SHALL log the accessible URL
- **AND** the script SHALL confirm successful deployment

#### Scenario: Application is not accessible
- **WHEN** the ingress endpoint is not accessible
- **THEN** the script SHALL log the accessibility failure
- **AND** the script SHALL provide troubleshooting steps
- **AND** the script SHALL suggest checking ingress configuration

## REMOVED Requirements

### Requirement: Docker image load into VM
**Reason**: Replaced by pushing images directly to microk8s local registry from within the VM. The new approach tags and pushes images entirely within the VM context where the registry is accessible, eliminating the need to transfer images from host to VM.

**Migration**: Remove docker save/load logic and host-to-VM image transfer code from deployment script. All image distribution now happens via registry push from within the VM.
