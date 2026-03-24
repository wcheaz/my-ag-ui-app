# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

# Proposal: Fix Docker Push to Microk8s Registry

## Why

The deployment script successfully builds the Docker image on the host system and verifies the microk8s registry is running in the VM. However, when attempting to push the image to the registry, it fails with "connection refused" because the host's Docker daemon tries to connect to `localhost:32000` (host's localhost) instead of the VM's `localhost:32000` where the registry actually runs. This prevents successful Kubernetes deployment.

## What Changes

- **Execute Docker push from within VM**: Modify the image push command to execute via `multipass exec` so it runs inside the VM where `localhost:32000` resolves to the microk8s registry
- **Tag image for registry within VM**: Update image tagging to execute inside the VM so the tagged image is available to the VM's Docker daemon
- **Keep Docker build on host**: Maintain existing Docker build workflow on the host system (no changes needed)
- **Minimal deployment script changes**: Only modify the image tag and push operations in [`deploy.sh`](deploy.sh)

## Capabilities

### New Capabilities
- `vm-registry-push`: Capability for pushing Docker images to microk8s registry from within the VM. This covers tagging images and pushing to the local registry where it's accessible.

### Modified Capabilities
- `docker-image-build-load`: Update requirements to execute image tag and push operations within the VM instead of on the host system. The Docker build remains on host, but tag and push move to VM context.

## Impact

- **Affected Code**: [`deploy.sh`](deploy.sh) - modify only the image tag and push sections to execute via `multipass exec`
- **Affected Configuration**: No configuration changes needed - [`k8s/deployment.yaml`](k8s/deployment.yaml) already references correct image location
- **Dependencies**: Requires Docker to be installed and running within the multipass VM (already present)
- **Systems**: 
  - Host system: Docker build continues to execute here
  - Multipass VM: Image tag and push operations execute here
  - Microk8s cluster: Local registry at localhost:32000 receives images pushed from within VM
- **Deployment Flow**: Minimal change - only tag and push operations move to VM, build remains on host

## Specifications

docker-image-build-load/spec.md
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

microk8s-registry-integration/spec.md
# Microk8s Registry Integration

## Purpose

Capability for using microk8s's built-in local registry to distribute Docker images for Kubernetes deployment. This enables standard Docker push/pull workflow with Docker daemon and registry co-located within the VM, eliminating host-to-VM communication issues.

## ADDED Requirements

### Requirement: System must enable microk8s local registry
The deployment process SHALL enable microk8s's built-in registry add-on to provide a local, trusted registry for image distribution within the VM.

#### Scenario: Successful registry enablement
- **WHEN** deployment script executes `microk8s enable registry` command via multipass exec
- **AND** microk8s is installed and running in VM
- **THEN** script SHALL enable registry add-on
- **AND** script SHALL verify registry is running at localhost:32000 within VM
- **AND** script SHALL log successful enablement

#### Scenario: Registry enablement failure due to microk8s not running
- **WHEN** deployment script attempts to enable registry
- **AND** microk8s is not running in VM
- **THEN** script SHALL log clear error that microk8s is not available
- **AND** script SHALL provide instructions to start microk8s
- **AND** script SHALL exit with non-zero status code
- **AND** script SHALL NOT proceed with deployment

#### Scenario: Registry enablement failure due to port conflict
- **WHEN** deployment script attempts to enable registry
- **AND** port 32000 is already in use within VM
- **THEN** script SHALL log error about port conflict
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL exit with non-zero status code

#### Scenario: Registry is already enabled
- **WHEN** deployment script attempts to enable registry
- **AND** registry is already enabled and running
- **THEN** script SHALL verify registry is accessible
- **AND** script SHALL log that registry is already enabled
- **AND** script SHALL proceed with deployment

### Requirement: System must verify registry accessibility within VM
The deployment process SHALL verify that microk8s registry is accessible at localhost:32000 from within the VM before attempting push operations.

#### Scenario: Registry is accessible and ready
- **WHEN** deployment script checks registry status via multipass exec
- **AND** registry is enabled and running within VM
- **THEN** script SHALL confirm registry is accessible at localhost:32000 within VM
- **AND** script SHALL display registry status
- **AND** script SHALL proceed with push operations

#### Scenario: Registry is not accessible
- **WHEN** deployment script checks registry status via multipass exec
- **AND** registry is not accessible at localhost:32000 within VM
- **THEN** script SHALL log error that registry is unavailable
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL exit with non-zero status code
- **AND** script SHALL NOT attempt push operations

### Requirement: System must provide clear error messages for registry operations
The deployment process SHALL provide actionable error messages with specific recovery steps for each failure scenario in registry operations.

#### Scenario: Error message includes context
- **WHEN** any registry operation fails
- **THEN** script SHALL log error with specific failure reason
- **AND** script SHALL include relevant command that failed
- **AND** script SHALL include error output if available

#### Scenario: Error message includes recovery suggestions
- **WHEN** any registry operation fails
- **THEN** script SHALL provide specific recovery steps
- **AND** script SHALL suggest checking prerequisites (microk8s, Docker daemon in VM)
- **AND** script SHALL suggest retrying for transient failures
- **AND** script SHALL provide manual intervention steps if automated recovery fails

vm-docker-operations/spec.md
# VM Registry Push

## Purpose

Capability for pushing Docker images to microk8s registry from within the VM. This enables image distribution by executing tag and push operations where the registry is accessible at localhost:32000.

## ADDED Requirements

### Requirement: System must tag Docker images for local registry within VM
The deployment process SHALL tag Docker images with the local registry endpoint within the VM context to make them addressable for push operations to the microk8s registry.

#### Scenario: Successful image tagging within VM
- **WHEN** deployment script executes docker tag command via multipass exec
- **AND** source image exists in VM's Docker daemon
- **THEN** script SHALL tag image as `localhost:32000/my-ag-ui-app:latest` within the VM
- **AND** script SHALL verify tag was created successfully
- **AND** script SHALL log successful tagging

#### Scenario: Image tagging failure due to source image not found in VM
- **WHEN** deployment script attempts to tag image
- **AND** source image does not exist in VM's Docker daemon
- **THEN** script SHALL log error that source image is not available in VM
- **AND** script SHALL provide instructions to build image first
- **AND** script SHALL exit with non-zero status code

### Requirement: System must push images to microk8s registry from within VM
The deployment process SHALL push tagged Docker images to microk8s local registry using standard Docker push commands executed from within the VM, where localhost:32000 resolves to the registry.

#### Scenario: Successful image push to registry from VM
- **WHEN** deployment script executes docker push command via multipass exec
- **AND** image is tagged for local registry within the VM
- **AND** registry is accessible at localhost:32000 within the VM
- **THEN** script SHALL push image to registry
- **AND** script SHALL verify push completed successfully
- **AND** script SHALL log successful push with image details

#### Scenario: Image push failure due to registry not accessible in VM
- **WHEN** deployment script attempts to push image
- **AND** registry is not accessible at localhost:32000 within the VM
- **THEN** script SHALL log error that registry is not available in VM
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL exit with non-zero status code

#### Scenario: Image push failure due to network issues
- **WHEN** deployment script attempts to push image
- **AND** transient network issues occur within the VM
- **THEN** script SHALL implement retry logic with exponential backoff
- **AND** script SHALL log retry attempts
- **AND** script SHALL succeed if push succeeds within retry limit
- **AND** script SHALL fail with clear error if all retries exhausted

### Requirement: System must verify registry accessibility within VM
The deployment process SHALL verify that microk8s registry is accessible at localhost:32000 from within the VM before attempting push operations.

#### Scenario: Registry is accessible and ready
- **WHEN** deployment script checks registry status via multipass exec
- **AND** registry is enabled and running within the VM
- **THEN** script SHALL confirm registry is accessible at localhost:32000 within the VM
- **AND** script SHALL display registry status
- **AND** script SHALL proceed with push operations

#### Scenario: Registry is not accessible
- **WHEN** deployment script checks registry status via multipass exec
- **AND** registry is not accessible at localhost:32000 within the VM
- **THEN** script SHALL log error that registry is unavailable
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL exit with non-zero status code
- **AND** script SHALL NOT attempt push operations

### Requirement: System must provide clear error messages for registry operations
The deployment process SHALL provide actionable error messages with specific recovery steps for each failure scenario in registry push operations.

#### Scenario: Error message includes context
- **WHEN** any registry operation fails
- **THEN** script SHALL log error with specific failure reason
- **AND** script SHALL include relevant command that failed
- **AND** script SHALL include error output if available

#### Scenario: Error message includes recovery suggestions
- **WHEN** any registry operation fails
- **THEN** script SHALL provide specific recovery steps
- **AND** script SHALL suggest checking prerequisites (microk8s, Docker daemon in VM)
- **AND** script SHALL suggest retrying for transient failures
- **AND** script SHALL provide manual intervention steps if automated recovery fails



## Design

# Design: Fix Docker Push to VM Registry

## Context

### Current State

The deployment script ([`deploy.sh`](deploy.sh)) currently executes Docker operations on the host system:
1. Validates package.json/package-lock.json synchronization on host
2. Builds Docker image on host Docker daemon
3. Tags image for local registry (localhost:32000/my-ag-ui-app:latest)
4. Attempts to push image to microk8s registry
5. Fails with "connection refused" because host Docker tries to connect to host's localhost:32000, but registry runs inside VM at VM's localhost:32000

The microk8s registry is successfully enabled and running inside the multipass VM (my-ag-ui-app-k8s) at localhost:32000, but it's inaccessible from the host system's Docker daemon.

### Constraints

- Docker must be installed and running within the multipass VM (already present)
- Microk8s must be running in the VM with registry add-on enabled
- Project files must be available inside the VM for Docker build
- Deployment script must maintain existing validation and error handling patterns
- All Docker operations must execute within VM context where registry is accessible

### Stakeholders

- Development team: Needs reliable automated deployment to Kubernetes
- Operations team: Requires maintainable deployment process with clear error messages
- End users: Depend on successful application deployment for feature access

## Goals / Non-Goals

**Goals:**

- Execute all Docker build, tag, and push operations within the multipass VM where microk8s registry is accessible
- Eliminate host-to-VM image transfer complexity by building images directly in VM
- Maintain existing dependency validation and error handling patterns
- Provide clear error messages for VM Docker operations
- Simplify deployment flow by co-locating Docker daemon and registry

**Non-Goals:**

- Changing Kubernetes deployment manifests (already correct)
- Modifying microk8s configuration beyond registry enablement
- Implementing alternative image distribution methods (e.g., external registry)
- Changing application code or Dockerfile

## Decisions

### Decision 1: Execute Docker operations within VM via multipass exec

**Rationale:**
- Docker daemon and microk8s registry co-exist within VM, eliminating network communication issues
- `localhost:32000` resolves correctly to registry when commands execute in VM context
- Simplifies deployment by removing host-to-VM image transfer logic
- Leverages existing multipass infrastructure for VM command execution

**Alternatives Considered:**
1. **Port forwarding from host to VM**: Would require configuring multipass to forward host port 32000 to VM port 32000. Rejected due to complexity and potential port conflicts on host.
2. **Use VM IP address for registry**: Would require obtaining VM IP dynamically and updating image tags. Rejected due to added complexity and potential IP changes.
3. **External registry**: Would require setting up and maintaining external registry service. Rejected due to additional infrastructure and operational overhead.

### Decision 2: Transfer project files to VM before Docker build

**Rationale:**
- Docker build requires access to project files (Dockerfile, source code, dependencies)
- Multipass provides `multipass transfer` command for file transfer
- Enables building images entirely within VM context
- Maintains separation between host and VM environments

**Alternatives Considered:**
1. **Shared directory mount**: Would require configuring multipass with shared filesystem. Rejected due to multipass limitations and complexity.
2. **Build on host, transfer image**: Would require docker save/load operations which we're eliminating. Rejected as it doesn't solve the core problem.

### Decision 3: Maintain dependency validation on host before VM operations

**Rationale:**
- Dependency validation (package.json/package-lock.json sync) doesn't require Docker
- Fails fast before expensive VM operations
- Provides clear error messages for dependency issues
- Maintains existing validation patterns

**Alternatives Considered:**
1. **Move validation to VM**: Would require transferring package files to VM first. Rejected due to unnecessary complexity and slower feedback loop.

### Decision 4: Use exponential backoff for transient failures

**Rationale:**
- Network operations (image push) can experience transient failures
- Provides automatic recovery without manual intervention
- Follows industry best practices for retry logic
- Maintains deployment reliability

**Alternatives Considered:**
1. **Single attempt with manual retry**: Would require user intervention for transient issues. Rejected due to poor user experience.
2. **Fixed delay retries**: Less effective than exponential backoff for network issues. Rejected due to suboptimal recovery behavior.

## Risks / Trade-offs

### Risk 1: File transfer time increases deployment duration

**Impact:** Transferring project files to VM before each deployment adds time to deployment process.

**Mitigation:**
- Only transfer files that have changed (using rsync or similar)
- Cache frequently transferred files in VM
- Monitor transfer time and optimize if it becomes significant bottleneck

### Risk 2: VM disk space exhaustion from repeated builds

**Impact:** Docker images and build artifacts consume disk space in VM with each deployment.

**Mitigation:**
- Implement Docker image cleanup after successful deployments
- Monitor VM disk space and alert before exhaustion
- Document disk space requirements and cleanup procedures

### Risk 3: Docker daemon startup issues in VM

**Impact:** If Docker daemon fails to start in VM, all deployments will fail.

**Mitigation:**
- Add pre-flight check for Docker daemon availability
- Provide clear error messages with recovery instructions
- Consider automatic Docker daemon restart on failure
- Document Docker daemon troubleshooting steps

### Risk 4: Network connectivity issues between host and VM

**Impact:** Multipass exec/transfer commands may fail due to network issues.

**Mitigation:**
- Implement retry logic for multipass commands
- Provide clear error messages for network failures
- Document network troubleshooting steps
- Consider health checks for VM connectivity

### Trade-off: Increased deployment complexity vs. simplified registry access

**Trade-off:** Moving Docker operations to VM increases deployment script complexity (file transfer, VM command execution) but simplifies registry access by co-locating Docker and registry.

**Decision:** Accept increased complexity as it solves the core problem and provides more reliable deployments. The complexity is manageable and well-documented.

## Migration Plan

### Deployment Steps

1. **Update deployment script** ([`deploy.sh`](deploy.sh)):
   - Add function to transfer project files to VM using `multipass transfer`
   - Modify Docker build command to execute via `multipass exec`
   - Update image tag command to execute within VM
   - Modify image push command to execute within VM
   - Remove docker save/load logic (no longer needed)
   - Add Docker daemon availability check in VM
   - Update error messages for VM context

2. **Test deployment flow**:
   - Verify project files transfer correctly
   - Confirm Docker build executes successfully in VM
   - Validate image push to registry succeeds
   - Ensure Kubernetes deployment uses pushed image
   - Test error handling for various failure scenarios

3. **Update documentation**:
   - Document new deployment workflow
   - Update troubleshooting guide with VM-specific issues
   - Add VM disk space management procedures
   - Document Docker daemon management in VM

### Rollback Strategy

If deployment fails or issues arise:

1. **Immediate rollback**: Revert [`deploy.sh`](deploy.sh) to previous version using git
2. **Clean up VM**: Remove any transferred files or Docker images created during failed deployment
3. **Restore previous deployment**: Use existing deployment script to redeploy previous version
4. **Document issues**: Capture failure details for analysis and improvement

Rollback is straightforward as changes are isolated to deployment script and don't affect running application or Kubernetes configuration.

## Open Questions

1. **File transfer optimization**: Should we implement incremental file transfer (rsync) or full transfer each time?
   - **Decision point**: Evaluate transfer time after initial implementation
   - **Recommendation**: Start with full transfer, optimize if needed

2. **Docker image cleanup**: Should we automatically clean up old Docker images in VM after successful deployments?
   - **Decision point**: Monitor disk space usage over multiple deployments
   - **Recommendation**: Implement cleanup if disk space becomes concern

3. **VM resource requirements**: What are the minimum CPU/memory requirements for VM to handle Docker builds efficiently?
   - **Decision point**: Measure resource usage during initial deployments
   - **Recommendation**: Document requirements based on empirical data

4. **Concurrent deployments**: Can multiple deployments run simultaneously without conflicts?
   - **Decision point**: Test concurrent deployment scenarios
   - **Recommendation**: Add locking mechanism if conflicts are detected

## Current Task Context

## Current Task
- 1.1 Review current deployment script to locate image tag and push operations
