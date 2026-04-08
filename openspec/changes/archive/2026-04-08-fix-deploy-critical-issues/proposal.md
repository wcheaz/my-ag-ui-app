## Why

Deployment pipeline fails due to three critical bugs that prevent reliable deployments and rollback capability. Docker cleanup fails with conflicts from stopped containers, the build script reports false negative errors after successful Docker builds, and rollback cannot execute because backup files are not created. These issues block deployment reliability and require immediate fixes.

## What Changes

- Fix Docker cleanup to stop and remove containers before attempting image deletion
- Fix build-docker-image.sh error detection to correctly identify successful builds
- Add backup file creation before deployment to enable rollback capability
- Add backup file verification to ensure rollback can execute
- Improve error messaging to clearly distinguish between warnings and failures

## Capabilities

### New Capabilities
- `docker-cleanup-idempotency`: Cleanup operations handle containers and images safely without conflicts
- `build-verification-accuracy`: Build scripts correctly identify success/failure states
- `deployment-rollback-safety`: Rollback can execute with pre-existing backup files

### Modified Capabilities
- None (implementation-only changes to existing scripts)

## Impact

- Modified scripts:
  - `deploy_scripts/cleanup-resources.sh`
  - `deploy_scripts/build-docker-image.sh`
  - `deploy_scripts/tag-docker-image.sh` (for backup creation)
  - `deploy-all.sh` (for backup orchestration)
- No API changes
- No dependency changes
- Deployments will become idempotent and verifiable
- Rollback will work correctly on failures
