# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

## Why

The Kubernetes deployment is failing with `ImagePullBackOff` errors because the deployment manifest references `my-ag-ui-app:latest` (which attempts to pull from Docker Hub) instead of `localhost:32000/my-ag-ui-app:latest` (the local microk8s registry). Despite the successful implementation of image pushing to the local registry in the `fix-docker-push-to-vm-registry` change, the deployment configuration was not updated to use the local registry image reference, causing pods to fail during image pull.

## What Changes

- Update `k8s/deployment.yaml` to reference `localhost:32000/my-ag-ui-app:latest` instead of `my-ag-ui-app:latest`
- Verify that the deployment correctly pulls images from the local microk8s registry
- Update any documentation that references the deployment image configuration
- Ensure the deployment script properly handles the updated image reference

## Capabilities

### New Capabilities
- `k8s-registry-image-reference`: Configures Kubernetes deployment to use local microk8s registry image references for reliable local deployments

### Modified Capabilities
- `docker-image-build-load`: The deployment phase now requires the image to be tagged and pushed to the local registry before deployment

## Impact

- **Affected Files**: `k8s/deployment.yaml`, deployment documentation
- **Kubernetes Deployment**: Pods will now pull images from `localhost:32000/my-ag-ui-app:latest` instead of Docker Hub
- **Deployment Flow**: The deployment script will continue to build, tag, and push images to the local registry, and the Kubernetes deployment will successfully pull from that registry
- **No Breaking Changes**: This is a configuration fix that aligns the deployment with the existing registry push workflow

## Specifications

docker-image-build-load/spec.md
## MODIFIED Requirements

### Requirement: Docker image load into VM
The deployment process SHALL verify Docker is available in multipass VM before tagging and pushing the built Docker image to the local microk8s registry at localhost:32000. Docker availability includes both Docker CLI installation and daemon operational status.

#### Scenario: Successful image tag and push with Docker available
- **WHEN** deployment script executes image tag command within VM
- **AND** Docker is installed in VM
- **AND** Docker daemon is running in VM
- **THEN** script SHALL tag the image as localhost:32000/my-ag-ui-app:latest within VM
- **THEN** script SHALL push the tagged image to the local microk8s registry
- **AND** script SHALL verify image is available in the registry
- **AND** script SHALL log to successful tag and push

#### Scenario: Image tag failure due to Docker not installed in VM
- **WHEN** deployment script attempts to execute image tag command
- **AND** Docker is not installed in VM
- **THEN** script SHALL log a clear error that Docker is not available in VM
- **AND** script SHALL provide instructions to install Docker in VM
- **AND** script SHALL exit with a non-zero status code
- **AND** script SHALL NOT attempt to restart deployment

#### Scenario: Image tag failure due to Docker daemon not running in VM
- **WHEN** deployment script attempts to execute image tag command
- **AND** Docker is installed in VM
- **AND** Docker daemon is not running in VM
- **THEN** script SHALL log a clear error that Docker daemon is not running
- **AND** script SHALL provide instructions to start Docker daemon
- **AND** script SHALL exit with a non-zero status code
- **AND** script SHALL NOT attempt to restart deployment

#### Scenario: Image tag or push failure
- **WHEN** image tag or push command fails
- **AND** Docker is available in VM
- **AND** failure is not related to Docker availability
- **THEN** script SHALL log error with context
- **AND** script SHALL exit with a non-zero status code
- **AND** script SHALL NOT attempt to restart deployment

#### Scenario: Docker availability verification before image operations
- **WHEN** deployment script is about to tag or push image
- **THEN** script SHALL verify Docker CLI is available in VM
- **AND** script SHALL verify Docker daemon is running in VM
- **AND** script SHALL log Docker availability status
- **AND** script SHALL proceed with image operations only if Docker is available

### Requirement: Pod restart with new image
The deployment process SHALL restart Kubernetes deployment to trigger pod recreation with the newly pushed registry image.

#### Scenario: Successful deployment restart
- **WHEN** deployment script restarts deployment
- **THEN** script SHALL use kubectl rollout restart command
- **AND** script SHALL wait for new pod to be created
- **AND** script SHALL verify that pod successfully pulls image from localhost:32000/my-ag-ui-app:latest
- **AND** script SHALL verify pod status reaches Running state without ImagePullBackOff errors

#### Scenario: Deployment restart failure
- **WHEN** deployment restart command fails
- **THEN** script SHALL log restart error with context
- **AND** script SHALL provide recovery suggestions
- **AND** script SHALL exit with a non-zero status code

### Requirement: Pod health verification
The deployment process SHALL verify that pod passes readiness and liveness probes after successfully pulling the image from the local registry.

#### Scenario: Pod becomes healthy
- **WHEN** pod starts successfully
- **THEN** script SHALL verify pod status is Running
- **AND** script SHALL verify readiness probe passes
- **AND** script SHALL verify liveness probe passes
- **AND** script SHALL log to successful health check

#### Scenario: Pod fails health checks
- **WHEN** pod fails readiness or liveness probes
- **THEN** script SHALL log which probe failed
- **AND** script SHALL provide pod logs for debugging
- **AND** script SHALL exit with a non-zero status code

### Requirement: Application accessibility verification
The deployment process SHALL verify that the application is accessible via ingress endpoint after pods are running with the local registry image.

#### Scenario: Application is accessible
- **WHEN** deployment script tests ingress endpoint
- **THEN** script SHALL verify application responds to HTTP requests
- **AND** script SHALL log accessible URL
- **AND** script SHALL confirm successful deployment

#### Scenario: Application is not accessible
- **WHEN** ingress endpoint is not accessible
- **THEN** script SHALL log accessibility failure
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL suggest checking ingress configuration

k8s-registry-image-reference/spec.md
## ADDED Requirements

### Requirement: Kubernetes deployment uses local registry image reference
The Kubernetes deployment manifest SHALL reference the local microk8s registry image at `localhost:32000/my-ag-ui-app:latest` to ensure pods pull images from the local registry instead of external Docker Hub.

#### Scenario: Deployment manifest references local registry
- **WHEN** the Kubernetes deployment manifest is applied
- **THEN** the deployment SHALL reference `localhost:32000/my-ag-ui-app:latest` as the container image
- **AND** the image reference SHALL NOT attempt to pull from Docker Hub

#### Scenario: Pods successfully pull from local registry
- **WHEN** Kubernetes creates a new pod using the deployment
- **THEN** the pod SHALL successfully pull the image from `localhost:32000/my-ag-ui-app:latest`
- **AND** the pod SHALL NOT encounter `ImagePullBackOff` errors
- **AND** the pod SHALL reach Running state

#### Scenario: No external registry access required
- **WHEN** the deployment is executed within the multipass VM
- **THEN** the deployment SHALL complete successfully without requiring external network access
- **AND** all image pulls SHALL be served by the local microk8s registry

### Requirement: Local registry accessibility verification
The deployment script SHALL verify that the local microk8s registry is accessible at `localhost:32000` before attempting to apply the Kubernetes deployment.

#### Scenario: Registry is accessible before deployment
- **WHEN** the deployment script reaches the Kubernetes deployment phase
- **THEN** the script SHALL verify connectivity to `http://localhost:32000/v2/_catalog`
- **AND** deployment SHALL proceed only if the registry is accessible
- **AND** deployment SHALL fail with a clear error message if the registry is not accessible

#### Scenario: Registry catalog contains expected image
- **WHEN** the deployment script verifies the registry
- **THEN** the script SHALL confirm that `my-ag-ui-app` repository exists in the registry catalog
- **AND** the script SHALL log the registry status for debugging purposes

### Requirement: Deployment configuration compatibility
The Kubernetes deployment SHALL maintain compatibility with all existing deployment settings while only modifying the image reference to use the local registry.

#### Scenario: All deployment settings preserved
- **WHEN** the deployment manifest is updated to use the local registry image
- **THEN** all other deployment settings SHALL remain unchanged
- **AND** replica count SHALL be preserved
- **AND** resource limits and requests SHALL be preserved
- **AND** liveness and readiness probes SHALL be preserved
- **AND** environment variable mappings SHALL be preserved
- **AND** secret references SHALL be preserved

#### Scenario: Rolling update behavior maintained
- **WHEN** the deployment is updated with the new image reference
- **THEN** Kubernetes SHALL perform a rolling update
- **AND** old pods SHALL be terminated gracefully
- **AND** new pods SHALL be created using the local registry image
- **AND** service availability SHALL be maintained during the update



## Design

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

## Current Task Context

## Current Task
- 1.1 Review current k8s/deployment.yaml to identify image reference
