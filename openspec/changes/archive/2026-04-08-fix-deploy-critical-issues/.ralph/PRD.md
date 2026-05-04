# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

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

## Specifications

build-verification-accuracy/spec.md
## ADDED Requirements

### Requirement: Build script correctly identifies success state
The build script MUST use Docker build exit code to determine success or failure. The script MUST verify the built image exists using `docker images` query. Both checks MUST pass for the build to be marked successful.

#### Scenario: Docker build completes successfully
- **GIVEN** Docker build completes with exit code 0
- **WHEN** the build script runs
- **THEN** the script checks the Docker build exit code
- **AND** the script verifies the image exists with `docker images my-ag-ui-app:latest`
- **AND** the script exits with code 0
- **AND** no false negative failure is reported

#### Scenario: Docker build fails
- **GIVEN** Docker build exits with non-zero code
- **WHEN** the build script runs
- **THEN** the script logs an error message
- **AND** the script exits with non-zero code
- **AND** the deployment pipeline halts

#### Scenario: Build exits successfully but image missing
- **GIVEN** Docker build exits with code 0 but image is not found in `docker images` output
- **WHEN** the build script runs
- **THEN** the script logs an error message
- **AND** the script exits with non-zero code
- **AND** the deployment pipeline halts

### Requirement: Build script does not parse output for success determination
The build script MUST NOT use text parsing of Docker build output to determine success. The script MUST rely solely on exit code and image existence verification.

#### Scenario: Build output contains error messages but build succeeds
- **GIVEN** Docker build produces warning messages but exits with code 0
- **WHEN** the build script runs
- **THEN** the build is marked as successful
- **AND** the script does not fail based on warning text in output
- **AND** the script proceeds to next deployment step

#### Scenario: Build output is verbose with no errors
- **GIVEN** Docker build produces extensive output but exits with code 0
- **WHEN** the build script runs
- **THEN** the build is marked as successful
- **AND** the script does not attempt to parse output for success patterns
- **AND** the script proceeds to next deployment step

deployment-rollback-safety/spec.md
## ADDED Requirements

### Requirement: Backup file created before deployment changes
The deployment pipeline MUST create a backup of `k8s/deployment.yaml` at `k8s/deployment.yaml.backup` before applying any Kubernetes changes. The backup MUST be created after the Docker build succeeds but before registry setup.

#### Scenario: Successful backup creation
- **GIVEN** `k8s/deployment.yaml` exists and Docker build succeeded
- **WHEN** the deployment pipeline reaches backup creation step
- **THEN** `k8s/deployment.yaml` is copied to `k8s/deployment.yaml.backup`
- **AND** the backup file exists
- **AND** the backup file content matches the original
- **AND** the deployment pipeline continues to next step

#### Scenario: Backup file already exists
- **GIVEN** `k8s/deployment.yaml.backup` already exists from previous deployment
- **WHEN** the deployment pipeline reaches backup creation step
- **THEN** the existing backup file is overwritten
- **AND** the backup file contains the current `k8s/deployment.yaml` content
- **AND** the deployment pipeline continues to next step
- **AND** no error is logged

#### Scenario: Deployment manifest missing
- **GIVEN** `k8s/deployment.yaml` does not exist
- **WHEN** the deployment pipeline reaches backup creation step
- **THEN** an error is logged
- **AND** the deployment pipeline halts
- **AND** no backup is created

### Requirement: Rollback can restore from backup
The rollback function MUST restore the deployment state from `k8s/deployment.yaml.backup`. The rollback MUST handle resource version conflicts and use appropriate strategies to apply the backup.

#### Scenario: Successful rollback with backup present
- **GIVEN** `k8s/deployment.yaml.backup` exists
- **WHEN** a deployment failure triggers rollback
- **THEN** the backup file is transferred to the VM
- **AND** Kubernetes applies the backup deployment manifest
- **AND** the deployment returns to previous state
- **AND** rollback logs success message

#### Scenario: Rollback encounters resource version conflict
- **GIVEN** backup file exists and Kubernetes reports resource version conflict
- **WHEN** rollback applies the backup
- **THEN** rollback attempts to apply with `--force` flag
- **OR** rollback deletes and recreates the deployment
- **AND** deployment is restored to previous state
- **AND** rollback logs success message with conflict resolution strategy used

#### Scenario: Rollback with missing backup file
- **GIVEN** `k8s/deployment.yaml.backup` does not exist
- **WHEN** a deployment failure triggers rollback
- **THEN** rollback logs error message "No backup deployment manifest found"
- **AND** rollback exits with non-zero code
- **AND** manual intervention is required

docker-cleanup-idempotency/spec.md
## ADDED Requirements

### Requirement: Docker cleanup removes containers before images
The cleanup script MUST stop all containers with label `app=my-ag-ui-app` before attempting to delete Docker images. The script MUST remove stopped containers before deleting images to prevent conflict errors.

#### Scenario: Cleanup with stopped containers referencing images
- **GIVEN** Docker has stopped containers with label `app=my-ag-ui-app` referencing the image to be deleted
- **WHEN** the cleanup script runs
- **THEN** all stopped containers with that label are removed
- **AND** no conflict errors occur during image deletion
- **AND** the cleanup script exits with code 0

#### Scenario: Cleanup with no containers
- **GIVEN** no containers exist with label `app=my-ag-ui-app`
- **WHEN** the cleanup script runs
- **THEN** the cleanup script exits with code 0
- **AND** no error messages are logged
- **AND** the script continues to image deletion phase

#### Scenario: Cleanup with running containers
- **GIVEN** Docker has running containers with label `app=my-ag-ui-app`
- **WHEN** the cleanup script runs
- **THEN** running containers are stopped
- **AND** stopped containers are removed
- **AND** images can be deleted without conflict errors
- **AND** the cleanup script exits with code 0

### Requirement: Cleanup handles non-critical failures gracefully
The cleanup script MUST log warnings for non-critical failures but MUST NOT fail the deployment pipeline. The script MUST continue execution after logging warnings for cleanup failures.

#### Scenario: Cleanup encounters non-critical error
- **GIVEN** a non-critical cleanup operation fails (e.g., unused images cannot be removed)
- **WHEN** the error occurs
- **THEN** the script logs a warning message
- **AND** the script continues with next cleanup phase
- **AND** the deployment pipeline is not blocked

#### Scenario: Cleanup encounters critical error
- **GIVEN** Docker daemon is not accessible
- **WHEN** the cleanup script attempts cleanup
- **THEN** the script logs an error message
- **AND** the script exits with non-zero code
- **AND** the deployment pipeline is halted



## Design

## Context

Current deployment pipeline has three critical bugs:

1. **Docker cleanup conflicts**: `cleanup-resources.sh` attempts to delete Docker images without first removing containers that reference them. This causes the script to fail when images are being used by stopped containers.

2. **False negative build failure**: `build-docker-image.sh` reports failure even when Docker builds complete successfully. The script's error detection logic incorrectly interprets certain conditions as failures.

3. **Missing rollback backups**: The rollback function in `deploy-all.sh` requires `k8s/deployment.yaml.backup`, but no script creates this backup before deployment changes. Rollback always fails with "No backup deployment manifest found."

These issues make deployments unreliable and prevent automated recovery on failures.

## Goals / Non-Goals

**Goals:**
- Make Docker cleanup idempotent: containers stopped and removed before image deletion
- Fix build script error detection to correctly identify success/failure states
- Create deployment manifest backups before applying changes
- Enable rollback to restore previous state on failure
- Ensure all changes are verifiable through automated checks

**Non-Goals:**
- Changing Kubernetes deployment strategy (remain rolling update)
- Modifying Docker build optimization or caching behavior
- Adding manual rollback approvals (rollback remains automated)
- Changing deployment manifest format or structure

## Decisions

### Decision 1: Docker Cleanup Order
**Choice**: Stop containers, remove containers, then delete images

**Rationale**:
- Docker prevents image deletion when referenced by any container (running or stopped)
- Stopping containers first ensures no processes are writing to layers
- Removing containers frees up image references
- This order ensures cleanup completes without conflicts

**Alternatives Considered**:
- Force delete (`docker rmi -f`): Faster but could break running deployments
- Ignore cleanup errors: Leaves resources consuming disk space
- Delete only unused containers: Misses stopped containers referencing images

### Decision 2: Backup Creation Point
**Choice**: Create backup after Step 3 (tagging) but before Step 4 (registry setup)

**Rationale**:
- `k8s/deployment.yaml` is the source of truth for backup
- Create backup before any Kubernetes changes to capture stable state
- Back up before registry setup ensures we can rollback to known-good state
- Backup location: `k8s/deployment.yaml.backup` (as expected by rollback function)

**Alternatives Considered**:
- Backup at start of deploy-all.sh: Too early, may miss pre-deployment state changes
- Backup after Kubernetes deployment: Too late, rollback needs previous state
- Multiple backups (timestamped): Adds complexity, single backup sufficient

### Decision 3: Build Verification Strategy
**Choice**: Verify image exists in Docker AND check build exit code

**Rationale**:
- Docker build exit code (0 = success, non-zero = failure) is authoritative
- Verify image exists: `docker images my-ag-ui-app:latest` query
- Combine both checks to eliminate false negatives
- Build output captured but not used for success determination

**Alternatives Considered**:
- Parse build output text: Brittle, output format varies between Docker versions
- Only check exit code: May miss cases where build claims success but image missing
- Add build hash verification: Overkill, adds complexity without clear benefit

### Decision 4: Backup File Handling
**Choice**: Overwrite existing backup file silently

**Rationale**:
- One backup file keeps rollback simple
- Overwriting ensures backup always matches last successful state
- Silent overwrite avoids blocking deployments on backup existence
- Backup created on every deployment attempt

**Alternatives Considered**:
- Fail if backup exists: Blocks deployments unnecessarily
- Create timestamped backups: Adds complexity, unnecessary for single-rollback pattern
- Skip backup creation on retry: Breaks rollback for retries

### Decision 5: Error Handling Non-Critical Failures
**Choice**: Log warnings but continue for non-critical cleanup failures

**Rationale**:
- Cleanup is preparatory, not critical to deployment
- Failures in cleanup shouldn't block deployment
- Warnings logged for visibility while allowing pipeline to proceed
- Critical failures (Docker daemon, VM access) still fail immediately

**Alternatives Considered**:
- Fail on any cleanup error: Too strict, blocks deployments for minor issues
- Ignore all cleanup errors: Too lax, hides problems
- Use `set -e` everywhere: Fails on any error, including non-critical

## Risks / Trade-offs

**Risk**: Removing containers during cleanup could affect other processes
→ **Mitigation**: Cleanup only removes containers with label `app=my-ag-ui-app`, not all containers

**Risk**: Overwriting backup file loses previous backup state
→ **Mitigation**: Backup only created after image build success, so backup is always valid. One backup is sufficient for rollback to previous successful deployment.

**Risk**: Build verification might have race conditions
→ **Mitigation**: Image query is synchronous with build completion, no async operations between them

**Trade-off**: Cleanup is more aggressive (removes stopped containers)
→ **Justification**: Stopped containers consuming disk space should be removed during cleanup

**Trade-off**: Build script is slightly more complex (dual verification)
→ **Justification**: Eliminates false negative failures, reliability > simplicity

## Current Task Context

## Current Task
- 1.1 Modify cleanup-resources.sh to stop containers with label `app=my-ag-ui-app` before image deletion
