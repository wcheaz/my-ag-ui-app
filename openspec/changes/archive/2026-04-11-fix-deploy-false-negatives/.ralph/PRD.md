# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

## Why

Deployments are failing due to multiple critical issues blocking the pipeline. First, a bug in the build script causes false negative failures after successful Docker builds when attempting to clean up a non-existent tar file. Second, the VM has insufficient disk space to load Docker images, causing "no space left on device" errors during image ingestion. These issues block all deployments and cause unnecessary rollbacks. Additionally, error handling with `set -e` treats all command failures as critical, including non-critical cleanup operations, making the deployment pipeline fragile.

## What Changes

- Remove tar cleanup commands that execute after successful file transfer to VM in build-docker-image.sh
- Restrict `set -e` error propagation to critical operations only (Docker build, image load), not cleanup operations
- Add VM disk space cleanup before loading Docker images to prevent "no space left on device" errors
- Add disk space verification before image load with clear error messaging if insufficient
- Update package-lock.json to synchronize with package.json React 19 requirements
- Update Dockerfile base image from Node 20.12.0-alpine to Node 20.19.0-alpine
- Add explicit error handling with exit code checks for build operations
- Maintain existing rollback capability without modification

## Capabilities

### New Capabilities
- `build-error-precision`: Build scripts accurately distinguish between actual build failures and non-critical cleanup failures
- `vm-disk-space-management`: VM has sufficient disk space to load Docker images, with cleanup and verification
- `lock-file-synchronization`: package-lock.json remains synchronized with package.json dependencies
- `node-version-compliance`: Docker image meets minimum Node version requirements for all dependencies

### Modified Capabilities
- None (implementation-only changes to existing scripts and configuration)

## Impact

- Modified scripts:
  - `deploy_scripts/build-docker-image.sh` (remove tar cleanup, add VM disk space cleanup and verification, refine error handling)
- Modified configuration files:
  - `package-lock.json` (regenerate for React 19 compatibility)
  - `Dockerfile` (update Node base image version)
- No API changes
- No dependency changes (package.json unchanged)
- Deployments will complete successfully without false negative failures
- VM will have sufficient disk space for Docker image loading
- Build verification will rely on Docker exit codes rather than cleanup operations
- All existing rollback capability preserved

## Specifications

build-error-precision/spec.md
## ADDED Requirements

### Requirement: Build scripts accurately distinguish between actual build failures and non-critical cleanup failures

The build system SHALL accurately determine build success or failure based on Docker build and image load operations, not on cleanup operations.

The build script SHALL NOT fail when non-critical cleanup operations fail after successful Docker build and image load.

The build script SHALL fail with non-zero exit code when Docker build operations fail.

The build script SHALL use Docker build exit codes via PIPESTATUS to determine build success.

The build script SHALL NOT attempt to clean up tar files after successful transfer to VM.

#### Scenario: Successful Docker build with cleanup failure
- **WHEN** Docker build completes successfully and image is loaded to VM
- **THEN** build script SHALL exit with code 0
- **THEN** deploy-all.sh SHALL proceed to next step
- **THEN** rollback SHALL NOT be triggered

#### Scenario: Failed Docker build
- **WHEN** Docker build encounters errors and exits with non-zero code
- **THEN** build script SHALL exit with same non-zero code
- **THEN** deploy-all.sh SHALL report "STEP 2 FAILED"
- **THEN** rollback SHALL be triggered

#### Scenario: Image load failure to VM
- **WHEN** Docker image transfer to VM fails or image load fails
- **THEN** build script SHALL exit with non-zero code
- **THEN** deploy-all.sh SHALL report "STEP 2 FAILED"
- **THEN** rollback SHALL be triggered

#### Scenario: Non-critical cleanup failure after successful build
- **WHEN** cleanup operations (tar deletion, container cleanup) fail after successful Docker build
- **THEN** build script SHALL log the failure
- **THEN** build script SHALL continue and exit with code 0
- **THEN** deployment SHALL proceed without rollback

lock-file-synchronization/spec.md
## ADDED Requirements

The package-lock.json file SHALL remain synchronized with package.json dependencies.

The package-lock.json file SHALL use React 19 type definitions when package.json specifies React 19.

The `npm ci` command SHALL succeed during Docker build without falling back to `npm install`.

The build script SHALL use `npm ci` for reproducible dependency installation when lock file is synchronized.

The build script SHALL NOT display lock file mismatch warnings during dependency installation.

#### Scenario: Successful npm ci during Docker build
- **WHEN** Docker build runs `npm ci` with synchronized package-lock.json
- **THEN** npm ci SHALL complete successfully with exit code 0
- **THEN** no lock file mismatch warnings SHALL be displayed
- **THEN** dependencies SHALL be installed from lock file exactly as specified
- **THEN** build SHALL continue without fallback to `npm install`

#### Scenario: Package-lock.json synchronized with package.json
- **WHEN** package.json is updated to React 19 and `npm install` is run locally
- **THEN** package-lock.json SHALL contain React 19 type definitions
- **THEN** package-lock.json SHALL not contain @types/react@18.x
- **THEN** subsequent `npm ci` in Docker build SHALL succeed

node-version-compliance/spec.md
## ADDED Requirements

The Docker image SHALL use Node.js version that meets minimum requirements for all npm dependencies.

The Dockerfile SHALL use Node.js 20.19.0 or later as base image.

The build system SHALL not display EBADENGINE warnings for Node version compatibility.

All npm dependencies SHALL meet their required Node version constraints in the Docker build environment.

#### Scenario: Docker build with compliant Node version
- **WHEN** Dockerfile uses `FROM node:20.19.0-alpine` as base image
- **THEN** Docker build SHALL complete without EBADENGINE warnings
- **THEN** eslint-visitor-keys@5.0.1 SHALL meet minimum Node version requirement (20.19.0+)
- **THEN** all dependencies SHALL install successfully
- **THEN** build log SHALL not contain "Unsupported engine" warnings

#### Scenario: Dependency requiring minimum Node version
- **WHEN** npm dependency specifies Node 20.19.0+ in engines field
- **THEN** Docker build SHALL use Node 20.19.0 or later
- **THEN** dependency SHALL install without engine compatibility warnings
- **THEN** ESLint SHALL function correctly in build environment

vm-disk-space-management/spec.md
## ADDED Requirements

The VM SHALL have sufficient disk space available before loading Docker images.

The build system SHALL clean up unused Docker images and containers on VM before loading new images.

The build system SHALL verify available disk space before attempting Docker image load.

The build system SHALL fail with clear error message if insufficient disk space remains for image load.

The build system SHALL not trigger rollback when disk space is insufficient (this is a pre-deployment verification failure, not a deployment rollback scenario).

#### Scenario: Sufficient disk space on VM
- **WHEN** VM has at least 500MB of free disk space before image load
- **THEN** Docker image load SHALL succeed
- **THEN** deployment SHALL proceed without disk space errors
- **THEN** no "no space left on device" errors SHALL occur

#### Scenario: Insufficient disk space, cleanup succeeds
- **WHEN** VM has insufficient disk space for image load
- **WHEN** `docker system prune -f` on VM frees sufficient space
- **THEN** Docker image load SHALL succeed after cleanup
- **THEN** deployment SHALL proceed
- **THEN** "no space left on device" error SHALL not occur

#### Scenario: Insufficient disk space, cleanup insufficient
- **WHEN** VM has insufficient disk space for image load
- **WHEN** `docker system prune -f` does not free sufficient space
- **THEN** build script SHALL fail with error message "ERROR: Insufficient disk space on VM. Free up space or increase VM disk size."
- **THEN** script SHALL exit with non-zero code
- **THEN** rollback SHALL NOT be triggered (this is a pre-deployment verification failure)

#### Scenario: Disk space verification before image load
- **WHEN** Building and transferring Docker image to VM
- **THEN** build script SHALL check available disk space with `multipass exec "$VM_NAME" -- df -h /`
- **THEN** build script SHALL require minimum 500MB free space
- **THEN** build script SHALL fail with clear message if space below threshold



## Design

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

## Current Task Context

## Current Task
- 5.2 Verify deployment succeeds without disk space errors
## Completed Tasks for Git Commit
- [x] 1.1 Remove tar cleanup commands from deploy_scripts/build-docker-image.sh lines 233-236
- [x] 1.2 Replace global `set -e` with scoped error handling in deploy_scripts/build-docker-image.sh
- [x] 1.3 Add explicit exit code checking for Docker build in deploy_scripts/build-docker-image.sh
- [x] 1.4 Verify build script exits with code 0 on successful build despite cleanup failures
- [x] 2.1 Add disk space verification before Docker image load in deploy_scripts/build-docker-image.sh
- [x] 2.2 Add Docker system prune before image load in deploy_scripts/build-docker-image.sh
- [x] 2.3 Add minimum disk space threshold check with 500MB requirement
- [x] 2.4 Verify deployment succeeds without "no space left on device" errors
- [x] 2.1 Update Dockerfile base image to node:20.19.0-alpine
- [x] 3.2 Verify Docker build completes without EBADENGINE warnings
- [x] 4.1 Run `npm install` locally to regenerate package-lock.json
- [x] 4.2 Commit updated package-lock.json to repository
- [x] 4.3 Verify npm ci succeeds during Docker build
- [x] 5.1 Run full deployment pipeline with all fixes
- [x] 5.3 Verify rollback capability is preserved
- [x] 5.4 Confirm no false negative build failures
