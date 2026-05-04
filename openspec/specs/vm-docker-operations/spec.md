# VM Registry Push

## Purpose

Capability for pushing Docker images to microk8s registry from within the VM. This enables image distribution by executing tag and push operations where the registry is accessible at localhost:32000.

## Requirements

### Requirement: System must tag Docker images for local registry within VM
The deployment process SHALL tag Docker images with the local registry endpoint within the VM context to make them addressable for push operations to the microk8s registry.

#### Scenario: Successful image tagging within VM
- **WHEN** deployment script executes docker tag command via multipass exec
- **AND** source image exists in VM's Docker daemon
- **THEN** script SHALL tag image as `localhost:32000/my-ag-ui-app:latest` within the VM
- **AND** script SHALL verify tag was created successfully
- **AND** script SHALL log successful tagging

#### Scenario: Image tagging failure due to source image not found in VM
- **WHEN** deployment script attempts to tag image
- **AND** source image does not exist in VM's Docker daemon
- **THEN** script SHALL log error that source image is not available in VM
- **AND** script SHALL provide instructions to build image first
- **AND** script SHALL exit with non-zero status code

### Requirement: System must push images to microk8s registry from within VM
The deployment process SHALL push tagged Docker images to microk8s local registry using standard Docker push commands executed from within the VM, where localhost:32000 resolves to the registry.

#### Scenario: Successful image push to registry from VM
- **WHEN** deployment script executes docker push command via multipass exec
- **AND** image is tagged for local registry within the VM
- **AND** registry is accessible at localhost:32000 within the VM
- **THEN** script SHALL push image to registry
- **AND** script SHALL verify push completed successfully
- **AND** script SHALL log successful push with image details

#### Scenario: Image push failure due to registry not accessible in VM
- **WHEN** deployment script attempts to push image
- **AND** registry is not accessible at localhost:32000 within the VM
- **THEN** script SHALL log error that registry is not available in VM
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL exit with non-zero status code

#### Scenario: Image push failure due to network issues
- **WHEN** deployment script attempts to push image
- **AND** transient network issues occur within the VM
- **THEN** script SHALL implement retry logic with exponential backoff
- **AND** script SHALL log retry attempts
- **AND** script SHALL succeed if push succeeds within retry limit
- **AND** script SHALL fail with clear error if all retries exhausted

### Requirement: System must verify registry accessibility within VM
The deployment process SHALL verify that microk8s registry is accessible at localhost:32000 from within the VM before attempting push operations.

#### Scenario: Registry is accessible and ready
- **WHEN** deployment script checks registry status via multipass exec
- **AND** registry is enabled and running within the VM
- **THEN** script SHALL confirm registry is accessible at localhost:32000 within the VM
- **AND** script SHALL display registry status
- **AND** script SHALL proceed with push operations

#### Scenario: Registry is not accessible
- **WHEN** deployment script checks registry status via multipass exec
- **AND** registry is not accessible at localhost:32000 within the VM
- **THEN** script SHALL log error that registry is unavailable
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL exit with non-zero status code
- **AND** script SHALL NOT attempt push operations

### Requirement: System must provide clear error messages for registry operations
The deployment process SHALL provide actionable error messages with specific recovery steps for each failure scenario in registry push operations.

#### Scenario: Error message includes context
- **WHEN** any registry operation fails
- **THEN** script SHALL log error with specific failure reason
- **AND** script SHALL include relevant command that failed
- **AND** script SHALL include error output if available

#### Scenario: Error message includes recovery suggestions
- **WHEN** any registry operation fails
- **THEN** script SHALL provide specific recovery steps
- **AND** script SHALL suggest checking prerequisites (microk8s, Docker daemon in VM)
- **AND** script SHALL suggest retrying for transient failures
- **AND** script SHALL provide manual intervention steps if automated recovery fails
