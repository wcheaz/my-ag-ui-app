## Context

**Background:**
The deployment pipeline was recently enhanced with the `fix-docker-push-to-vm-registry` change to push Docker images to the local microk8s registry (`localhost:32000`). This change successfully implemented:
- Building Docker images on the host
- Tagging images within the VM to reference the local registry
- Pushing tagged images to the microk8s registry at `localhost:32000`

**Current State:**
Despite successful image pushes to the local registry, the Kubernetes deployment manifest (`k8s/deployment.yaml`) still references `my-ag-ui-app:latest`, which causes Kubernetes to attempt pulling the image from Docker Hub instead of the local registry. This results in `ImagePullBackOff` errors during deployment.

**Constraints:**
- The deployment must work entirely within the multipass VM environment (`my-ag-ui-app-k8s`)
- No external registry access should be required for the deployment
- The solution must be compatible with the existing deployment script workflow
- Changes should not break existing functionality or require significant refactoring

**Stakeholders:**
- Development team: Needs reliable local deployment workflow
- Deployment automation: Must seamlessly integrate with existing script

## Goals / Non-Goals

**Goals:**
- Update `k8s/deployment.yaml` to reference `localhost:32000/my-ag-ui-app:latest`
- Ensure pods successfully pull images from the local microk8s registry
- Verify the complete deployment flow works end-to-end
- Document the registry configuration for future reference

**Non-Goals:**
- Changing the image build or push workflow (already implemented)
- Modifying the microk8s registry setup (already configured)
- Implementing external registry support
- Changing the application code or Dockerfile

## Decisions

**Decision 1: Use localhost:32000 in deployment manifest**
- **Choice:** Reference `localhost:32000/my-ag-ui-app:latest` in `k8s/deployment.yaml`
- **Rationale:** The microk8s registry is exposed on port 32000 within the VM. Using `localhost:32000` ensures Kubernetes pulls from the local registry without requiring external network access.
- **Alternatives Considered:**
  - Use cluster IP (10.152.183.199): More complex, harder to remember, may change on registry restart
  - Use node IP with port: Requires knowing VM IP, less portable
  - Use Docker Hub: Defeats the purpose of local registry, requires external access

**Decision 2: No imagePullSecrets required**
- **Choice:** Do not add `imagePullSecrets` to the deployment
- **Rationale:** The local microk8s registry does not require authentication. Adding secrets would add unnecessary complexity without security benefits in a local development environment.
- **Alternatives Considered:**
  - Add imagePullSecrets: Would be required for external registries, but unnecessary for local registry

**Decision 3: Keep existing deployment configuration**
- **Choice:** Maintain all other deployment settings (replicas, resources, probes, environment variables)
- **Rationale:** Only the image reference needs to change. Other settings are working correctly and should not be modified to minimize risk.
- **Alternatives Considered:**
  - Full deployment refactor: Unnecessary, introduces risk, not aligned with the specific issue

## Risks / Trade-offs

**Risk 1: Registry availability**
- **Risk:** The microk8s registry might not be running or accessible when pods attempt to pull images
- **Mitigation:** The deployment script already includes registry verification steps. The registry setup phase ensures the registry is running and accessible before deployment proceeds.

**Risk 2: Image tag mismatch**
- **Risk:** If the image is not pushed to the registry before deployment, pods will still fail
- **Mitigation:** The deployment script enforces the correct sequence: build → tag → push → deploy. The push phase includes verification that the image exists in the registry.

**Risk 3: Port conflicts**
- **Risk:** Port 32000 might be used by another service on the VM
- **Mitigation:** Port 32000 is the standard microk8s registry port and is unlikely to conflict. The registry setup phase verifies accessibility on this port.

**Trade-off: Local-only deployment**
- **Trade-off:** This solution only works for local deployments within the VM. External deployments would require a different registry configuration.
- **Mitigation:** Document this limitation clearly. For production deployments, a separate configuration with an external registry can be added later if needed.

## Migration Plan

**Deployment Steps:**
1. Update `k8s/deployment.yaml` to change the image reference from `my-ag-ui-app:latest` to `localhost:32000/my-ag-ui-app:latest`
2. Test the deployment script to ensure the complete flow works:
   - Docker image builds successfully
   - Image is tagged for local registry
   - Image is pushed to local registry
   - Kubernetes deployment applies the updated manifest
   - Pods successfully pull from local registry
   - Pods reach Running state
3. Verify the application is accessible via ingress
4. Update documentation to reflect the registry configuration

**Rollback Strategy:**
- Revert `k8s/deployment.yaml` to use `my-ag-ui-app:latest` if issues arise
- Delete the failed pods to trigger recreation with the old configuration
- The old deployment script (before registry push changes) can be used as a fallback

**Verification:**
- Check pod status: `microk8s kubectl get pods -l app=my-ag-ui-app`
- Verify pod logs: `microk8s kubectl logs -l app=my-ag-ui-app`
- Confirm image pull: `microk8s kubectl describe pod <pod-name>` should show successful pull from `localhost:32000`

## Open Questions

None at this time. The solution is straightforward and well-defined based on the deploy log analysis.
