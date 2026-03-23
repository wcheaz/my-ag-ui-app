# Docker Image Build and Load (Delta)

## MODIFIED Requirements

### Requirement: Docker image load into VM
The deployment process SHALL verify Docker is available in the multipass VM before loading the built Docker image into the VM's Docker daemon. Docker availability includes both Docker CLI installation and daemon operational status.

#### Scenario: Successful image load with Docker available
- **WHEN** the deployment script executes the image load command
- **AND** Docker is installed in the VM
- **AND** Docker daemon is running in the VM
- **THEN** the script SHALL save the image using docker save
- **THEN** the script SHALL pipe the image to multipass exec with docker load
- **AND** the script SHALL verify the image is available in the VM
- **AND** the script SHALL log the successful load

#### Scenario: Image load failure due to Docker not installed in VM
- **WHEN** the deployment script attempts to execute the image load command
- **AND** Docker is not installed in the VM
- **THEN** the script SHALL log a clear error that Docker is not available in the VM
- **AND** the script SHALL provide instructions to install Docker in the VM
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT attempt to restart the deployment

#### Scenario: Image load failure due to Docker daemon not running in VM
- **WHEN** the deployment script attempts to execute the image load command
- **AND** Docker is installed in the VM
- **AND** Docker daemon is not running in the VM
- **THEN** the script SHALL log a clear error that Docker daemon is not running
- **AND** the script SHALL provide instructions to start the Docker daemon
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT attempt to restart the deployment

#### Scenario: Image load failure
- **WHEN** the image load command fails
- **AND** Docker is available in the VM
- **AND** the failure is not related to Docker availability
- **THEN** the script SHALL log the load error with context
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT attempt to restart the deployment

#### Scenario: Docker availability verification before image load
- **WHEN** the deployment script is about to load the image
- **THEN** the script SHALL verify Docker CLI is available in the VM
- **AND** the script SHALL verify Docker daemon is running in the VM
- **AND** the script SHALL log the Docker availability status
- **AND** the script SHALL proceed with image load only if Docker is available
