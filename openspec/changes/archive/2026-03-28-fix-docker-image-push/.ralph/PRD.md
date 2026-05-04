# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

## Why

The Docker image push to the microk8s registry fails during verification despite the push operation completing successfully. The deployment log shows that `docker push` executes successfully within the VM, but the subsequent verification step fails after 7 retry attempts with exponential backoff. The root cause is that the verification curl command runs on the host machine instead of within the VM context, where the registry is actually running at `localhost:32000`. This causes the verification to fail because it cannot reach the registry that exists only inside the VM.

## What Changes

- Fix the image verification step in [`deploy_scripts/push-docker-image.sh`](deploy_scripts/push-docker-image.sh:503) to execute the curl command within the VM context using `multipass exec $VM_NAME`
- Change the verification command from `curl -s "http://localhost:32000/v2/my-ag-ui-app/tags/list"` to `multipass exec "$VM_NAME" -- curl -s "http://localhost:32000/v2/my-ag-ui-app/tags/list"`
- This ensures the verification reaches the registry running inside the VM, matching the behavior of the pre-flight registry check at line 88

## Capabilities

### New Capabilities
None - this is a bug fix to existing functionality.

### Modified Capabilities
None - this fix does not change the requirements or behavior of the deployment system; it corrects an implementation bug where the verification step was executing in the wrong context.

## Impact

- **Affected Code**: [`deploy_scripts/push-docker-image.sh`](deploy_scripts/push-docker-image.sh:503) - single line modification to add `multipass exec "$VM_NAME" --` prefix to the curl command in the verification loop
- **Dependencies**: No new dependencies
- **Systems**: Docker image push verification for microk8s registry deployment
- **Risk**: Low - this is a targeted fix that aligns the verification step with the existing pre-flight check pattern already used in the same script
- **Testing Impact**: The fix enables successful completion of Step 5 in the deployment pipeline, which currently fails due to this verification issue

## Specifications

docker-image-push-verification/spec.md
## ADDED Requirements

### Requirement: Docker image push verification executes within VM context
The system SHALL verify that a Docker image has been successfully pushed to the microk8s registry by executing the verification curl command within the VM context where the registry is running at localhost:32000.

#### Scenario: Successful image push verification after fix
- **WHEN** Docker image push completes successfully within the VM
- **THEN** the verification command executes within the VM context using `multipass exec "$VM_NAME" -- curl -s "http://localhost:32000/v2/my-ag-ui-app/tags/list"`
- **AND** the verification succeeds on the first attempt
- **AND** the deployment pipeline proceeds to the next step without retry delays

#### Scenario: Verification fails when executed from host context
- **WHEN** the verification curl command executes on the host machine instead of within the VM
- **THEN** the verification fails to reach the registry
- **AND** the system retries with exponential backoff up to 7 attempts
- **AND** the deployment pipeline fails after all retries are exhausted

### Requirement: Verification command matches pre-flight registry check pattern
The system SHALL use the same VM context execution pattern for the verification step as used in the pre-flight registry check function to ensure consistency.

#### Scenario: Verification uses multipass exec prefix
- **WHEN** the verification step executes
- **THEN** the command includes `multipass exec "$VM_NAME" --` prefix
- **AND** this matches the pattern used in `verify_microk8s_registry` function at line 88
- **AND** the curl command connects to `http://localhost:32000/v2/my-ag-ui-app/tags/list` within the VM

#### Scenario: Pre-flight registry check succeeds with VM context
- **WHEN** the pre-flight registry check executes at line 88
- **THEN** the command uses `multipass exec "$VM_NAME" -- curl -s --connect-timeout 5 http://localhost:32000/v2/_catalog`
- **AND** the registry responds successfully
- **AND** this confirms that VM context is required for registry access



## Design

## Context

The deployment pipeline uses a microk8s registry running inside a multipass VM at `localhost:32000`. The [`push-docker-image.sh`](deploy_scripts/push-docker-image.sh) script successfully pushes Docker images to this registry from within the VM context, but the subsequent verification step fails because it executes the curl command on the host machine instead of within the VM.

The script already demonstrates the correct pattern in the `verify_microk8s_registry` function at line 88, which uses `multipass exec "$VM_NAME" -- curl` to access the registry. However, the verification loop at line 503 uses `curl` directly without the multipass exec prefix, causing it to fail to reach the registry.

Current constraints:
- The microk8s registry only exists inside the VM at `localhost:32000`
- Docker operations execute within the VM context via multipass exec
- The verification step must run in the same context as the registry to succeed

## Goals / Non-Goals

**Goals:**
- Fix the image verification step to execute within the VM context
- Ensure verification succeeds on the first attempt after successful push
- Align the verification pattern with the existing pre-flight registry check
- Enable the deployment pipeline to complete Step 5 successfully

**Non-Goals:**
- Changing the retry logic or exponential backoff mechanism
- Modifying the pre-flight registry check function
- Adding new verification methods or alternative approaches
- Changing the registry configuration or deployment architecture

## Decisions

### Decision 1: Use multipass exec prefix for verification command

**Choice**: Add `multipass exec "$VM_NAME" --` prefix to the curl command at line 503

**Rationale**:
- This matches the existing pattern used in `verify_microk8s_registry` function at line 88
- The registry is only accessible within the VM context
- This is the minimal change required to fix the bug
- No additional dependencies or configuration changes needed

**Alternatives considered**:
- *Alternative A*: Expose registry to host network via port forwarding
  - Rejected: Requires additional multipass configuration, increases complexity, changes deployment architecture
- *Alternative B*: Use VM IP address instead of localhost
  - Rejected: Requires dynamic IP resolution, less reliable than multipass exec, breaks when VM IP changes
- *Alternative C*: Skip verification step entirely
  - Rejected: Removes safety check, could deploy broken images, violates deployment best practices

### Decision 2: Modify only the verification loop, not the pre-flight check

**Choice**: Keep the pre-flight registry check unchanged and only fix the verification loop

**Rationale**:
- The pre-flight check already works correctly with multipass exec
- Changing working code introduces unnecessary risk
- The bug is isolated to the verification loop at line 503
- This maintains consistency with the existing working pattern

**Alternatives considered**:
- *Alternative A*: Refactor both functions to use a shared helper
  - Rejected: Over-engineering for a single-line fix, increases testing scope
- *Alternative B*: Move verification into the pre-flight check function
  - Rejected: Changes function semantics, breaks separation of concerns, requires more extensive testing

## Risks / Trade-offs

**Risk**: The VM_NAME variable might not be set in the verification loop context
- **Mitigation**: The script sources `deploy_scripts/common.sh` which defines VM_NAME, and the verification loop is in the same function scope where VM_NAME is already used

**Risk**: The multipass exec command might fail if the VM becomes unresponsive
- **Mitigation**: The existing retry logic and error handling in the verification loop will catch and report failures

**Trade-off**: The verification step now depends on multipass exec, which adds a small performance overhead
- **Justification**: The overhead is minimal (<100ms) and the correctness of verification outweighs the performance impact

**Risk**: If the VM is not running, verification will fail with a different error message
- **Mitigation**: The pre-flight checks at lines 254-269 already verify VM accessibility before reaching the verification step

## Migration Plan

**Deployment Steps**:
1. Apply the single-line change to [`deploy_scripts/push-docker-image.sh`](deploy_scripts/push-docker-image.sh:503)
2. Test the fix by running the deployment pipeline: `./deploy-all.sh`
3. Verify that Step 5 (Docker image push) completes successfully
4. Confirm that the image appears in the registry catalog without retry delays

**Rollback Strategy**:
- Revert the single-line change to restore original behavior
- The rollback is trivial and can be done instantly if issues arise
- No data migration or state changes are involved

## Open Questions

None - the fix is straightforward and all technical decisions are resolved.

## Current Task Context

## Current Task
- 1.1 Add multipass exec prefix to verification curl command in deploy_scripts/push-docker-image.sh at line 503
