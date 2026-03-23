# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

## Why

The deployment process fails when attempting to load Docker images into the multipass VM because Docker is not installed or the Docker daemon is not running in the VM. The error "bash: line 1: docker: command not found" indicates the Docker CLI is unavailable, and "Docker daemon in VM: not running" confirms the daemon is not operational. This prevents the image load step from completing, causing the entire deployment to fail with error code 124.

## What Changes

- Fix existing syntax errors in deploy.sh that prevent script execution (line 408: `start_total_deployment_timing: command not found`, line 2594: syntax error near `}`)
- Add Docker installation and daemon startup verification in the multipass VM before attempting image load operations
- Implement automatic Docker installation in the VM if not present
- Add Docker daemon health checks in the VM before proceeding with image loading
- Enhance error messages to provide specific recovery steps when Docker is unavailable in the VM
- Update the deployment script to wait for Docker daemon to be ready before loading images

## Capabilities

### New Capabilities
- `vm-docker-setup`: Capability for installing, configuring, and verifying Docker daemon availability in multipass VMs. This ensures Docker is properly installed and running before attempting to load images into the VM's Docker daemon.

### Modified Capabilities
- `docker-image-build-load`: Add dependency on `vm-docker-setup` to ensure Docker is available in the VM before attempting image load operations. The image load step will now verify Docker daemon availability in the VM before proceeding.

## Impact

- **deploy.sh**: Will need modifications to check for Docker in the VM, install it if missing, start the daemon, and verify it's operational before image loading
- **Deployment flow**: Adds a new pre-image-load step for VM Docker setup, increasing deployment time slightly but ensuring reliability
- **Error handling**: Improved error messages and recovery guidance when Docker is unavailable in the VM
- **Dependencies**: No new external dependencies; uses standard Docker installation methods for Ubuntu (multipass VMs typically run Ubuntu)
- **Testing**: Will require testing in fresh VM environments to ensure Docker installation works correctly

## Specifications

docker-image-build-load/spec.md
# Docker Image Build and Load (Delta)

## MODIFIED Requirements

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

vm-docker-setup/spec.md
# VM Docker Setup

## Purpose

Capability for installing, configuring, and verifying Docker daemon availability in multipass VMs. This ensures Docker is properly installed and running before attempting to load images into the VM's Docker daemon.

## Requirements

### Requirement: System must check for Docker installation in VM
The system SHALL check if Docker is already installed in the multipass VM before attempting installation.

#### Scenario: Docker is already installed
- **WHEN** the deployment script checks for Docker in the VM
- **AND** Docker CLI is available
- **THEN** the script SHALL skip Docker installation
- **AND** the script SHALL proceed to verify Docker daemon status
- **AND** the script SHALL log that Docker is already installed

#### Scenario: Docker is not installed
- **WHEN** the deployment script checks for Docker in the VM
- **AND** Docker CLI is not available
- **THEN** the script SHALL proceed with Docker installation
- **AND** the script SHALL log that Docker installation is required

#### Scenario: Docker check fails
- **WHEN** the deployment script cannot determine Docker installation status
- **THEN** the script SHALL log the error with context
- **AND** the script SHALL assume Docker is not installed
- **AND** the script SHALL proceed with Docker installation

### Requirement: System must install Docker in VM if not present
The system SHALL install Docker in the multipass VM using Docker's official installation script for Ubuntu.

#### Scenario: Successful Docker installation
- **WHEN** the deployment script executes the Docker installation command
- **AND** the VM has network connectivity
- **AND** the VM has sufficient disk space
- **THEN** Docker packages SHALL be installed successfully
- **AND** Docker daemon SHALL be started automatically
- **AND** the script SHALL log the successful installation
- **AND** the script SHALL log the Docker version installed

#### Scenario: Docker installation fails due to network issues
- **WHEN** the deployment script attempts to install Docker
- **AND** the VM cannot reach Docker's installation servers
- **THEN** the script SHALL log a clear network error message
- **AND** the script SHALL provide manual installation instructions
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

#### Scenario: Docker installation fails due to insufficient disk space
- **WHEN** the deployment script attempts to install Docker
- **AND** the VM has insufficient disk space
- **THEN** the script SHALL log a disk space error message
- **AND** the script SHALL report the available and required space
- **THEN** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

#### Scenario: Docker installation fails with unknown error
- **WHEN** the deployment script attempts to install Docker
- **AND** the installation fails with an unexpected error
- **THEN** the script SHALL log the error with full context
- **AND** the script SHALL provide diagnostic information
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

### Requirement: System must add VM user to docker group
The system SHALL add the default VM user to the docker group to enable Docker commands without sudo.

#### Scenario: User successfully added to docker group
- **WHEN** the deployment script adds the user to the docker group
- **THEN** the user SHALL be added to the docker group
- **AND** the script SHALL log the successful group addition
- **AND** the script SHALL activate the group membership

#### Scenario: Group membership activation
- **WHEN** the deployment script activates the docker group membership
- **THEN** the user SHALL be able to run Docker commands without sudo
- **AND** the script SHALL verify group membership is active
- **AND** the script SHALL log that group membership is active

#### Scenario: Group addition fails
- **WHEN** the deployment script attempts to add the user to the docker group
- **AND** the group addition fails
- **THEN** the script SHALL log the error with context
- **AND** the script SHALL provide manual group addition instructions
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

### Requirement: System must verify Docker daemon is running
The system SHALL verify that the Docker daemon is running and ready to accept commands before proceeding with image loading.

#### Scenario: Docker daemon is running
- **WHEN** the deployment script checks Docker daemon status
- **AND** the Docker daemon is running
- **THEN** the script SHALL confirm daemon is operational
- **AND** the script SHALL log that Docker daemon is running
- **AND** the script SHALL proceed with image loading

#### Scenario: Docker daemon is not running
- **WHEN** the deployment script checks Docker daemon status
- **AND** the Docker daemon is not running
- **THEN** the script SHALL attempt to start the Docker daemon
- **AND** the script SHALL wait for the daemon to become ready
- **AND** the script SHALL verify the daemon is operational

#### Scenario: Docker daemon fails to start
- **WHEN** the deployment script attempts to start the Docker daemon
- **AND** the daemon fails to start
- **THEN** the script SHALL log the error with context
- **AND** the script SHALL provide diagnostic information
- **AND** the script SHALL provide manual troubleshooting steps
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

#### Scenario: Docker daemon check times out
- **WHEN** the deployment script waits for Docker daemon to become ready
- **AND** the daemon does not become ready within the timeout period
- **THEN** the script SHALL log a timeout error
- **AND** the script SHALL report the timeout period
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

### Requirement: System must verify Docker commands work without sudo
The system SHALL verify that Docker commands can be executed without sudo privileges in the VM.

#### Scenario: Docker commands work without sudo
- **WHEN** the deployment script tests Docker commands
- **AND** the user has docker group membership
- **THEN** Docker commands SHALL execute successfully without sudo
- **AND** the script SHALL log that Docker commands work without sudo
- **AND** the script SHALL proceed with image loading

#### Scenario: Docker commands require sudo
- **WHEN** the deployment script tests Docker commands
- **AND** Docker commands fail without sudo
- **THEN** the script SHALL attempt to fix the group membership issue
- **AND** the script SHALL verify the fix was successful
- **AND** the script SHALL log the resolution

#### Scenario: Docker commands fail with or without sudo
- **WHEN** the deployment script tests Docker commands
- **AND** Docker commands fail even with sudo
- **THEN** the script SHALL log a critical error
- **AND** the script SHALL provide diagnostic information
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

### Requirement: System must wait for Docker daemon to be ready after installation
The system SHALL wait for the Docker daemon to be fully initialized and ready to accept commands after installation.

#### Scenario: Docker daemon becomes ready within timeout
- **WHEN** the deployment script waits for Docker daemon to be ready
- **AND** the daemon becomes ready within the timeout period
- **THEN** the script SHALL proceed with image loading
- **AND** the script SHALL log that Docker daemon is ready
- **AND** the script SHALL report the time taken for daemon to be ready

#### Scenario: Docker daemon readiness check uses exponential backoff
- **WHEN** the deployment script polls for Docker daemon readiness
- **THEN** the script SHALL use exponential backoff between checks
- **AND** the script SHALL log each readiness check attempt
- **AND** the script SHALL not overwhelm the system with frequent checks

#### Scenario: Docker daemon readiness check exceeds maximum attempts
- **WHEN** the deployment script polls for Docker daemon readiness
- **AND** the daemon does not become ready after maximum attempts
- **THEN** the script SHALL log a timeout error
- **AND** the script SHALL report the number of attempts made
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

### Requirement: System must provide comprehensive error messages and recovery guidance
The system SHALL provide clear, actionable error messages and recovery steps when Docker setup fails.

#### Scenario: Network connectivity error
- **WHEN** Docker installation fails due to network issues
- **THEN** the script SHALL provide a clear error message
- **AND** the script SHALL explain the network connectivity requirement
- **AND** the script SHALL suggest checking VM network configuration
- **AND** the script SHALL provide manual installation commands

#### Scenario: Permission error
- **WHEN** Docker setup fails due to permission issues
- **THEN** the script SHALL provide a clear error message
- **AND** the script SHALL explain the permission requirement
- **AND** the script SHALL suggest checking user permissions
- **AND** the script SHALL provide manual permission fix commands

#### Scenario: Disk space error
- **WHEN** Docker installation fails due to insufficient disk space
- **THEN** the script SHALL provide a clear error message
- **AND** the script SHALL report available and required space
- **AND** the script SHALL suggest cleaning up disk space
- **AND** the script SHALL provide commands to check disk usage

#### Scenario: Generic error with diagnostic information
- **WHEN** Docker setup fails with an unknown error
- **THEN** the script SHALL log the full error output
- **AND** the script SHALL provide system diagnostic information
- **AND** the script SHALL suggest manual troubleshooting steps
- **AND** the script SHALL provide a way to access the VM for manual intervention

### Requirement: System must log Docker setup progress
The system SHALL log each step of the Docker setup process to provide visibility into the installation progress.

#### Scenario: Logging Docker check
- **WHEN** the deployment script checks for Docker installation
- **THEN** the script SHALL log the check operation
- **AND** the script SHALL log the result (found/not found)
- **AND** the script SHALL include a timestamp

#### Scenario: Logging Docker installation
- **WHEN** the deployment script installs Docker
- **THEN** the script SHALL log the installation start
- **AND** the script SHALL log installation progress
- **AND** the script SHALL log the installation completion
- **AND** the script SHALL log the Docker version installed

#### Scenario: Logging Docker daemon verification
- **WHEN** the deployment script verifies Docker daemon status
- **THEN** the script SHALL log the verification attempt
- **AND** the script SHALL log the daemon status
- **AND** the script SHALL log any issues encountered

#### Scenario: Logging group membership setup
- **WHEN** the deployment script sets up docker group membership
- **THEN** the script SHALL log the group addition attempt
- **AND** the script SHALL log the activation attempt
- **AND** the script SHALL log the final status

### Requirement: System must integrate with existing deployment flow
The system SHALL integrate Docker setup into the existing deployment flow at the appropriate point.

#### Scenario: Docker setup occurs after VM provisioning
- **WHEN** the deployment script completes VM provisioning
- **THEN** the script SHALL call Docker setup function
- **AND** the script SHALL wait for Docker setup to complete
- **AND** the script SHALL proceed to next deployment phase

#### Scenario: Docker setup occurs before image loading
- **WHEN** the deployment script is about to load Docker images
- **THEN** Docker setup SHALL already be complete
- **AND** Docker daemon SHALL be verified as running
- **AND** the script SHALL proceed with image loading

#### Scenario: Docker setup failure stops deployment
- **WHEN** Docker setup fails
- **THEN** the deployment script SHALL stop
- **AND** the script SHALL NOT attempt image loading
- **AND** the script SHALL NOT proceed with Kubernetes deployment
- **AND** the script SHALL exit with a non-zero status code



## Design

## Context

The current deployment process builds Docker images on the host system and attempts to load them into the multipass VM's Docker daemon using `multipass exec <vm-name> -- docker load`. However, this fails because Docker is not installed or the Docker daemon is not running in the VM. The error manifests as "bash: line 1: docker: command not found" followed by "Docker daemon in VM: not running".

Additionally, the deployment script ([`deploy.sh`](deploy.sh)) has existing syntax errors that prevent it from executing at all:
- Line 408: `start_total_deployment_timing: command not found`
- Line 2594: syntax error near unexpected token `}`

These syntax errors must be fixed before implementing the Docker setup functionality.

The deployment script currently assumes Docker is pre-installed and running in the VM, which is not a valid assumption for freshly provisioned multipass VMs. Multipass VMs typically run Ubuntu but do not include Docker by default.

## Goals / Non-Goals

**Goals:**
- Ensure Docker is installed in the multipass VM before attempting image load operations
- Verify the Docker daemon is running and ready to accept commands
- Provide clear error messages and recovery guidance if Docker installation fails
- Minimize deployment time impact by checking for existing Docker installation
- Support both fresh VMs and VMs that may already have Docker installed

**Non-Goals:**
- Installing Docker in the host system (already handled by existing checks)
- Configuring Docker registries or authentication in the VM
- Setting up Docker Compose or other Docker orchestration tools
- Modifying the Kubernetes deployment process beyond image loading
- Supporting Docker on non-Ubuntu VMs (multipass defaults to Ubuntu)

## Decisions

### Decision 1: Use Docker's official installation script for Ubuntu

**Rationale:** Docker provides an official installation script (`get.docker.com`) that is maintained, tested, and handles dependency resolution automatically. This is more reliable than manually installing packages and ensures we get the latest stable version.

**Alternatives Considered:**
- Manual apt installation: More complex, requires manual repository setup and key management
- Snap installation: Simpler but may have permission issues and slower startup times
- Pre-baked VM image: Would require maintaining custom VM images, increasing complexity

### Decision 2: Check for Docker before attempting installation

**Rationale:** To minimize deployment time, we should first check if Docker is already installed and running in the VM. This is important for scenarios where the VM may already be configured or when re-running deployments.

**Implementation:** Use `multipass exec <vm-name> -- docker --version` to check if Docker CLI is available, then verify the daemon is running with `multipass exec <vm-name> -- docker info`.

### Decision 3: Add user to docker group during installation

**Rationale:** The default user in multipass VMs (typically `ubuntu`) needs to be added to the docker group to run Docker commands without sudo. This is required for the `docker load` command to work properly.

**Implementation:** After Docker installation, run `sudo usermod -aG docker ubuntu` and create a new shell session or use `newgrp docker` to activate the group membership.

### Decision 4: Wait for Docker daemon to be ready

**Rationale:** After installation, the Docker daemon may take a few seconds to start. We need to wait and verify it's ready before proceeding with image loading to avoid race conditions.

**Implementation:** Use a retry loop with `multipass exec <vm-name> -- docker info` to check daemon readiness, with a reasonable timeout (e.g., 30 seconds) and exponential backoff.

### Decision 5: Implement comprehensive error handling

**Rationale:** Docker installation can fail for various reasons (network issues, package conflicts, insufficient disk space). We need to provide clear error messages and recovery guidance.

**Implementation:** Check exit codes at each step, log specific error messages, and provide actionable recovery steps (e.g., "Run 'multipass shell <vm-name>' and manually install Docker").

### Decision 6: Add Docker setup as a separate deployment phase

**Rationale:** Docker setup should occur after VM provisioning but before image loading. This creates a clear separation of concerns and makes the deployment flow easier to understand and debug.

**Implementation:** Add a new function `setup_vm_docker()` in [`deploy.sh`](deploy.sh) that is called after VM creation and before image loading.

## Risks / Trade-offs

### Risk 1: Network connectivity required for Docker installation
**Risk:** The Docker installation script requires internet access to download packages. If the VM has network issues, installation will fail.

**Mitigation:** Check network connectivity before attempting installation, provide clear error messages if network is unavailable, and document manual installation steps as a fallback.

### Risk 2: Increased deployment time
**Risk:** Docker installation adds 1-3 minutes to deployment time for fresh VMs.

**Mitigation:** Check for existing Docker installation first to skip unnecessary steps. The time impact is acceptable given the reliability improvement.

### Risk 3: Docker version compatibility issues
**Risk:** Installing the latest Docker version may introduce compatibility issues with existing deployment scripts or Kubernetes configurations.

**Mitigation:** Test with the latest stable Docker version, document the version used, and pin to a specific version if issues arise.

### Risk 4: Disk space requirements
**Risk:** Docker installation requires additional disk space (~500MB for packages, more for images).

**Mitigation:** Verify VM has sufficient disk space before installation (already done in VM provisioning), provide clear error if space is insufficient.

### Risk 5: Permission issues with docker group
**Risk:** Adding the user to the docker group may not take effect immediately, requiring a new shell session.

**Mitigation:** Use `newgrp docker` or create a new shell session to activate group membership, or run Docker commands with sudo as a fallback.

### Risk 6: Docker daemon startup failures
**Risk:** The Docker daemon may fail to start due to configuration issues or resource constraints.

**Mitigation:** Check daemon status with `docker info`, provide detailed error logs, and suggest manual troubleshooting steps.

## Migration Plan

### Deployment Steps

0. Fix existing syntax errors in [`deploy.sh`](deploy.sh):
   - Investigate and fix `start_total_deployment_timing: command not found` error on line 408
   - Investigate and fix syntax error near unexpected token `}` on line 2594
   - Verify deploy.sh has no syntax errors by running `bash -n deploy.sh`
   - Test that deploy.sh can be executed without immediate syntax errors

1. Add the `setup_vm_docker()` function to [`deploy.sh`](deploy.sh) that:
   - Checks if Docker is already installed
   - Installs Docker using the official script if not present
   - Adds the default user to the docker group
   - Starts the Docker daemon
   - Verifies Docker is operational

2. Integrate `setup_vm_docker()` into the deployment flow:
   - Call after VM provisioning is complete
   - Call before Docker image loading

3. Add error handling and logging:
   - Log each step of Docker setup
   - Provide clear error messages on failure
   - Include recovery suggestions

4. Test the deployment:
   - Test with a fresh VM (no Docker installed)
   - Test with an existing VM (Docker already installed)
   - Test with network issues
   - Test with insufficient disk space

### Rollback Strategy

If issues arise after deployment:

1. **Quick rollback:** Comment out the `setup_vm_docker()` call in [`deploy.sh`](deploy.sh) and manually install Docker in the VM using `multipass shell <vm-name>`.

2. **Version rollback:** Revert to the previous version of [`deploy.sh`](deploy.sh) that doesn't include Docker setup.

3. **Manual recovery:** If Docker installation fails mid-process, manually complete the installation using the provided error messages and recovery steps.

### Verification

After deployment, verify:
- Docker is installed in the VM: `multipass exec <vm-name> -- docker --version`
- Docker daemon is running: `multipass exec <vm-name> -- docker info`
- User can run Docker commands without sudo: `multipass exec <vm-name> -- docker ps`
- Image loading works: Run the full deployment and verify the image is loaded successfully

## Open Questions

1. **Docker version pinning:** Should we pin to a specific Docker version or always use the latest stable? (Recommendation: Use latest stable for now, pin if issues arise)

2. **Docker Compose:** Should we also install Docker Compose in the VM? (Recommendation: No, out of scope for this change)

3. **Docker daemon configuration:** Should we configure any Docker daemon settings (e.g., log rotation, storage driver)? (Recommendation: No, use defaults unless issues arise)

4. **Cleanup on VM deletion:** Should we clean up Docker data when the VM is deleted? (Recommendation: No, multipass handles VM cleanup)

5. **Alternative container runtimes:** Should we consider supporting containerd or other runtimes? (Recommendation: No, Docker is the standard and Kubernetes supports it well)

## Current Task Context

## Current Task
- 0.4 Test that deploy.sh can be executed without immediate syntax errors
## Completed Tasks for Git Commit
- [x] 0.1 Investigate and fix `start_total_deployment_timing: command not found` error on line 408 of deploy.sh
- [x] 0.2 Investigate and fix syntax error near unexpected token `}` on line 2594 of deploy.sh
- [x] 0.3 Verify deploy.sh has no syntax errors by running `bash -n deploy.sh`
- [x] 1.1 Create `setup_vm_docker()` function in deploy.sh with function signature and basic structure
- [x] 1.2 Implement Docker CLI availability check using `multipass exec <vm-name> -- docker --version`
- [x] 1.3 Implement Docker daemon status check using `multipass exec <vm-name> -- docker info`
- [x] 1.4 Implement Docker installation using official script `curl -fsSL https://get.docker.com | sh`
- [x] 1.5 Implement user addition to docker group using `sudo usermod -aG docker ubuntu`
- [x] 1.6 Implement Docker daemon startup verification with retry loop and exponential backoff
- [x] 1.7 Implement Docker command verification without sudo using `docker ps`
- [x] 2.1 Add comprehensive error handling for Docker CLI check failures
- [x] 2.2 Add comprehensive error handling for Docker installation failures (network, disk space, unknown errors)
- [x] 2.3 Add comprehensive error handling for Docker daemon startup failures
- [x] 2.4 Add comprehensive error handling for docker group membership failures
- [x] 2.5 Implement logging for each Docker setup step with timestamps
- [x] 2.6 Add specific error messages and recovery guidance for each failure scenario
- [x] 2.7 Add diagnostic information output for debugging purposes
- [x] 3.1 Identify the correct location in deploy.sh to call `setup_vm_docker()` (after VM provisioning, before image loading)
- [x] 3.2 Add function call to `setup_vm_docker()` in the deployment flow
- [x] 3.3 Ensure proper error propagation from `setup_vm_docker()` to stop deployment on failure
- [x] 3.4 Update deployment script to exit with non-zero status when Docker setup fails
- [x] 3.5 Verify that deployment stops correctly and does not proceed to image loading when Docker setup fails
- [x] 4.1 Test Docker setup with fresh VM (no Docker installed)
- [x] 4.2 Test Docker setup with existing VM (Docker already installed and running)
- [x] 4.3 Test Docker setup with VM that has Docker installed but daemon not running
- [x] 4.4 Test error handling when VM has no network connectivity
- [x] 4.5 Test error handling when VM has insufficient disk space
- [x] 4.6 Test full deployment flow end-to-end with Docker setup
- [x] 4.7 Verify image loading works correctly after Docker setup
- [x] 4.8 Verify Kubernetes deployment proceeds successfully after image loading
- [x] 5.1 Add inline comments explaining each step of Docker setup
- [x] 5.2 Document Docker setup requirements in deployment documentation
- [x] 5.3 Document troubleshooting steps for common Docker setup issues
- [x] 5.4 Update README.md with Docker setup information if needed
- [x] 5.5 Review and clean up any temporary or debugging code
- [x] 5.6 Verify all error messages are clear and actionable
- [x] 6.1 Handle case where Docker installation script is not accessible
- [x] 6.2 Handle case where Docker daemon takes longer than expected to start
- [x] 6.3 Handle case where docker group membership doesn't activate immediately
- [x] 6.4 Add timeout handling for all Docker operations
- [x] 6.5 Handle case where VM is not accessible or multipass commands fail
- [x] 6.6 Verify idempotency - running setup multiple times should not cause issues
- [x] 7.1 Optimize Docker availability check to minimize execution time
- [x] 7.2 Implement caching or state tracking to avoid redundant checks
- [x] 7.3 Tune retry intervals and timeouts for optimal performance
- [x] 7.4 Measure and document performance impact on deployment time
