# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

# Proposal: Fix Kubernetes Deployment Issues

## Why

The deployment script fails to successfully deploy the application to the Kubernetes cluster running in the multipass VM (my-ag-ui-app-k8s) using microk8s. The root cause is that while Docker images are successfully loaded into the VM's Docker daemon, Kubernetes attempts to pull images from external registries (docker.io) instead of using the locally available images. This causes pods to remain in `ImagePullBackOff` state, preventing the application from running. This fix is needed to complete the deployment automation and enable reliable, repeatable deployments to the Kubernetes cluster using microk8s's built-in local registry.

## What Changes

- **Enable microk8s local registry**: Configure microk8s registry add-on to provide a local, trusted registry for image distribution
- **Tag images for local registry**: Modify deployment script to tag Docker images with the local registry endpoint (localhost:32000)
- **Push images to local registry**: Add functionality to push tagged images to the microk8s registry
- **Update deployment manifest**: Configure the deployment to reference images from the local registry (localhost:32000/my-ag-ui-app:latest)
- **Improve error handling**: Add validation to ensure registry is enabled and images are successfully pushed before attempting deployment
- **Streamline deployment**: Remove unnecessary retry logic and improve the deployment flow based on successful registry operations

## Capabilities

### New Capabilities
- `microk8s-registry-integration`: Capability for using microk8s's built-in local registry to distribute Docker images. This covers enabling the registry, tagging images for local registry, pushing images, and referencing them in Kubernetes deployments.

### Modified Capabilities
- `docker-image-build-load`: Update the image loading requirements to support pushing images to microk8s local registry instead of loading into Docker daemon. The current spec only covers loading into Docker daemon; this change adds registry push as the primary method for microk8s deployments.

- `kubernetes-deployment`: Update the deployment requirements to include local registry image references and registry availability verification. The current spec assumes images are pulled from external registries; this change adds support for microk8s local registry images.

## Impact

- **Affected Code**: [`deploy.sh`](deploy.sh) - main deployment script requiring modifications to enable registry, tag/push images, and verify registry operations
- **Affected Configuration**: [`k8s/deployment.yaml`](k8s/deployment.yaml) - needs image reference updated to `localhost:32000/my-ag-ui-app:latest`
- **Dependencies**: Requires microk8s registry add-on (standard with microk8s installation)
- **Systems**: 
  - Host system: Docker build and image tagging operations
  - Multipass VM: Registry enablement and image push operations
  - Microk8s cluster: Local registry at localhost:32000, pod deployment using registry images
- **Deployment Flow**: Changes the image distribution to use microk8s local registry (push) instead of direct daemon loading

## Specifications

docker-image-build-load/spec.md
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

kubernetes-deployment/spec.md
# Kubernetes Deployment

## Purpose

Capability for deploying application containers to Kubernetes using microk8s, including deployment manifests, services, and configuration management. Supports images distributed via microk8s local registry using standard Docker push/pull workflow.

## MODIFIED Requirements

### Requirement: System must provide Kubernetes deployment manifest
The system SHALL provide a deployment.yaml manifest that defines how application container is deployed in Kubernetes, including replicas, resource limits, health checks, and image reference to local registry.

#### Scenario: Deployment manifest is valid
- **WHEN** `microk8s kubectl apply -f deployment.yaml` is executed
- **THEN** Kubernetes creates deployment without errors
- **AND** deployment is in "Available" state

#### Scenario: Deployment creates correct number of replicas
- **WHEN** deployment is applied
- **THEN** it creates specified number of replica pods
- **AND** all pods are running and ready

#### Scenario: Deployment uses local registry image reference
- **WHEN** deployment manifest is examined
- **THEN** it includes image reference `localhost:32000/my-ag-ui-app:latest`
- **AND** it references image from microk8s local registry
- **AND** it allows Kubernetes to pull image from local registry

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
- **AND** required add-ons (dns, storage, ingress, registry) are enabled

#### Scenario: Microk8s add-ons are enabled
- **WHEN** `microk8s status` is checked
- **THEN** dns add-on is enabled
- **AND** storage add-on is enabled
- **AND** ingress add-on is enabled
- **AND** registry add-on is enabled

### Requirement: System must handle container image deployment
The system SHALL build container image and distribute it to Kubernetes cluster using microk8s local registry, enabling standard Docker push/pull workflow.

#### Scenario: Container image is built
- **WHEN** deployment script is executed
- **THEN** Docker image is built successfully
- **AND** image is tagged appropriately

#### Scenario: Container image is pushed to local registry
- **WHEN** deployment script pushes image to microk8s registry
- **AND** registry is enabled and accessible
- **THEN** image is successfully pushed to `localhost:32000/my-ag-ui-app:latest`
- **AND** image is available to Kubernetes cluster

#### Scenario: Container image is available to cluster
- **WHEN** deployment is applied
- **THEN** Kubernetes cluster can pull container image from local registry
- **AND** pods start with the correct image
- **AND** pods do not enter ImagePullBackOff state

### Requirement: System must provide deployment verification
The system SHALL include verification steps to ensure deployment is successful, including pod status checks, registry image availability verification, and application access tests.

#### Scenario: Deployment status is verified
- **WHEN** deployment is complete
- **THEN** all pods are in "Running" state
- **AND** all pods are "Ready"
- **AND** deployment is "Available"

#### Scenario: Image availability in registry is verified
- **WHEN** deployment is initiated
- **THEN** script SHALL verify image exists in microk8s registry
- **THEN** script SHALL confirm image tag matches deployment manifest
- **AND** script SHALL log image availability before attempting deployment

#### Scenario: Application access is verified
- **WHEN** application is accessed via ingress
- **THEN** it responds with HTTP 200 status
- **AND** application content is displayed correctly

microk8s-registry-integration/spec.md
# Microk8s Registry Integration

## Purpose

Capability for using microk8s's built-in local registry to distribute Docker images for Kubernetes deployment. This enables standard Docker push/pull workflow while keeping all image distribution within the VM, eliminating external registry dependencies.

## ADDED Requirements

### Requirement: System must enable microk8s local registry
The deployment process SHALL enable microk8s's built-in registry add-on to provide a local, trusted registry for image distribution.

#### Scenario: Successful registry enablement
- **WHEN** deployment script executes `microk8s enable registry` command
- **AND** microk8s is installed and running
- **THEN** script SHALL enable registry add-on
- **AND** script SHALL verify registry is running at localhost:32000
- **AND** script SHALL log successful enablement

#### Scenario: Registry enablement failure due to microk8s not running
- **WHEN** deployment script attempts to enable registry
- **AND** microk8s is not running
- **THEN** script SHALL log clear error that microk8s is not available
- **AND** script SHALL provide instructions to start microk8s
- **AND** script SHALL exit with non-zero status code
- **AND** script SHALL NOT proceed with deployment

#### Scenario: Registry enablement failure due to port conflict
- **WHEN** deployment script attempts to enable registry
- **AND** port 32000 is already in use
- **THEN** script SHALL log error about port conflict
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL exit with non-zero status code

#### Scenario: Registry is already enabled
- **WHEN** deployment script attempts to enable registry
- **AND** registry is already enabled and running
- **THEN** script SHALL verify registry is accessible
- **AND** script SHALL log that registry is already enabled
- **AND** script SHALL proceed with deployment

### Requirement: System must tag Docker images for local registry
The deployment process SHALL tag Docker images with the local registry endpoint to make them addressable for push operations.

#### Scenario: Successful image tagging
- **WHEN** deployment script executes docker tag command
- **AND** source image exists in Docker daemon
- **THEN** script SHALL tag image as `localhost:32000/my-ag-ui-app:latest`
- **AND** script SHALL verify tag was created successfully
- **AND** script SHALL log successful tagging

#### Scenario: Image tagging failure due to source image not found
- **WHEN** deployment script attempts to tag image
- **AND** source image does not exist in Docker daemon
- **THEN** script SHALL log error that source image is not available
- **AND** script SHALL provide instructions to build image first
- **AND** script SHALL exit with non-zero status code

#### Scenario: Image tagging failure due to Docker daemon not running
- **WHEN** deployment script attempts to tag image
- **AND** Docker daemon is not running
- **THEN** script SHALL log error that Docker daemon is not available
- **AND** script SHALL provide instructions to start Docker daemon
- **AND** script SHALL exit with non-zero status code

### Requirement: System must push images to local registry
The deployment process SHALL push tagged Docker images to microk8s local registry using standard Docker push commands.

#### Scenario: Successful image push to registry
- **WHEN** deployment script executes docker push command
- **AND** image is tagged for local registry
- **AND** registry is accessible at localhost:32000
- **THEN** script SHALL push image to registry
- **AND** script SHALL verify push completed successfully
- **AND** script SHALL log successful push with image details

#### Scenario: Image push failure due to registry not accessible
- **WHEN** deployment script attempts to push image
- **AND** registry is not accessible at localhost:32000
- **THEN** script SHALL log error that registry is not available
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL exit with non-zero status code

#### Scenario: Image push failure due to network issues
- **WHEN** deployment script attempts to push image
- **AND** transient network issues occur
- **THEN** script SHALL implement retry logic with exponential backoff
- **AND** script SHALL log retry attempts
- **AND** script SHALL succeed if push succeeds within retry limit
- **AND** script SHALL fail with clear error if all retries exhausted

#### Scenario: Image push failure due to invalid tag
- **WHEN** deployment script attempts to push image
- **AND** image tag is invalid or not found
- **THEN** script SHALL log error about invalid image tag
- **AND** script SHALL provide instructions to check image tagging
- **AND** script SHALL exit with non-zero status code

### Requirement: System must verify registry operations
The deployment process SHALL verify that registry is enabled and accessible before attempting push operations.

#### Scenario: Registry is accessible and ready
- **WHEN** deployment script checks registry status
- **AND** registry is enabled and running
- **THEN** script SHALL confirm registry is accessible at localhost:32000
- **AND** script SHALL display registry status
- **AND** script SHALL proceed with push operations

#### Scenario: Registry is not accessible
- **WHEN** deployment script checks registry status
- **AND** registry is not accessible
- **THEN** script SHALL log error that registry is unavailable
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL exit with non-zero status code
- **AND** script SHALL NOT attempt push operations

### Requirement: System must provide clear error messages and recovery suggestions
The deployment process SHALL provide actionable error messages with specific recovery steps for each failure scenario in registry operations.

#### Scenario: Error message includes context
- **WHEN** any registry operation fails
- **THEN** script SHALL log error with specific failure reason
- **AND** script SHALL include relevant command that failed
- **AND** script SHALL include error output if available

#### Scenario: Error message includes recovery suggestions
- **WHEN** any registry operation fails
- **THEN** script SHALL provide specific recovery steps
- **AND** script SHALL suggest checking prerequisites (microk8s, Docker daemon)
- **AND** script SHALL suggest retrying for transient failures
- **AND** script SHALL provide manual intervention steps if automated recovery fails



## Design

# Design: Fix Kubernetes Deployment Issues

## Context

### Current State

The deployment script ([`deploy.sh`](deploy.sh)) successfully builds Docker images and loads them into the multipass VM's Docker daemon. However, the Kubernetes cluster running in the VM uses microk8s, which attempts to pull images from external registries by default. This creates a deployment failure: images are available locally in Docker, but Kubernetes tries to pull from `docker.io/library/my-ag-ui-app:latest`, causing pods to fail with `ImagePullBackOff` status.

### Problem Analysis

From [`deploy_log.md`](deploy_log.md) analysis:
- Docker image `my-ag-ui-app:latest` is successfully built and loaded into the VM's Docker daemon
- The image is verified as available in Docker (546MB, created 2026-03-23 11:05:10)
- Kubernetes attempts to pull the image from `docker.io/library/my-ag-ui-app:latest` (external registry)
- Pod remains in `ImagePullBackOff` state for 89 seconds before timeout
- Error: `failed to pull and unpack image "docker.io/library/my-ag-ui-app:latest": failed to unpack image on snapshotter overlayfs: unexpected media type text/html`

### Root Cause

Registry pull configuration:
- **Build process**: Uses Docker daemon to build and store images
- **Deployment target**: microk8s uses containerd as container runtime
- **Default behavior**: Kubernetes attempts to pull images from external registries
- **Local availability**: Images exist in Docker daemon but Kubernetes doesn't know to use them
- **Result**: Kubernetes ignores local images and fails trying to pull from non-existent registry

### Constraints

- Must use microk8s's built-in local registry (official/recommended approach)
- Must work within multipass VM environment
- Must follow ralph-loops best practices for task execution
- Must minimize human intervention (automated workflow)
- Must not require external container registry

## Goals / Non-Goals

**Goals:**
1. Enable microk8s local registry to distribute locally built Docker images
2. Configure deployment script to tag images for local registry (localhost:32000)
3. Push tagged images to microk8s registry using standard Docker commands
4. Update Kubernetes deployment to reference images from local registry
5. Improve error handling and validation for registry operations
6. Maintain existing Docker build functionality
7. Provide clear error messages and recovery suggestions for failures

**Non-Goals:**
1. Setting up an external container registry (Docker Hub, private registry, etc.)
2. Using containerd import tools (ctr, crictl) directly
3. Modifying to application code or Dockerfile
4. Supporting container runtimes other than Docker
5. Implementing image caching or optimization strategies

## Decisions

### Decision 1: Use microk8s built-in local registry

**Rationale:**
- microk8s includes a local registry add-on at `localhost:32000`
- This is the official/recommended approach by Canonical for microk8s
- Registry is pre-configured and trusted by containerd
- Uses standard Docker push/pull workflow
- No need to understand containerd internals
- All communication stays within the VM

**Alternatives Considered:**
1. **Use containerd import tools (ctr/crictl)**: Rejected - requires understanding containerd internals, less standard approach
2. **Use external registry (Docker Hub)**: Rejected - adds infrastructure complexity and external dependencies
3. **Configure microk8s to use Docker daemon**: Rejected - requires significant microk8s reconfiguration, not supported by default

### Decision 2: Tag images for local registry

**Rationale:**
- Docker images must be tagged with registry endpoint before pushing
- Tagging with `localhost:32000/my-ag-ui-app:latest` makes image addressable by registry
- Standard Docker workflow: tag → push → reference in deployment
- Clear and predictable naming convention

**Alternatives Considered:**
1. **Push without tagging**: Rejected - Docker requires registry prefix in tag
2. **Use complex tagging schemes**: Rejected - adds unnecessary complexity, simple localhost:32000 prefix is sufficient
3. **Manual tagging**: Rejected - increases human intervention, should be automated

### Decision 3: Push images to local registry

**Rationale:**
- Standard Docker push command: `docker push localhost:32000/my-ag-ui-app:latest`
- Registry runs inside VM, no network latency
- Push validates image integrity and availability
- Provides clear feedback on success/failure
- Enables Kubernetes to pull from registry using standard workflow

**Alternatives Considered:**
1. **Copy image files to registry storage**: Rejected - bypasses Docker push validation, non-standard
2. **Use skopeo for image transfer**: Rejected - additional dependency, adds complexity without clear benefit
3. **Manual image transfer**: Rejected - increases human intervention, error-prone

### Decision 4: Reference local registry images in deployment

**Rationale:**
- Kubernetes deployment manifest must reference registry image: `localhost:32000/my-ag-ui-app:latest`
- Standard Kubernetes workflow: pull from registry (even local registry)
- No special configuration needed, just correct image reference
- Registry is pre-trusted by containerd, no additional setup

**Alternatives Considered:**
1. **Use imagePullPolicy: Never with local images**: Rejected - requires containerd import, more complex
2. **Keep default image name**: Rejected - Kubernetes will try to pull from docker.io, causing same failure
3. **Use imagePullPolicy: IfNotPresent**: Rejected - may attempt registry pull, causing failures

### Decision 5: Enable registry automatically

**Rationale:**
- Use `microk8s enable registry` command to enable registry add-on
- One-time setup, not per-deployment
- Registry runs as service, always available
- Minimizes human intervention
- Follows ralph-loops best practice of automating setup

**Alternatives Considered:**
1. **Manual registry enablement**: Rejected - increases human intervention, should be automated
2. **Check if registry is enabled**: Rejected - enabling multiple times is idempotent, safe to always run
3. **Use external registry**: Rejected - adds infrastructure complexity and external dependencies

### Decision 6: Verify registry operations

**Rationale:**
- Early detection of registry issues prevents confusing Kubernetes errors
- Provides clear error messages at right stage of deployment
- Reduces debugging time by failing fast
- Aligns with ralph-loops best practice of validating prerequisites

**Alternatives Considered:**
1. **Let Kubernetes handle registry availability**: Rejected - results in cryptic ImagePullBackOff errors
2. **Skip verification entirely**: Rejected - increases deployment failure rate and debugging difficulty
3. **Verify only in Docker**: Rejected - doesn't verify registry is accessible to Kubernetes

## Risks / Trade-offs

### Risk 1: Registry not enabled in microk8s

**Mitigation:**
- Automatically enable registry with `microk8s enable registry`
- Verify registry is running before attempting push
- Provide clear error messages if registry is unavailable
- Document registry enablement in deployment script

### Risk 2: Docker push fails

**Mitigation:**
- Verify Docker daemon is running before push
- Check image exists and is tagged correctly
- Provide clear error messages with recovery suggestions
- Implement retry logic for transient network issues
- Validate registry is accessible before push

### Risk 3: Registry port conflicts

**Mitigation:**
- Use standard microk8s registry port (32000)
- Document port requirement in deployment script
- Check if port is in use before enabling registry
- Provide clear error if port conflict occurs

### Risk 4: Breaking existing Docker-based deployments

**Mitigation:**
- Registry approach is additive, doesn't break existing Docker workflows
- Docker images remain available for other uses
- Test both registry and Docker workflows
- Document registry approach clearly

### Risk 5: Increased deployment complexity

**Mitigation:**
- Encapsulate registry logic in reusable functions
- Provide clear logging at each stage
- Use descriptive error messages with recovery suggestions
- Follow ralph-loops task breakdown for maintainability

### Trade-off: Additional deployment time for registry operations

**Impact:**
- Adds ~10-30 seconds for registry enablement (one-time)
- Adds ~5-10 seconds for image tag and push per deployment
- Increases total deployment time compared to Docker-only workflow

**Justification:**
- Time increase is minimal and acceptable given to benefit of successful deployments
- Registry enablement is one-time cost, not per deployment
- Reduces overall time spent debugging failed deployments
- Enables reliable, repeatable deployments without external dependencies
- Uses official/recommended microk8s approach

## Migration Plan

### Deployment Steps

1. **Update deployment script** ([`deploy.sh`](deploy.sh)):
   - Add microk8s registry enablement function
   - Add image tagging function for local registry
   - Add image push function to local registry
   - Add registry availability verification
   - Improve error handling and logging
   - Remove Docker daemon loading (no longer needed)

2. **Update Kubernetes deployment manifest** ([`k8s/deployment.yaml`](k8s/deployment.yaml)):
   - Update image reference to `localhost:32000/my-ag-ui-app:latest`
   - Remove any `imagePullPolicy` settings (use default behavior)

3. **Test deployment workflow**:
   - Build Docker image locally
   - Tag image for local registry
   - Enable microk8s registry
   - Push image to local registry
   - Apply Kubernetes deployment
   - Confirm pods reach Running state
   - Verify application accessibility via ingress

4. **Validate error handling**:
   - Test with registry not enabled
   - Test with registry port conflicts
   - Test with Docker daemon not running
   - Test with invalid image tags
   - Verify error messages are clear and actionable

### Rollback Strategy

If deployment fails after implementing changes:
1. **Revert deployment script** to previous version using Docker-only loading
2. **Restore deployment.yaml** to use `my-ag-ui-app:latest` image reference
3. **Document failure** with detailed logs for analysis
4. **Consider alternative approach** if registry approach proves unreliable

**Rollback triggers:**
- Registry consistently fails to enable or run
- Image push consistently fails
- Pods fail to start even with successful registry push
- Deployment time increases unacceptably (>5 minutes)
- New errors introduced in deployment workflow

## Open Questions

1. **Registry persistence**: Should registry enablement be cached or re-executed on each deployment? Re-executing is idempotent and safer, but adds small overhead.

2. **Image tag management**: Should the script automatically retag images for local registry, or expect images to be pre-tagged? Automatic tagging reduces human intervention.

3. **Disk space management**: Should the deployment script actively clean up old images in registry to prevent disk space issues, or leave this to manual maintenance?

4. **Error recovery**: For transient failures (network issues, temporary registry unavailability), should the deployment script implement automatic retry logic or fail fast and require manual intervention?

## Current Task Context

## Current Task
- 7.12 Test deployment script syntax validation to catch syntax errors before execution
## Completed Tasks for Git Commit
- [x] 1.1 Add function to enable microk8s registry using `microk8s enable registry` command
- [x] 1.2 Add function to verify registry is running and accessible at localhost:32000
- [x] 1.3 Add error handling for registry enablement failures with clear messages
- [x] 1.4 Add logging for registry status and enablement
- [x] 2.1 Add function to tag Docker image with local registry endpoint (localhost:32000/my-ag-ui-app:latest)
- [x] 2.2 Add validation to ensure source image exists before tagging
- [x] 2.3 Add error handling for tagging failures with clear messages
- [x] 2.4 Add logging for tagging operations
- [x] 3.1 Add function to push tagged image to microk8s registry using `docker push` command
- [x] 3.2 Add validation to ensure registry is accessible before push
- [x] 3.3 Add error handling for push failures with retry logic for transient issues
- [x] 3.4 Add verification that image is successfully pushed to registry
- [x] 3.5 Add logging for push operations and success/failure status
- [x] 4.1 Update image reference in deployment.yaml to `localhost:32000/my-ag-ui-app:latest`
- [x] 4.2 Remove any `imagePullPolicy` settings from deployment.yaml (use default pull behavior)
- [x] 4.3 Verify deployment manifest applies correctly with kubectl
- [x] 4.4 Document image reference change in deployment manifest comments
- [x] 5.1 Integrate registry enablement into main deployment flow
- [x] 5.2 Integrate image tagging into deployment flow after Docker build
- [x] 5.3 Integrate image push into deployment flow after tagging
- [x] 5.4 Remove Docker daemon loading logic from deployment script (no longer needed)
- [x] 5.5 Update pod status verification to handle registry-based deployments
- [x] 5.6 Add comprehensive logging throughout deployment process
- [x] 5.7 Test complete deployment flow from build to running pods
- [x] 6.1 Add pre-flight check for Docker daemon availability before operations
- [x] 6.2 Add validation for registry availability before push
- [x] 6.3 Add validation for image existence before tagging
- [x] 6.4 Add specific error messages for each failure scenario (registry not enabled, push failed, tag failed)
- [x] 6.5 Add recovery suggestions to error messages (enable registry, check Docker daemon, retry steps)
- [x] 6.6 Add retry logic for transient failures (network issues, temporary registry unavailability)
- [x] 6.7 Add disk space check before large operations (image build, push)
- [x] 7.1 Test registry enablement with microk8s
- [x] 7.2 Test image tagging for local registry
- [x] 7.3 Test image push to local registry
- [x] 7.4 Test deployment with registry image reference
- [x] 7.5 Test error handling when registry is not enabled
- [x] 7.6 Test error handling with Docker daemon not running
- [x] 7.7 Test error handling with invalid image tags
- [x] 7.8 Test error handling with registry port conflicts
- [x] 7.9 Verify pods reach Running state after successful registry push
- [x] 7.10 Verify application is accessible via ingress after deployment
- [x] 7.11 Test complete deployment flow end-to-end
- [x] 8.1 Update deployment script comments to explain registry approach
- [x] 8.2 Add README section explaining microk8s registry workflow
- [x] 8.3 Document troubleshooting steps for common registry issues
- [x] 8.4 Update project documentation with new deployment workflow
- [x] 8.5 Clean up any test images or temporary files from development
- [x] 8.6 Verify all code follows project coding standards
- [x] 8.7 Commit changes with descriptive commit message referencing this change
