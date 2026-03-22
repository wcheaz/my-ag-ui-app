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
