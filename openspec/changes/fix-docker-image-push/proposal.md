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
