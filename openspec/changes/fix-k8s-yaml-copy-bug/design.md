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
