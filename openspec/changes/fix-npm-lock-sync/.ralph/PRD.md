# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

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

## Specifications

docker-build-dependencies/spec.md
# Docker Build Dependencies

## Purpose

Capability for maintaining consistent package dependency files (package.json and package-lock.json) to ensure reliable Docker builds. This covers validation, synchronization, and error handling for npm lock file issues during the Docker build process.

## ADDED Requirements

### Requirement: Lock file consistency validation
The deployment process SHALL validate that package.json and package-lock.json are synchronized before attempting Docker builds.

#### Scenario: Lock files are synchronized
- **WHEN** the deployment script validates lock file consistency
- **AND** package.json and package-lock.json are in sync
- **THEN** the script SHALL proceed with the Docker build
- **AND** the script SHALL log that validation passed

#### Scenario: Lock files are out of sync
- **WHEN** the deployment script validates lock file consistency
- **AND** package.json and package-lock.json are out of sync
- **THEN** the script SHALL detect the mismatch
- **AND** the script SHALL log which dependencies are missing or inconsistent
- **AND** the script SHALL provide clear instructions to fix the issue
- **AND** the script SHALL exit with a non-zero status code

### Requirement: Lock file synchronization
The system SHALL provide a mechanism to synchronize package-lock.json with package.json when they are out of sync.

#### Scenario: Successful lock file synchronization
- **WHEN** the user runs the synchronization command
- **THEN** the system SHALL execute npm install to update package-lock.json
- **AND** the system SHALL verify the lock file is now consistent
- **AND** the system SHALL log the successful synchronization

#### Scenario: Synchronization fails
- **WHEN** the synchronization command fails
- **THEN** the system SHALL log the npm error with context
- **AND** the system SHALL provide troubleshooting suggestions
- **AND** the system SHALL exit with a non-zero status code

### Requirement: Docker build fallback mechanism
The Dockerfile SHALL include a fallback mechanism when npm ci fails due to lock file sync issues.

#### Scenario: npm ci succeeds
- **WHEN** the Docker build executes npm ci
- **AND** package.json and package-lock.json are in sync
- **THEN** the build SHALL proceed normally
- **AND** npm ci SHALL install dependencies from the lock file

#### Scenario: npm ci fails with fallback
- **WHEN** the Docker build executes npm ci
- **AND** npm ci fails due to lock file sync issues
- **THEN** the build SHALL automatically fall back to npm install
- **AND** the build SHALL log that fallback was triggered
- **AND** the build SHALL continue with dependency installation

### Requirement: Pre-build dependency check
The deployment script SHALL perform a dependency consistency check before initiating the Docker build process.

#### Scenario: Pre-build check passes
- **WHEN** the deployment script runs the pre-build dependency check
- **AND** all dependencies are consistent
- **THEN** the script SHALL proceed to Docker build
- **AND** the script SHALL log that dependencies are valid

#### Scenario: Pre-build check fails
- **WHEN** the deployment script runs the pre-build dependency check
- **AND** dependencies are inconsistent
- **THEN** the script SHALL halt before Docker build
- **AND** the script SHALL display the specific dependency issues
- **AND** the script SHALL provide the command to fix the issue
- **AND** the script SHALL exit with a non-zero status code

### Requirement: Development workflow guidance
The system SHALL provide clear documentation for maintaining lock file consistency during development.

#### Scenario: Developer updates dependencies
- **WHEN** a developer adds or updates a dependency in package.json
- **THEN** the system SHALL instruct them to run npm install
- **AND** the system SHALL explain that this updates package-lock.json
- **AND** the system SHALL warn against manually editing package-lock.json

#### Scenario: Developer commits changes
- **WHEN** a developer commits changes
- **THEN** the system SHALL verify both package.json and package-lock.json are committed together
- **AND** the system SHALL warn if only one file is changed

docker-image-build-load/spec.md
# Docker Image Build and Load

## Purpose

Capability for building Docker images and loading them into the multipass VM's Docker daemon. This enables the deployment process to build application images locally and transfer them to the VM for Kubernetes deployment.

## MODIFIED Requirements

### Requirement: Docker image build
The deployment process SHALL build a Docker image from the project's Dockerfile after validating that package.json and package-lock.json are synchronized.

#### Scenario: Successful image build with validated dependencies
- **WHEN** the deployment script executes the docker build command
- **AND** package.json and package-lock.json are validated as synchronized
- **THEN** the script SHALL build an image named my-ag-ui-app:latest
- **AND** the script SHALL use the Dockerfile in the project root
- **AND** the script SHALL log the build progress
- **AND** the script SHALL use npm ci for clean installation
- **AND** the script SHALL log that dependencies were installed from lock file

#### Scenario: Image build failure with dependency sync error
- **WHEN** the deployment script validates dependencies
- **AND** package.json and package-lock.json are out of sync
- **THEN** the script SHALL NOT proceed with docker build
- **AND** the script SHALL log the dependency sync error with context
- **AND** the script SHALL provide instructions to run npm install to fix the issue
- **AND** the script SHALL exit with a non-zero status code

#### Scenario: Image build failure with npm ci fallback
- **WHEN** the docker build executes npm ci
- **AND** npm ci fails due to lock file sync issues
- **THEN** the Dockerfile SHALL automatically fall back to npm install
- **AND** the build SHALL log that fallback to npm install was triggered
- **AND** the build SHALL continue with dependency installation
- **AND** the build SHALL complete successfully if npm install succeeds

#### Scenario: Image build failure
- **WHEN** the docker build command fails
- **AND** the failure is not related to dependency synchronization
- **THEN** the script SHALL log the build error with context
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with deployment



## Design

## Context

The current Docker build process fails when `package.json` and `package-lock.json` are out of sync. The error occurs during the `npm ci` step in the Dockerfile, which requires exact synchronization between these files. This creates a critical deployment bottleneck where developers must manually synchronize lock files before any Docker build can succeed.

**Current State:**
- Dockerfile uses `npm ci --ignore-scripts` for dependency installation
- No pre-build validation of lock file consistency
- No fallback mechanism when `npm ci` fails
- Error messages are cryptic and don't provide clear remediation steps
- The deploy.sh script doesn't validate dependencies before initiating Docker builds

**Constraints:**
- Must maintain reproducible builds (prefer `npm ci` over `npm install`)
- Minimal changes to existing Docker build workflow
- Must work with current multipass VM and Kubernetes deployment setup
- Should not break existing CI/CD pipelines
- Must provide clear error messages and remediation guidance

**Stakeholders:**
- Developers who need to update dependencies
- DevOps team managing deployments
- CI/CD pipeline maintainers

## Goals / Non-Goals

**Goals:**
- Detect lock file synchronization issues before Docker builds
- Provide clear error messages with remediation steps
- Implement a fallback mechanism when `npm ci` fails
- Document best practices for maintaining lock file consistency
- Ensure deployment process is more resilient to dependency sync issues

**Non-Goals:**
- Changing the fundamental Docker build architecture
- Modifying Kubernetes deployment configurations
- Implementing a full dependency management system
- Changing the multipass VM setup
- Modifying application code or dependencies

## Decisions

### Decision 1: Pre-build validation in deploy.sh
**Choice:** Add a validation step in deploy.sh before Docker build that checks if package.json and package-lock.json are synchronized.

**Rationale:**
- Fails fast before expensive Docker build operations
- Provides immediate feedback to developers
- Easier to maintain than Dockerfile changes
- Can provide more detailed error messages and remediation steps
- Doesn't require modifying the Docker build process itself

**Alternatives considered:**
- **Dockerfile validation:** Would catch issues during build but wastes build time
- **CI/CD gate:** Would catch issues but doesn't help local development
- **Git pre-commit hook:** Would prevent committing out-of-sync files but doesn't help existing issues

### Decision 2: Fallback mechanism in Dockerfile
**Choice:** Modify Dockerfile to use `npm install` as a fallback when `npm ci` fails due to lock file sync issues.

**Rationale:**
- Maintains reproducible builds when lock files are in sync (preferred path)
- Provides graceful degradation when sync issues occur
- Allows deployments to proceed even with minor sync discrepancies
- Logs when fallback is triggered for monitoring and debugging

**Alternatives considered:**
- **Always use npm install:** Loses reproducibility benefits of npm ci
- **Fail hard on sync issues:** Too strict, blocks deployments unnecessarily
- **Separate Dockerfile for development:** Adds complexity and maintenance burden

### Decision 3: Validation approach
**Choice:** Use `npm ci --dry-run` to validate lock file consistency.

**Rationale:**
- Uses npm's built-in validation logic
- Fast and reliable
- Provides detailed error messages about which dependencies are out of sync
- No external dependencies required

**Alternatives considered:**
- **Custom JSON comparison:** Would need to handle npm's resolution logic
- **npm outdated:** Doesn't check lock file sync, only version availability
- **npm audit:** Checks for security issues, not sync consistency

### Decision 4: Documentation location
**Choice:** Add lock file maintenance guidance to existing SETUP.md and create a separate DEPENDENCIES.md file.

**Rationale:**
- SETUP.md already covers environment setup, so it's a natural fit
- Separate DEPENDENCIES.md allows for more detailed dependency management documentation
- Keeps documentation organized and discoverable
- Can be referenced from multiple places (README, deploy.sh output)

**Alternatives considered:**
- **Only in README:** README is already long, might get lost
- **Only in deploy.sh comments:** Not discoverable enough
- **Inline in Dockerfile:** Hard to read and maintain

## Risks / Trade-offs

### Risk 1: Fallback mechanism masks underlying issues
**Risk:** Using `npm install` as a fallback might allow deployments with inconsistent lock files, potentially leading to different dependency versions across environments.

**Mitigation:**
- Log prominently when fallback is triggered
- Include warnings in deployment logs about lock file inconsistencies
- Provide clear instructions to fix the root cause
- Monitor fallback usage in production to identify systemic issues

### Risk 2: Pre-build validation adds deployment time
**Risk:** Additional validation step adds ~2-5 seconds to deployment time.

**Mitigation:**
- Validation is fast compared to Docker build (minutes)
- Fails fast, saving time when issues are present
- Can be skipped with a flag if needed (e.g., `--skip-deps-check`)

### Risk 3: npm ci --dry-run might have false positives
**Risk:** Some edge cases where `npm ci --dry-run` reports issues that wouldn't actually fail the build.

**Mitigation:**
- Test validation against various dependency scenarios
- Allow bypass with explicit flag if needed
- Monitor validation accuracy and adjust as needed

### Risk 4: Documentation drift
**Risk:** Documentation might become outdated as npm or project practices evolve.

**Mitigation:**
- Include documentation in code review checklist
- Add automated checks where possible
- Review documentation quarterly or after major npm version changes

### Trade-off: Reproducibility vs. Resilience
**Trade-off:** We're trading some build reproducibility (by allowing fallback) for deployment resilience.

**Balance:** The fallback is a safety net, not the primary path. We maintain reproducibility as the default and only fall back when necessary, with clear logging to encourage fixing the root cause.

## Migration Plan

### Deployment Steps

1. **Update Dockerfile**
   - Add fallback logic for npm ci failures
   - Add logging for fallback activation
   - Test with both in-sync and out-of-sync lock files

2. **Update deploy.sh**
   - Add pre-build validation function
   - Call validation before Docker build
   - Add error handling and remediation messages
   - Add `--skip-deps-check` flag for emergency bypass

3. **Create documentation**
   - Add lock file maintenance section to SETUP.md
   - Create DEPENDENCIES.md with detailed guidance
   - Add troubleshooting section for common sync issues

4. **Test deployment**
   - Deploy with in-sync lock files (verify normal path)
   - Deploy with out-of-sync lock files (verify fallback path)
   - Verify error messages are clear and actionable
   - Test with `--skip-deps-check` flag

### Rollback Strategy

1. **Revert Dockerfile** to original `npm ci` only version
2. **Revert deploy.sh** to remove validation step
3. **Remove documentation** changes (or keep as helpful reference)
4. **No data migration** needed (no data changes)

**Rollback triggers:**
- Fallback mechanism causes production issues
- Validation step blocks valid deployments
- Performance impact is unacceptable
- Security vulnerabilities discovered in fallback path

## Open Questions

1. **Should we enforce lock file consistency in CI/CD?**
   - Currently unclear if this should be a hard gate or just a warning
   - Need to understand team's tolerance for deployment delays

2. **What's the acceptable threshold for fallback usage?**
   - How often can fallback be triggered before we need to investigate?
   - Should we alert if fallback is used more than X times per week?

3. **Should we add a git pre-commit hook?**
   - Would prevent committing out-of-sync files
   - Might be too restrictive for some workflows
   - Need team input on this

4. **How should we handle transitive dependency updates?**
   - When npm updates transitive dependencies, lock file changes
   - Need clear guidance on when to commit these changes
   - May need to document expected behavior

5. **Should we add automated lock file updates to CI/CD?**
   - Could run `npm install` periodically to keep lock file fresh
   - Might create unexpected changes in production
   - Need to weigh benefits vs. risks

## Current Task Context

## Current Task
- 4.4 Test --skip-deps-check flag functionality
## Completed Tasks for Git Commit
- [x] 1.1 Add fallback logic to handle npm ci failures in Dockerfile
- [x] 1.2 Implement npm install fallback when npm ci fails due to lock file sync issues
- [x] 1.3 Add logging to indicate when fallback mechanism is triggered
- [x] 1.4 Test Dockerfile with in-sync lock files (verify normal path works)
- [x] 1.5 Test Dockerfile with out-of-sync lock files (verify fallback path works)
- [x] 2.1 Create validate_lock_files function in deploy.sh
- [x] 2.2 Implement npm ci --dry-run validation check
- [x] 2.3 Add error handling and clear remediation messages for sync failures
- [x] 2.4 Integrate validation step before Docker build in deploy.sh
- [x] 2.5 Add --skip-deps-check flag for emergency bypass
- [x] 2.6 Test validation with in-sync lock files (should pass)
- [x] 2.7 Test validation with out-of-sync lock files (should fail with clear message)
- [x] 3.1 Add lock file maintenance section to SETUP.md
- [x] 3.2 Create DEPENDENCIES.md with detailed dependency management guidance
- [x] 3.3 Document the pre-build validation process
- [x] 3.4 Document the fallback mechanism and when it triggers
- [x] 3.5 Add troubleshooting section for common lock file sync issues
- [x] 3.6 Document the --skip-deps-check flag usage and warnings
- [x] 4.1 Run full deployment with in-sync lock files (verify normal path)
- [x] 4.2 Run full deployment with out-of-sync lock files (verify fallback path)
- [x] 4.3 Verify error messages are clear and actionable
