# Docker Image Build and Load

## Purpose

Capability for building Docker images and loading them into the multipass VM's Docker daemon. This enables the deployment process to build application images locally and transfer them to the VM for Kubernetes deployment.

## Requirements

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

### Requirement: Docker image load into VM
The deployment process SHALL verify Docker is available in the multipass VM before loading the built Docker image into the VM's Docker daemon. Docker availability includes both Docker CLI installation and daemon operational status.

#### Scenario: Successful image load with Docker available
- **WHEN** the deployment script executes the image load command
- **AND** Docker is installed in the VM
- **AND** Docker daemon is running in the VM
- **THEN** the script SHALL save the image using docker save
- **THEN** the script SHALL pipe the image to multipass exec with docker load
- **AND** the script SHALL verify the image is available in the VM
- **AND** the script SHALL log the successful load

#### Scenario: Image load failure due to Docker not installed in VM
- **WHEN** the deployment script attempts to execute the image load command
- **AND** Docker is not installed in the VM
- **THEN** the script SHALL log a clear error that Docker is not available in the VM
- **AND** the script SHALL provide instructions to install Docker in the VM
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT attempt to restart the deployment

#### Scenario: Image load failure due to Docker daemon not running in VM
- **WHEN** the deployment script attempts to execute the image load command
- **AND** Docker is installed in the VM
- **AND** Docker daemon is not running in the VM
- **THEN** the script SHALL log a clear error that Docker daemon is not running
- **AND** the script SHALL provide instructions to start the Docker daemon
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT attempt to restart the deployment

#### Scenario: Image load failure
- **WHEN** the image load command fails
- **AND** Docker is available in the VM
- **AND** the failure is not related to Docker availability
- **THEN** the script SHALL log the load error with context
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT attempt to restart the deployment

#### Scenario: Docker availability verification before image load
- **WHEN** the deployment script is about to load the image
- **THEN** the script SHALL verify Docker CLI is available in the VM
- **AND** the script SHALL verify Docker daemon is running in the VM
- **AND** the script SHALL log the Docker availability status
- **AND** the script SHALL proceed with image load only if Docker is available

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
