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
