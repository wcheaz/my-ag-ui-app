# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

## Why

The deployment script fails because Kubernetes YAML files are not being copied to the VM during the deployment process, preventing the application from being deployed to the microk8s cluster. Additionally, even after fixing the file transfer issue, the deployment fails with ImagePullBackOff because the Docker image is not built or loaded into the VM. Furthermore, the Docker build process fails due to insufficient permissions to access the Docker daemon socket. These are critical bugs that block the entire deployment workflow.

## What Changes

- Fix the deployment script to properly copy Kubernetes YAML files (secrets.yaml, deployment.yaml, service.yaml, ingress.yaml) from the host to the VM
- Ensure the k8s/ directory is created in the VM before copying files
- Add validation to verify files exist before attempting to apply them with kubectl
- Improve error handling and logging for file transfer operations
- Build the Docker image from the project's Dockerfile
- Load the Docker image into the multipass VM's Docker daemon
- Verify the pod can successfully start with the loaded image
- Fix Docker permissions issues to allow Docker build commands to execute
- Add Docker permissions checks and proper error handling for permission errors

## Capabilities

### New Capabilities
- `vm-file-transfer`: Capability for transferring files from host to VM during deployment, including directory creation and file validation
- `docker-image-build-load`: Capability for building Docker images and loading them into the multipass VM's Docker daemon
- `docker-permissions-check`: Capability for checking and fixing Docker daemon socket permissions to enable Docker build operations

### Modified Capabilities
- None (this is a bug fix, not a requirement change)

## Impact

- **Code**: The deploy.sh script will be modified to include proper file transfer logic
- **Deployment Workflow**: The deployment process will successfully transfer and apply Kubernetes manifests
- **Dependencies**: No new dependencies required - uses existing multipass and kubectl tools
- **Systems**: Affects the microk8s deployment on multipass VMs
- **Breaking Changes**: None - this is a bug fix that restores intended functionality

## Specifications

docker-image-build-load/spec.md
## ADDED Requirements

### Requirement: Docker image build
The deployment process SHALL build a Docker image from the project's Dockerfile.

#### Scenario: Successful image build
- **WHEN** the deployment script executes the docker build command
- **THEN** the script SHALL build an image named my-ag-ui-app:latest
- **AND** the script SHALL use the Dockerfile in the project root
- **AND** the script SHALL log the build progress

#### Scenario: Image build failure
- **WHEN** the docker build command fails
- **THEN** the script SHALL log the build error with context
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with deployment

### Requirement: Docker image load into VM
The deployment process SHALL load the built Docker image into the multipass VM's Docker daemon.

#### Scenario: Successful image load
- **WHEN** the deployment script executes the image load command
- **THEN** the script SHALL save the image using docker save
- **THEN** the script SHALL pipe the image to multipass exec with docker load
- **AND** the script SHALL verify the image is available in the VM
- **AND** the script SHALL log the successful load

#### Scenario: Image load failure
- **WHEN** the image load command fails
- **THEN** the script SHALL log the load error with context
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT attempt to restart the deployment

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

docker-permissions-check/spec.md
## ADDED Requirements

### Requirement: Docker daemon permissions check
The deployment script SHALL check if the current user has sufficient permissions to access the Docker daemon socket before attempting to build Docker images.

#### Scenario: User has Docker permissions
- **WHEN** the deployment script checks Docker permissions
- **THEN** the script SHALL verify the user can access /var/run/docker.sock
- **AND** the script SHALL proceed with the Docker build process
- **AND** the script SHALL log that Docker permissions are sufficient

#### Scenario: User lacks Docker permissions
- **WHEN** the deployment script detects insufficient Docker permissions
- **THEN** the script SHALL log a clear error message about the permission issue
- **AND** the script SHALL provide instructions to add the user to the docker group
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT attempt to build the Docker image

### Requirement: Docker daemon status check
The deployment script SHALL verify that the Docker daemon is running before attempting to build Docker images.

#### Scenario: Docker daemon is running
- **WHEN** the deployment script checks Docker daemon status
- **THEN** the script SHALL verify Docker daemon is active
- **AND** the script SHALL proceed with the Docker build process
- **AND** the script SHALL log that Docker daemon is running

#### Scenario: Docker daemon is not running
- **WHEN** the deployment script detects Docker daemon is not running
- **THEN** the script SHALL log a clear error message
- **AND** the script SHALL provide instructions to start the Docker daemon
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT attempt to build the Docker image

### Requirement: Docker build error handling
The deployment script SHALL properly catch and handle Docker build errors, including permission errors.

#### Scenario: Docker build succeeds
- **WHEN** the Docker build command completes successfully
- **THEN** the script SHALL log the successful build
- **AND** the script SHALL verify the image exists in local Docker images
- **AND** the script SHALL proceed with image loading

#### Scenario: Docker build fails with permission error
- **WHEN** the Docker build command fails with a permission error
- **THEN** the script SHALL log the specific permission error
- **AND** the script SHALL provide recovery instructions
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

#### Scenario: Docker build fails with other error
- **WHEN** the Docker build command fails with a non-permission error
- **THEN** the script SHALL log the build error with context
- **AND** the script SHALL provide diagnostic information
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

### Requirement: Docker permissions recovery guidance
The deployment script SHALL provide clear, actionable instructions when Docker permissions are insufficient.

#### Scenario: User not in docker group
- **WHEN** the user is not in the docker group
- **THEN** the script SHALL provide the command to add the user to the docker group
- **AND** the script SHALL inform the user they need to log out and back in
- **AND** the script SHALL provide alternative solutions (sudo, new terminal session)

#### Scenario: Docker daemon not running
- **WHEN** the Docker daemon is not running
- **THEN** the script SHALL provide the command to start the Docker daemon
- **AND** the script SHALL provide the command to enable Docker at startup
- **AND** the script SHALL suggest checking Docker service status

### Requirement: Docker build verification
The deployment script SHALL verify that the Docker image was successfully built before proceeding with image loading.

#### Scenario: Image exists after build
- **WHEN** the deployment script verifies the built image
- **THEN** the script SHALL confirm the image exists in local Docker images
- **AND** the script SHALL log the image details (name, tag, size)
- **AND** the script SHALL proceed with image loading

#### Scenario: Image does not exist after build
- **WHEN** the deployment script cannot find the expected image
- **THEN** the script SHALL log that the image is missing
- **AND** the script SHALL list available Docker images for debugging
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

vm-file-transfer/spec.md
## ADDED Requirements

### Requirement: VM directory creation
The deployment script SHALL create the target directory in the VM before attempting to copy files.

#### Scenario: Directory creation success
- **WHEN** the deployment script starts the file transfer process
- **THEN** the script SHALL create the k8s/ directory in the VM at /home/ubuntu/k8s/
- **AND** the script SHALL verify the directory exists before proceeding

#### Scenario: Directory already exists
- **WHEN** the deployment script attempts to create a directory that already exists
- **THEN** the script SHALL continue without error
- **AND** the script SHALL log that the directory already exists

### Requirement: File transfer from host to VM
The deployment script SHALL copy Kubernetes YAML files from the host system to the VM.

#### Scenario: Successful file transfer
- **WHEN** the deployment script executes the file transfer command
- **THEN** the script SHALL copy all required files (secrets.yaml, deployment.yaml, service.yaml, ingress.yaml) from the host k8s/ directory to the VM
- **AND** the script SHALL verify each file was successfully transferred

#### Scenario: File transfer failure
- **WHEN** the file transfer command fails for any reason
- **THEN** the script SHALL log a detailed error message
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT attempt to apply Kubernetes manifests

### Requirement: File validation
The deployment script SHALL validate that all required files exist in the VM before attempting to apply Kubernetes manifests.

#### Scenario: All files present
- **WHEN** the deployment script validates files after transfer
- **THEN** the script SHALL verify that secrets.yaml, deployment.yaml, service.yaml, and ingress.yaml all exist in /home/ubuntu/k8s/
- **AND** the script SHALL proceed to apply the manifests

#### Scenario: Missing file detected
- **WHEN** the deployment script detects a missing required file
- **THEN** the script SHALL log which file is missing
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT attempt to apply any Kubernetes manifests

### Requirement: Error handling and logging
The deployment script SHALL provide clear error messages and logging throughout the file transfer process.

#### Scenario: Successful transfer logging
- **WHEN** files are successfully transferred to the VM
- **THEN** the script SHALL log a success message with the number of files transferred
- **AND** the script SHALL log the destination path

#### Scenario: Error logging
- **WHEN** an error occurs during file transfer or validation
- **THEN** the script SHALL log the specific error with context (command, exit code, timestamp)
- **AND** the script SHALL provide actionable error messages to help diagnose the issue



## Design

## Context

The deployment script ([`deploy.sh`](deploy.sh:1)) attempts to apply Kubernetes manifests to a microk8s cluster running inside a multipass VM. The script fails for two reasons:

1. **File Transfer Issue**: Kubernetes YAML files (secrets.yaml, deployment.yaml, service.yaml, ingress.yaml) are never transferred from the host system to the VM before the script attempts to apply them.

2. **Image Pull Issue**: Even after fixing the file transfer, the pod fails with ImagePullBackOff because the Docker image is not built or loaded into the VM.

**Current State:**
- The script runs commands like `multipass exec "$VM_NAME" -- microk8s kubectl apply -f k8s/secrets.yaml` (line 128)
- These commands expect the files to exist at `/home/ubuntu/k8s/` inside the VM
- No file transfer logic exists in the script
- The k8s/ directory does not exist in the VM
- Result: "error: the path 'k8s/secrets.yaml' does not exist"
- After file transfer fix, pod shows ImagePullBackOff status
- The deployment.yaml references image `my-ag-ui-app:latest` which doesn't exist in any accessible registry
- The Docker image has not been built or loaded into the VM's Docker daemon
- Docker build fails with "permission denied" error when accessing Docker daemon socket
- Current user lacks permissions to access /var/run/docker.sock
- Docker daemon may not be running or accessible

**Constraints:**
- Must use existing tools: multipass, docker, and kubectl
- Must not introduce new dependencies
- Must maintain backward compatibility with existing deployment workflow
- Must provide clear error messages and logging

**Stakeholders:**
- Developers who need to deploy application to microk8s
- Operations team managing the deployment process

## Goals / Non-Goals

**Goals:**
- Transfer Kubernetes YAML files from host k8s/ directory to VM's /home/ubuntu/k8s/ directory
- Create the k8s/ directory in the VM before file transfer
- Validate that all required files exist in the VM before attempting to apply manifests
- Improve error handling and logging for file transfer operations
- Build the Docker image from the project's Dockerfile
- Load the Docker image into the multipass VM's Docker daemon
- Verify the pod can successfully start with the loaded image
- Ensure the deployment process succeeds end-to-end

**Non-Goals:**
- Modifying the Kubernetes manifest files themselves
- Changing the VM configuration or microk8s setup
- Implementing a new deployment mechanism
- Adding file synchronization or monitoring capabilities
- Setting up a container registry infrastructure

## Decisions

### 1. Use multipass transfer command for file copying

**Decision:** Use `multipass transfer` command to copy files from host to VM.

**Rationale:**
- multipass provides a built-in file transfer mechanism designed for this use case
- No need for additional tools or dependencies
- Simple and reliable for transferring individual files or directories
- Well-documented and supported

**Alternatives Considered:**
- **multipass exec with cat/tee**: More complex, error-prone for multiple files
- **SCP/SSH**: Requires SSH setup, adds complexity
- **Shared directory**: Requires VM reconfiguration, not always available

### 2. Create directory in VM before file transfer

**Decision:** Explicitly create the k8s/ directory in the VM before transferring files.

**Rationale:**
- Ensures the target directory exists before file transfer
- Prevents ambiguous error messages if directory doesn't exist
- Makes the deployment process more robust and predictable
- Allows for proper error handling if directory creation fails

**Alternatives Considered:**
- **Let multipass create it implicitly**: Less control over error handling
- **Transfer entire directory**: May transfer unwanted files

### 3. Validate files after transfer

**Decision:** Verify each required file exists in the VM after transfer before attempting to apply manifests.

**Rationale:**
- Catches transfer failures early
- Provides clear error messages about which files are missing
- Prevents cascading failures when kubectl can't find files
- Improves debugging and troubleshooting

**Alternatives Considered:**
- **Skip validation**: Would lead to confusing kubectl errors
- **Validate before transfer**: Doesn't catch transfer failures

### 4. Fail fast on file transfer errors

**Decision:** Exit immediately with a clear error message if file transfer or validation fails.

**Rationale:**
- Prevents wasting time on partial deployments
- Makes failures immediately obvious
- Provides actionable error messages
- Maintains script reliability

**Alternatives Considered:**
- **Continue with warnings**: Could lead to partial/broken deployments
- **Retry automatically**: Adds complexity, may mask underlying issues

### 5. Preserve existing logging structure

**Decision:** Use the existing [`log()`](deploy.sh:13) function for all new logging statements.

**Rationale:**
- Maintains consistency with existing code
- Ensures all messages are written to both stdout and log file
- Preserves timestamp formatting
- No need to modify existing logging infrastructure

**Alternatives Considered:**
- **Create new logging functions**: Unnecessary complexity
- **Use echo directly**: Would lose log file output

### 6. Build Docker image locally

**Decision:** Build the Docker image on the host machine using the project's Dockerfile.

**Rationale:**
- Leverages existing Docker infrastructure
- No need to set up a container registry
- Simple and straightforward for local development
- Image can be loaded directly into the VM

**Alternatives Considered:**
- **Build inside VM**: Requires transferring build context, slower
- **Use external registry**: Adds complexity, requires network access
- **Use microk8s local registry**: Requires additional configuration

### 7. Load image using docker save | multipass exec -- docker load

**Decision:** Use docker save to export the image and pipe it to multipass exec with docker load.

**Rationale:**
- Efficient transfer of Docker images without intermediate files
- Uses standard Docker commands that work reliably
- No need for additional tools or file system access
- Works well with multipass's exec capabilities

**Alternatives Considered:**
- **Save to file then transfer**: Requires intermediate storage, slower
- **Use multipass transfer**: Not optimized for Docker image format
- **Build directly in VM**: Requires transferring build context

### 8. Restart deployment to trigger pod recreation

**Decision:** Use kubectl rollout restart to trigger pod recreation with the new image.

**Rationale:**
- Standard Kubernetes approach for triggering pod updates
- Ensures the new pod uses the newly loaded image
- Maintains deployment configuration
- Allows for graceful pod termination and startup

**Alternatives Considered:**
- **Delete and recreate pod**: More disruptive, loses pod history
- **Update deployment image**: Requires modifying deployment.yaml
- **Scale down and up**: More complex, unnecessary

### 9. Check Docker permissions before build

**Decision:** Check Docker daemon permissions and status before attempting to build the Docker image.

**Rationale:**
- Prevents confusing permission errors during build
- Provides clear, actionable error messages early
- Saves time by failing fast on permission issues
- Helps users understand and fix the root cause

**Alternatives Considered:**
- **Attempt build and catch errors**: Less user-friendly, errors are confusing
- **Use sudo for build**: Security risk, not recommended for scripts
- **Skip permissions check**: Would lead to confusing error messages

### 10. Provide Docker permissions recovery instructions

**Decision:** Provide specific commands and instructions to fix Docker permissions when they are insufficient.

**Rationale:**
- Empowers users to fix the issue themselves
- Reduces support burden
- Provides immediate value without waiting for help
- Covers common scenarios (user not in docker group, daemon not running)

**Alternatives Considered:**
- **Generic error message**: Not helpful, users don't know what to do
- **Link to documentation**: Users may not follow links, want immediate help
- **Automatically fix permissions**: Too risky, could break system configuration

## Risks / Trade-offs

### Risk 1: File transfer may fail silently
**Risk:** `multipass transfer` may not properly report all failure modes.

**Mitigation:** Validate file existence after transfer using `multipass exec` with `test -f` command. Log detailed error messages including the transfer command and exit code.

### Risk 2: VM may not be running or accessible
**Risk:** The VM may not be in a state where file transfer is possible.

**Mitigation:** The existing script already checks VM status. Add explicit check before file transfer. Provide clear error message if VM is not accessible.

### Risk 3: Large files may cause timeout
**Risk:** If YAML files become very large, transfer may timeout.

**Mitigation:** Current files are small (<10KB). Monitor file sizes. Consider adding timeout configuration if files grow significantly in the future.

### Risk 4: Concurrent deployments may conflict
**Risk:** Multiple deployment runs may interfere with each other's file transfers.

**Mitigation:** Document that deployments should be run sequentially. Consider adding a lock mechanism if concurrent deployments become a requirement.

### Risk 5: Docker build may fail
**Risk:** The Docker build process may fail due to missing dependencies or build errors.

**Mitigation:** Provide clear error messages from Docker build. Document build prerequisites. Test build process before deployment.

### Risk 6: Image load may fail
**Risk:** The image load process may fail due to VM storage issues or Docker daemon problems.

**Mitigation:** Validate image exists in VM after load. Provide detailed error messages. Check VM disk space before load.

### Risk 7: Pod may still fail to start
**Risk:** Even with the correct image, the pod may fail due to application errors or misconfiguration.

**Mitigation:** Verify pod health checks pass. Provide pod logs for debugging. Implement proper readiness and liveness probes.

### Risk 8: Docker permissions issues
**Risk:** User may not have permissions to access Docker daemon, causing build failures.

**Mitigation:** Check permissions before attempting build. Provide clear recovery instructions. Suggest adding user to docker group or using sudo with appropriate warnings.

### Risk 9: Docker daemon not running
**Risk:** Docker daemon may not be running, causing all Docker operations to fail.

**Mitigation:** Check Docker daemon status before build. Provide instructions to start Docker daemon. Check if Docker service is enabled.

### Trade-off: Additional deployment time
**Trade-off:** File transfer and image build/load add time to the deployment process.

**Justification:** The transfer time is negligible for small YAML files (<1 second). Image build time is necessary for deployment. The benefit of a working deployment far outweighs this overhead.

### Trade-off: Increased script complexity
**Trade-off:** Adding file transfer and image build/load logic increases script complexity.

**Justification:** The complexity is necessary for the script to function correctly. The logic is straightforward and well-contained, making it maintainable.

## Migration Plan

### Deployment Steps

1. **Add file transfer section** before Kubernetes manifest application (after line 125)
   - Create k8s/ directory in VM
   - Transfer secrets.yaml, deployment.yaml, service.yaml, ingress.yaml
   - Validate all files exist in VM

2. **Add Docker image build section** before file transfer
   - Build Docker image using project Dockerfile
   - Verify image was built successfully
   - Log build progress

3. **Add Docker image load section** after file transfer, before manifest application
   - Save Docker image using docker save
   - Pipe to multipass exec with docker load
   - Verify image exists in VM

4. **Add deployment restart section** after manifest application
   - Use kubectl rollout restart to trigger pod recreation
   - Wait for new pod to be created
   - Verify pod status changes to Running

5. **Add Docker permissions check section** before Docker build
    - Check if user can access Docker daemon socket
    - Check if Docker daemon is running
    - Provide clear error messages if permissions are insufficient
    - Provide recovery instructions for common permission issues

6. **Update error handling** to include all new error types
    - Add new error codes for file transfer failures
    - Add new error codes for Docker build failures
    - Add new error codes for Docker load failures
    - Add new error codes for Docker permission failures
    - Provide specific recovery suggestions for each error type

6. **Test deployment** with the updated script
   - Verify files are transferred correctly
   - Verify image is built and loaded
   - Verify deployment succeeds end-to-end
   - Verify error messages are clear and actionable

### Rollback Strategy

If issues arise after deployment:

1. **Revert to previous version** of deploy.sh from version control
2. **Clean up VM** by removing transferred files and loaded image if necessary
3. **Document the issue** and investigate root cause

The rollback is straightforward because:
- No changes are made to VM configuration
- No changes are made to Kubernetes manifests
- Only the deployment script is modified
- The previous script version is preserved in version control

## Open Questions

None identified at this time. The design addresses the file transfer issue, image pull issue, and Docker permissions issue with clear, well-defined solutions.

## Current Task Context

## Current Task
- 7.1 Investigate Docker daemon socket permissions error
## Completed Tasks for Git Commit
- [x] 1.1 Add VM directory creation logic to deploy.sh after line 125 (after VM_NAME validation)
- [x] 1.2 Implement file transfer for secrets.yaml using multipass transfer command
- [x] 1.3 Implement file transfer for deployment.yaml using multipass transfer command
- [x] 1.4 Implement file transfer for service.yaml using multipass transfer command
- [x] 1.5 Implement file transfer for ingress.yaml using multipass transfer command
- [x] 2.1 Add validation logic to check if k8s/ directory exists in VM after creation
- [x] 2.2 Add validation logic to verify secrets.yaml exists in VM after transfer
- [x] 2.3 Add validation logic to verify deployment.yaml exists in VM after transfer
- [x] 2.4 Add validation logic to verify service.yaml exists in VM after transfer
- [x] 2.5 Add validation logic to verify ingress.yaml exists in VM after transfer
- [x] 3.1 Add error handler for directory creation failures with specific error code
- [x] 3.2 Add error handler for file transfer failures with specific error code
- [x] 3.3 Add error handler for file validation failures with specific error code
- [x] 3.4 Update handle_secrets_error function to include new error codes (110-119)
- [x] 3.5 Add recovery suggestions for each new error type
- [x] 4.1 Add log message before directory creation in VM
- [x] 4.2 Add success log message after directory creation
- [x] 4.3 Add log message before each file transfer
- [x] 4.4 Add success log message after each file transfer
- [x] 4.5 Add log message before file validation
- [x] 4.6 Add success log message after all files validated
- [x] 5.1 Test directory creation in VM with successful execution
- [x] 5.2 Test file transfer for all four YAML files
- [x] 5.3 Test file validation catches missing files
- [x] 5.4 Test deployment succeeds end-to-end with file transfers
- [x] 5.5 Test error handling provides clear messages when transfers fail
- [x] 5.6 Verify log file contains all new log messages
- [x] 5.7 Verify deployment script exits with non-zero status on file transfer failures
- [x] 6.1 Build Docker image using Dockerfile in project root
- [x] 6.2 Verify Docker image was built successfully
- [x] 6.3 Load Docker image into multipass VM using docker save | multipass exec -- docker load
- [x] 6.4 Verify image is available in VM's Docker daemon
- [x] 6.5 Restart deployment to trigger pod recreation with new image
- [x] 6.6 Verify pod status changes from ImagePullBackOff to Running
- [x] 6.7 Verify pod passes readiness and liveness probes
- [x] 6.8 Test application accessibility via ingress endpoint
