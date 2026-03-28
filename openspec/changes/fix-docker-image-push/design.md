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
