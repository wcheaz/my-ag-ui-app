## Why

The deployment process fails when attempting to load Docker images into the multipass VM because Docker is not installed or the Docker daemon is not running in the VM. The error "bash: line 1: docker: command not found" indicates the Docker CLI is unavailable, and "Docker daemon in VM: not running" confirms the daemon is not operational. This prevents the image load step from completing, causing the entire deployment to fail with error code 124.

Additionally, even after Docker is set up in the VM, the image loading process may fail silently, resulting in the image not being available in the VM's Docker images. This manifests as "Docker image verification in VM failed" with error code 124, suggesting the image load command is not completing successfully despite Docker being operational.

**Investigation Finding:** Debugging revealed that multipass transfer fails with error: `[sftp] cannot access /tmp/docker-image-load-364049/my-ag-ui-app-latest.tar: No such file or directory`. This indicates the `docker save` command is not creating the file in the expected location or the file path is incorrect, causing the image transfer to fail.

**Additional Syntax Error:** The deploy.sh script has a bash syntax error on line 1229: `local: can only be used in a function`. The `local` keyword is being used multiple times outside of function definitions, which is not valid in bash. This prevents the script from executing at all and must be fixed before any other implementation work.

## What Changes

- Fix existing syntax errors in deploy.sh that prevent script execution (line 408: `start_total_deployment_timing: command not found`, line 2594: syntax error near `}`)
- Fix `local: can only be used in a function` error on line 1229 - identify and fix all instances of `local` keyword used outside of functions
- Add Docker installation and daemon startup verification in the multipass VM before attempting image load operations
- Implement automatic Docker installation in the VM if not present
- Add Docker daemon health checks in the VM before proceeding with image loading
- Debug and fix silent image loading failures - ensure image is successfully transferred to VM
- Fix file path issue: `docker save` output file not found at `/tmp/docker-image-load-*/my-ag-ui-app-latest.tar`
- Add explicit file existence check after `docker save` before attempting multipass transfer
- Log exact file path and permissions after `docker save` completes
- Test alternative file locations (e.g., `/tmp/` without subdirectory, current working directory)
- Verify multipass transfer can access the file from the host system
- Add comprehensive logging and error checking for image load operations
- Implement image load verification with detailed error reporting and recovery steps
- Enhance error messages to provide specific recovery steps when Docker is unavailable in the VM or image loading fails
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
