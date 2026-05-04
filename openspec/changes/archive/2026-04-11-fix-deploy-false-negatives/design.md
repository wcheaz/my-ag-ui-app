## Context

Current deployment pipeline uses `deploy-all.sh` which orchestrates several steps including building Docker images via `deploy_scripts/build-docker-image.sh`. The build script has four issues blocking deployments:

1. **False negative build failure**: After successfully transferring Docker image tar to VM, script attempts to delete the tar file from the host (line 234), but file no longer exists there. This causes `rm -f` to fail, and with `set -e` active, entire script exits with code 1. The parent `deploy-all.sh` interprets this as build failure and triggers rollback, even though the build succeeded.

2. **VM disk space exhaustion**: The VM has insufficient disk space to load Docker images (292MB image). When attempting `docker load`, containerd fails with "no space left on device" error in `/var/lib/containerd/io.containerd.content.v1.content/ingest/`. This causes deployment to fail even though Docker build succeeded.

3. **Overly aggressive error propagation**: The script uses `set -e` globally (line 5), causing ANY non-zero exit code to abort the script. This includes non-critical cleanup operations that should not fail the deployment.

4. **Package lock mismatch**: `package.json` specifies React 19.2.4 but `package-lock.json` expects `@types/react@18.3.28`, causing `npm ci` to fail and fall back to `npm install`, reducing build reproducibility.

5. **Node version incompatibility**: Dockerfile uses Node 20.12.0, but `eslint-visitor-keys@5.0.1` requires Node 20.19.0+.

## Goals / Non-Goals

**Goals:**
- Fix false negative build failures in deploy_scripts/build-docker-image.sh
- Ensure VM has sufficient disk space to load Docker images through cleanup and verification
- Ensure build success/failure is determined by Docker build exit codes, not cleanup operations
- Synchronize package-lock.json with package.json for React 19 compatibility
- Update Dockerfile to use Node version that meets all dependency requirements
- Maintain existing rollback capability
- Preserve all other deployment pipeline functionality

**Non-Goals:**
- Addressing security vulnerabilities in npm packages (deferred to separate change)
- Changing the overall deployment architecture
- Modifying rollback functionality
- Changing Docker build configuration or multi-stage setup
- Modifying Kubernetes deployment or service definitions

## Decisions

### 1. Remove tar cleanup commands from build-docker-image.sh

**Decision**: Remove lines 233-236 from `deploy_scripts/build-docker-image.sh`:
```bash
multipass exec "$VM_NAME" -- rm -f /tmp/my-ag-ui-app.tar
rm -f "$TAR_FILE"
```

**Rationale**: The tar file is created on the host, transferred to VM via line 173 (`multipass transfer`), and loaded into Docker. After successful transfer, the tar file in VM is consumed by Docker. Attempting to delete it afterward is redundant and causes false failures because the host-side file already doesn't exist when we try to delete it.

**Alternatives considered**:
- Add error suppression `|| true` after `rm -f` → rejected because cleanup is unnecessary, better to remove entirely
- Check file existence before deletion → rejected because adds complexity without value

### 2. Add VM disk space cleanup and verification before image load

**Decision**: Before loading Docker image to VM, add cleanup and verification:
```bash
# Check disk space before image load (in megabytes as integers)
log "Checking VM disk space..."
AVAILABLE_SPACE_MB=$(multipass exec "$VM_NAME" -- df -BM / | awk 'NR==2 {print $4}')
log "Available space: ${AVAILABLE_SPACE_MB}MB"

# Prune unused Docker data to free space
log "Cleaning up unused Docker images and containers..."
multipass exec "$VM_NAME" -- docker system prune -f

# Verify space again after cleanup
AVAILABLE_SPACE_MB=$(multipass exec "$VM_NAME" -- df -BM / | awk 'NR==2 {print $4}')
log "Available space after cleanup: ${AVAILABLE_SPACE_MB}MB"

# Require minimum 500MB (both values are integers from df -BM)
MIN_SPACE_MB=500
if [ "$AVAILABLE_SPACE_MB" -lt "$MIN_SPACE_MB" ]; then
    log "❌ ERROR: Insufficient disk space on VM (${AVAILABLE_SPACE_MB}MB available, ${MIN_SPACE_MB}MB required)"
    log "   Free up space or increase VM disk size"
    exit 1
fi
```

**Rationale**: The VM disk space exhaustion is blocking deployments. By running `docker system prune -f` before loading images, we free up space from unused images, containers, and build cache. Verifying disk space with a 500MB minimum threshold ensures we fail fast with a clear error message rather than during Docker load, which provides better user feedback and prevents partial deployment state.

Using `df -BM` instead of `df -h` provides disk space in megabytes as integers, avoiding floating-point comparison issues that cause bash "integer expression expected" errors when parsing human-readable sizes like "4.8G".

**Alternatives considered**:
- Increase VM disk size → rejected because requires user intervention to recreate VM, not automated
- Ignore disk space errors → rejected because deployment fails anyway with cryptic error message
- Use separate disk cleanup script → rejected because cleanup belongs as part of image load preparation
- Set threshold lower (e.g., 200MB) → rejected because 292MB image size plus buffer needs 500MB minimum
- Parse human-readable output with floating-point comparison → rejected because bash `[` test doesn't support floating-point and requires `bc` or `awk`, adding complexity

### 3. Use scoped error handling instead of global `set -e`

**Decision**: Replace global `set -e` with scoped error handling for critical operations only:

```bash
# Critical section with error checking
(
    set -e
    docker build -t my-ag-ui-app:latest . 2>&1 | tee "$LOG_FILE"
    docker_build_status=${PIPESTATUS[0]}
    
    if [ $docker_build_status -ne 0 ]; then
        echo "ERROR: Docker build failed with exit code $docker_build_status"
        exit $docker_build_status
    fi
)

# Non-critical cleanup continues even if it fails
set +e
# ... cleanup operations that should not fail deployment
```

**Rationale**: Only Docker build and image load operations should cause deployment failure. Cleanup operations (tar removal, container cleanup) should not abort deployment even if they fail. Using scoped `set -e` ensures critical failures propagate while non-critical failures are logged but ignored.

**Alternatives considered**:
- Keep global `set -e` and add `|| true` to every non-critical command → rejected because verbose and error-prone
- Remove `set -e` entirely and manually check every command → rejected because increases risk of missing critical failures

### 4. Update package-lock.json by running npm install locally

**Decision**: Run `npm install` locally (not in CI/CD) to regenerate package-lock.json, then commit the updated file.

**Rationale**: package.json has been updated to React 19.2.4 but package-lock.json still references React 18 types. Running `npm install` synchronizes the lock file with package.json, eliminating the `npm ci` fallback to `npm install` and restoring build reproducibility.

**Alternatives considered**:
- Manually edit package-lock.json → rejected because error-prone and risks inconsistencies
- Use `npm ci --force` to ignore mismatch → rejected because bypasses problem rather than fixing it

### 5. Update Dockerfile base image to Node 20.19.0-alpine

**Decision**: Change Dockerfile line 4 from:
```dockerfile
FROM node:20.12.0-alpine
```
to:
```dockerfile
FROM node:20.19.0-alpine
```

**Rationale**: The `eslint-visitor-keys@5.0.1` package requires Node 20.19.0 or later (as shown in deploy log warning). Current Node 20.12.0 triggers an EBADENGINE warning. Updating to 20.19.0 removes the warning and ensures all packages meet minimum version requirements.

**Alternatives considered**:
- Upgrade to Node 22.x → rejected because larger version jump, potential for more breaking changes
- Suppresses warning → rejected because doesn't address underlying compatibility issue
- Remove eslint-visitor-keys → rejected because may break ESLint functionality

### 6. Preserve existing rollback capability

**Decision**: Do not modify rollback functionality in deploy-all.sh. The backup file creation (k8s/deployment.yaml.backup) works correctly and should continue to be triggered only on actual failures.

**Rationale**: Rollback is currently triggered by the false negative failure from the tar cleanup bug. Once that bug is fixed, rollback will only trigger on genuine failures. No changes needed.

## Risks / Trade-offs

### Risk: Docker system prune removes images needed for other applications

**Risk**: Running `docker system prune -f` on VM may remove Docker images or containers that are being used by other applications or microservices running on the same VM.

**Mitigation**: The VM is dedicated to this deployment. Other applications should run on separate VMs or use different container namespaces. Verify no other critical services depend on unused images before running prune. The prune only removes unused (dangling) images, not images in use or referenced by containers.

### Risk: Disk space verification threshold is arbitrary

**Risk**: Setting 500MB minimum disk space threshold may be too high or too low depending on image size and VM usage patterns.

**Mitigation**: The current Docker image is 292MB. 500MB provides sufficient buffer for image loading plus overhead. Monitor successful deployments and adjust threshold if needed. The error message clearly indicates the requirement, making it easy for operators to adjust if necessary.

### Risk: Removing tar cleanup leaves temporary files

**Risk**: Removing tar cleanup lines may leave temporary tar files in VM.

**Mitigation**: The tar file in VM is consumed by Docker during `docker load`, so Docker manages cleanup. Host-side file is already handled by being transferred to VM. No orphaned files remain.

### Risk: Scoped error handling may miss some critical failures

**Risk**: Only explicitly scoped operations use `set -e`, so some failures in unscoped sections might be missed.

**Mitigation**: Critical operations (Docker build, image load, VM transfer) are all scoped and will fail appropriately. Unscoped sections are intentionally non-critical cleanup operations that should not abort deployment.

### Risk: npm install locally may introduce environment-specific changes

**Risk**: Running `npm install` in local development environment may capture environment-specific packages or versions not suitable for CI/CD.

**Mitigation**: Use `.npmrc` or `package.json` overrides if environment-specific packages exist. Verify lock file changes only include React-related updates, not new dependencies. The production Docker build runs `npm ci` or `npm install` in a clean environment anyway.

### Risk: Node version update may introduce compatibility issues

**Risk**: Upgrading from Node 20.12.0 to 20.19.0 is a minor version bump but could still introduce unexpected compatibility issues.

**Mitigation**: 20.19.0 is a patch-level update within Node 20 LTS, with minimal breaking changes. Test locally before committing to ensure application builds and runs correctly.

### Trade-off: Security vulnerabilities not addressed

**Trade-off**: The npm audit shows 19 vulnerabilities (10 moderate, 9 high), but we are not fixing them in this change.

**Rationale**: Security fixes require separate dependency updates that could introduce breaking changes or require extensive testing. This change focuses on blocking deployment issues only. Create a separate security-focused change to address vulnerabilities.

## Migration Plan

**Deployment Steps**:
1. Update build-docker-image.sh by removing tar cleanup, adding VM disk space cleanup and verification, and adding scoped error handling
2. Update Dockerfile to use Node 20.19.0-alpine
3. Run `npm install` locally to regenerate package-lock.json
4. Commit changes to repository
5. Deploy using deploy-all.sh
6. Verify deployment succeeds without "STEP 2 FAILED" error
7. Verify no "no space left on device" errors during image load
8. Verify npm ci succeeds without lock file mismatch warnings
9. Verify no Node version warnings in build output

**Rollback Strategy**:
- Existing rollback in deploy-all.sh remains unchanged and will function correctly
- If issues arise, rollback to previous commit before these changes
- Restore previous package-lock.json and Dockerfile versions if needed

## Open Questions

None. All technical decisions are specified and actionable. No outstanding unknowns require resolution before implementation.
