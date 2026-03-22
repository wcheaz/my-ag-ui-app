## Why

Docker builds are failing because `package.json` and `package-lock.json` are out of sync, preventing `npm ci` from running successfully during the Docker build process. This blocks deployment and creates a critical bottleneck in the CI/CD pipeline.

## What Changes

- Synchronize `package-lock.json` with `package.json` to resolve the missing `@types/react@18.3.28` dependency
- Update the [`Dockerfile`](Dockerfile) to use `npm install` instead of `npm ci` when lock file synchronization issues occur, or add a pre-check step to validate lock file consistency
- Add validation in the [`deploy.sh`](deploy.sh) script to detect lock file sync issues before attempting Docker builds
- Document the process for maintaining lock file consistency in development workflows

## Capabilities

### New Capabilities
- `docker-build-dependencies`: Defines requirements for maintaining consistent package dependency files (package.json and package-lock.json) to ensure reliable Docker builds. Covers validation, synchronization, and error handling for npm lock file issues.

### Modified Capabilities
- `docker-image-build-load`: Update requirements to include pre-build validation of npm lock file consistency and fallback mechanisms when `npm ci` fails due to sync issues.

## Impact

- **Docker build process**: More reliable builds with better error handling and validation
- **CI/CD pipeline**: Faster failure detection with clear error messages when lock files are out of sync
- **Development workflow**: Clearer guidance for maintaining lock file consistency
- **Deployment reliability**: Reduced deployment failures due to npm dependency issues
- **No breaking changes**: Existing functionality preserved, only adding validation and fallback mechanisms