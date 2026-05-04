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
