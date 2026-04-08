## Why

Deployments are failing due to a critical bug in the build script that causes false negative build failures after successful Docker builds. The script attempts to clean up a tar file that no longer exists after transfer to VM, causing the build step to report failure even when Docker build succeeds. This blocks all deployments and causes unnecessary rollbacks. Additionally, error handling with `set -e` treats all command failures as critical, including non-critical cleanup operations, making the deployment pipeline fragile.

## What Changes

- Remove tar cleanup commands that execute after successful file transfer to VM in build-docker-image.sh
- Restrict `set -e` error propagation to critical operations only (Docker build, image load), not cleanup operations
- Update package-lock.json to synchronize with package.json React 19 requirements
- Update Dockerfile base image from Node 20.12.0-alpine to Node 20.19.0-alpine
- Add explicit error handling with exit code checks for build operations
- Maintain existing rollback capability without modification

## Capabilities

### New Capabilities
- `build-error-precision`: Build scripts accurately distinguish between actual build failures and non-critical cleanup failures
- `lock-file-synchronization`: package-lock.json remains synchronized with package.json dependencies
- `node-version-compliance`: Docker image meets minimum Node version requirements for all dependencies

### Modified Capabilities
- None (implementation-only changes to existing scripts and configuration)

## Impact

- Modified scripts:
  - `deploy_scripts/build-docker-image.sh` (remove tar cleanup, refine error handling)
- Modified configuration files:
  - `package-lock.json` (regenerate for React 19 compatibility)
  - `Dockerfile` (update Node base image version)
- No API changes
- No dependency changes (package.json unchanged)
- Deployments will complete successfully without false negative failures
- Build verification will rely on Docker exit codes rather than cleanup operations
- All existing rollback capability preserved
