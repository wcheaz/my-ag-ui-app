# Docker Image Build and Load

## Purpose

Capability for building Docker images and distributing them to multipass VM's container runtime. This enables deployment process to build application images locally and make them available to Kubernetes via microk8s local registry, using standard Docker push/pull workflow.

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

### Requirement: Docker image distribution via local registry
The deployment process SHALL verify microk8s local registry is available and push the built Docker image to it for Kubernetes deployment.

#### Scenario: Successful image push to microk8s local registry
- **WHEN** deployment script executes image distribution commands
- **AND** microk8s registry is enabled and accessible
- **AND** Docker image is built and tagged for registry
- **THEN** script SHALL tag image as `localhost:32000/my-ag-ui-app:latest`
- **THEN** script SHALL push image to microk8s registry
- **AND** script SHALL verify image is available in registry
- **AND** script SHALL log successful distribution with registry details

#### Scenario: Image distribution failure due to registry not enabled
- **WHEN** deployment script attempts to push image
- **AND** microk8s registry is not enabled
- **THEN** script SHALL log clear error that registry is not available
- **AND** script SHALL provide instructions to enable registry
- **AND** script SHALL exit with a non-zero status code
- **AND** script SHALL NOT attempt to restart deployment

#### Scenario: Image distribution failure due to Docker daemon not running
- **WHEN** deployment script attempts to tag or push image
- **AND** Docker daemon is not running
- **THEN** script SHALL log clear error that Docker daemon is not available
- **AND** script SHALL provide instructions to start Docker daemon
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
- **AND** script SHALL verify registry is accessible at localhost:32000
- **AND** script SHALL verify Docker daemon is running
- **AND** script SHALL log registry and Docker status
- **AND** script SHALL proceed with distribution only if both are available

### Requirement: Pod restart with new image
The deployment process SHALL restart the Kubernetes deployment to trigger pod recreation with the newly pushed image.

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
