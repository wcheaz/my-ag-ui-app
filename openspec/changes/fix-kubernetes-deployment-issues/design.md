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
