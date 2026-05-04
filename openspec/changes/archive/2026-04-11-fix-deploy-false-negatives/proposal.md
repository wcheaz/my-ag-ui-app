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
