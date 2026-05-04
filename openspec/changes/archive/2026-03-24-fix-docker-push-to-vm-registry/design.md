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
