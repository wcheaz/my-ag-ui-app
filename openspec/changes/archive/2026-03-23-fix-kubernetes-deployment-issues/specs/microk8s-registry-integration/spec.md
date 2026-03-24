# Microk8s Registry Integration

## Purpose

Capability for using microk8s's built-in local registry to distribute Docker images for Kubernetes deployment. This enables standard Docker push/pull workflow while keeping all image distribution within the VM, eliminating external registry dependencies.

## ADDED Requirements

### Requirement: System must enable microk8s local registry
The deployment process SHALL enable microk8s's built-in registry add-on to provide a local, trusted registry for image distribution.

#### Scenario: Successful registry enablement
- **WHEN** deployment script executes `microk8s enable registry` command
- **AND** microk8s is installed and running
- **THEN** script SHALL enable registry add-on
- **AND** script SHALL verify registry is running at localhost:32000
- **AND** script SHALL log successful enablement

#### Scenario: Registry enablement failure due to microk8s not running
- **WHEN** deployment script attempts to enable registry
- **AND** microk8s is not running
- **THEN** script SHALL log clear error that microk8s is not available
- **AND** script SHALL provide instructions to start microk8s
- **AND** script SHALL exit with non-zero status code
- **AND** script SHALL NOT proceed with deployment

#### Scenario: Registry enablement failure due to port conflict
- **WHEN** deployment script attempts to enable registry
- **AND** port 32000 is already in use
- **THEN** script SHALL log error about port conflict
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL exit with non-zero status code

#### Scenario: Registry is already enabled
- **WHEN** deployment script attempts to enable registry
- **AND** registry is already enabled and running
- **THEN** script SHALL verify registry is accessible
- **AND** script SHALL log that registry is already enabled
- **AND** script SHALL proceed with deployment

### Requirement: System must tag Docker images for local registry
The deployment process SHALL tag Docker images with the local registry endpoint to make them addressable for push operations.

#### Scenario: Successful image tagging
- **WHEN** deployment script executes docker tag command
- **AND** source image exists in Docker daemon
- **THEN** script SHALL tag image as `localhost:32000/my-ag-ui-app:latest`
- **AND** script SHALL verify tag was created successfully
- **AND** script SHALL log successful tagging

#### Scenario: Image tagging failure due to source image not found
- **WHEN** deployment script attempts to tag image
- **AND** source image does not exist in Docker daemon
- **THEN** script SHALL log error that source image is not available
- **AND** script SHALL provide instructions to build image first
- **AND** script SHALL exit with non-zero status code

#### Scenario: Image tagging failure due to Docker daemon not running
- **WHEN** deployment script attempts to tag image
- **AND** Docker daemon is not running
- **THEN** script SHALL log error that Docker daemon is not available
- **AND** script SHALL provide instructions to start Docker daemon
- **AND** script SHALL exit with non-zero status code

### Requirement: System must push images to local registry
The deployment process SHALL push tagged Docker images to microk8s local registry using standard Docker push commands.

#### Scenario: Successful image push to registry
- **WHEN** deployment script executes docker push command
- **AND** image is tagged for local registry
- **AND** registry is accessible at localhost:32000
- **THEN** script SHALL push image to registry
- **AND** script SHALL verify push completed successfully
- **AND** script SHALL log successful push with image details

#### Scenario: Image push failure due to registry not accessible
- **WHEN** deployment script attempts to push image
- **AND** registry is not accessible at localhost:32000
- **THEN** script SHALL log error that registry is not available
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL exit with non-zero status code

#### Scenario: Image push failure due to network issues
- **WHEN** deployment script attempts to push image
- **AND** transient network issues occur
- **THEN** script SHALL implement retry logic with exponential backoff
- **AND** script SHALL log retry attempts
- **AND** script SHALL succeed if push succeeds within retry limit
- **AND** script SHALL fail with clear error if all retries exhausted

#### Scenario: Image push failure due to invalid tag
- **WHEN** deployment script attempts to push image
- **AND** image tag is invalid or not found
- **THEN** script SHALL log error about invalid image tag
- **AND** script SHALL provide instructions to check image tagging
- **AND** script SHALL exit with non-zero status code

### Requirement: System must verify registry operations
The deployment process SHALL verify that registry is enabled and accessible before attempting push operations.

#### Scenario: Registry is accessible and ready
- **WHEN** deployment script checks registry status
- **AND** registry is enabled and running
- **THEN** script SHALL confirm registry is accessible at localhost:32000
- **AND** script SHALL display registry status
- **AND** script SHALL proceed with push operations

#### Scenario: Registry is not accessible
- **WHEN** deployment script checks registry status
- **AND** registry is not accessible
- **THEN** script SHALL log error that registry is unavailable
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL exit with non-zero status code
- **AND** script SHALL NOT attempt push operations

### Requirement: System must provide clear error messages and recovery suggestions
The deployment process SHALL provide actionable error messages with specific recovery steps for each failure scenario in registry operations.

#### Scenario: Error message includes context
- **WHEN** any registry operation fails
- **THEN** script SHALL log error with specific failure reason
- **AND** script SHALL include relevant command that failed
- **AND** script SHALL include error output if available

#### Scenario: Error message includes recovery suggestions
- **WHEN** any registry operation fails
- **THEN** script SHALL provide specific recovery steps
- **AND** script SHALL suggest checking prerequisites (microk8s, Docker daemon)
- **AND** script SHALL suggest retrying for transient failures
- **AND** script SHALL provide manual intervention steps if automated recovery fails
