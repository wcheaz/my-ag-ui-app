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
