# VM Docker Setup

## Purpose

Capability for installing, configuring, and verifying Docker daemon availability in multipass VMs. This ensures Docker is properly installed and running before attempting to load images into the VM's Docker daemon.

## Requirements

### Requirement: System must check for Docker installation in VM
The system SHALL check if Docker is already installed in the multipass VM before attempting installation.

#### Scenario: Docker is already installed
- **WHEN** the deployment script checks for Docker in the VM
- **AND** Docker CLI is available
- **THEN** the script SHALL skip Docker installation
- **AND** the script SHALL proceed to verify Docker daemon status
- **AND** the script SHALL log that Docker is already installed

#### Scenario: Docker is not installed
- **WHEN** the deployment script checks for Docker in the VM
- **AND** Docker CLI is not available
- **THEN** the script SHALL proceed with Docker installation
- **AND** the script SHALL log that Docker installation is required

#### Scenario: Docker check fails
- **WHEN** the deployment script cannot determine Docker installation status
- **THEN** the script SHALL log the error with context
- **AND** the script SHALL assume Docker is not installed
- **AND** the script SHALL proceed with Docker installation

### Requirement: System must install Docker in VM if not present
The system SHALL install Docker in the multipass VM using Docker's official installation script for Ubuntu.

#### Scenario: Successful Docker installation
- **WHEN** the deployment script executes the Docker installation command
- **AND** the VM has network connectivity
- **AND** the VM has sufficient disk space
- **THEN** Docker packages SHALL be installed successfully
- **AND** Docker daemon SHALL be started automatically
- **AND** the script SHALL log the successful installation
- **AND** the script SHALL log the Docker version installed

#### Scenario: Docker installation fails due to network issues
- **WHEN** the deployment script attempts to install Docker
- **AND** the VM cannot reach Docker's installation servers
- **THEN** the script SHALL log a clear network error message
- **AND** the script SHALL provide manual installation instructions
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

#### Scenario: Docker installation fails due to insufficient disk space
- **WHEN** the deployment script attempts to install Docker
- **AND** the VM has insufficient disk space
- **THEN** the script SHALL log a disk space error message
- **AND** the script SHALL report the available and required space
- **THEN** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

#### Scenario: Docker installation fails with unknown error
- **WHEN** the deployment script attempts to install Docker
- **AND** the installation fails with an unexpected error
- **THEN** the script SHALL log the error with full context
- **AND** the script SHALL provide diagnostic information
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

### Requirement: System must add VM user to docker group
The system SHALL add the default VM user to the docker group to enable Docker commands without sudo.

#### Scenario: User successfully added to docker group
- **WHEN** the deployment script adds the user to the docker group
- **THEN** the user SHALL be added to the docker group
- **AND** the script SHALL log the successful group addition
- **AND** the script SHALL activate the group membership

#### Scenario: Group membership activation
- **WHEN** the deployment script activates the docker group membership
- **THEN** the user SHALL be able to run Docker commands without sudo
- **AND** the script SHALL verify group membership is active
- **AND** the script SHALL log that group membership is active

#### Scenario: Group addition fails
- **WHEN** the deployment script attempts to add the user to the docker group
- **AND** the group addition fails
- **THEN** the script SHALL log the error with context
- **AND** the script SHALL provide manual group addition instructions
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

### Requirement: System must verify Docker daemon is running
The system SHALL verify that the Docker daemon is running and ready to accept commands before proceeding with image loading.

#### Scenario: Docker daemon is running
- **WHEN** the deployment script checks Docker daemon status
- **AND** the Docker daemon is running
- **THEN** the script SHALL confirm daemon is operational
- **AND** the script SHALL log that Docker daemon is running
- **AND** the script SHALL proceed with image loading

#### Scenario: Docker daemon is not running
- **WHEN** the deployment script checks Docker daemon status
- **AND** the Docker daemon is not running
- **THEN** the script SHALL attempt to start the Docker daemon
- **AND** the script SHALL wait for the daemon to become ready
- **AND** the script SHALL verify the daemon is operational

#### Scenario: Docker daemon fails to start
- **WHEN** the deployment script attempts to start the Docker daemon
- **AND** the daemon fails to start
- **THEN** the script SHALL log the error with context
- **AND** the script SHALL provide diagnostic information
- **AND** the script SHALL provide manual troubleshooting steps
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

#### Scenario: Docker daemon check times out
- **WHEN** the deployment script waits for Docker daemon to become ready
- **AND** the daemon does not become ready within the timeout period
- **THEN** the script SHALL log a timeout error
- **AND** the script SHALL report the timeout period
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

### Requirement: System must verify Docker commands work without sudo
The system SHALL verify that Docker commands can be executed without sudo privileges in the VM.

#### Scenario: Docker commands work without sudo
- **WHEN** the deployment script tests Docker commands
- **AND** the user has docker group membership
- **THEN** Docker commands SHALL execute successfully without sudo
- **AND** the script SHALL log that Docker commands work without sudo
- **AND** the script SHALL proceed with image loading

#### Scenario: Docker commands require sudo
- **WHEN** the deployment script tests Docker commands
- **AND** Docker commands fail without sudo
- **THEN** the script SHALL attempt to fix the group membership issue
- **AND** the script SHALL verify the fix was successful
- **AND** the script SHALL log the resolution

#### Scenario: Docker commands fail with or without sudo
- **WHEN** the deployment script tests Docker commands
- **AND** Docker commands fail even with sudo
- **THEN** the script SHALL log a critical error
- **AND** the script SHALL provide diagnostic information
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

### Requirement: System must wait for Docker daemon to be ready after installation
The system SHALL wait for the Docker daemon to be fully initialized and ready to accept commands after installation.

#### Scenario: Docker daemon becomes ready within timeout
- **WHEN** the deployment script waits for Docker daemon to be ready
- **AND** the daemon becomes ready within the timeout period
- **THEN** the script SHALL proceed with image loading
- **AND** the script SHALL log that Docker daemon is ready
- **AND** the script SHALL report the time taken for daemon to be ready

#### Scenario: Docker daemon readiness check uses exponential backoff
- **WHEN** the deployment script polls for Docker daemon readiness
- **THEN** the script SHALL use exponential backoff between checks
- **AND** the script SHALL log each readiness check attempt
- **AND** the script SHALL not overwhelm the system with frequent checks

#### Scenario: Docker daemon readiness check exceeds maximum attempts
- **WHEN** the deployment script polls for Docker daemon readiness
- **AND** the daemon does not become ready after maximum attempts
- **THEN** the script SHALL log a timeout error
- **AND** the script SHALL report the number of attempts made
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT proceed with image loading

### Requirement: System must provide comprehensive error messages and recovery guidance
The system SHALL provide clear, actionable error messages and recovery steps when Docker setup fails.

#### Scenario: Network connectivity error
- **WHEN** Docker installation fails due to network issues
- **THEN** the script SHALL provide a clear error message
- **AND** the script SHALL explain the network connectivity requirement
- **AND** the script SHALL suggest checking VM network configuration
- **AND** the script SHALL provide manual installation commands

#### Scenario: Permission error
- **WHEN** Docker setup fails due to permission issues
- **THEN** the script SHALL provide a clear error message
- **AND** the script SHALL explain the permission requirement
- **AND** the script SHALL suggest checking user permissions
- **AND** the script SHALL provide manual permission fix commands

#### Scenario: Disk space error
- **WHEN** Docker installation fails due to insufficient disk space
- **THEN** the script SHALL provide a clear error message
- **AND** the script SHALL report available and required space
- **AND** the script SHALL suggest cleaning up disk space
- **AND** the script SHALL provide commands to check disk usage

#### Scenario: Generic error with diagnostic information
- **WHEN** Docker setup fails with an unknown error
- **THEN** the script SHALL log the full error output
- **AND** the script SHALL provide system diagnostic information
- **AND** the script SHALL suggest manual troubleshooting steps
- **AND** the script SHALL provide a way to access the VM for manual intervention

### Requirement: System must log Docker setup progress
The system SHALL log each step of the Docker setup process to provide visibility into the installation progress.

#### Scenario: Logging Docker check
- **WHEN** the deployment script checks for Docker installation
- **THEN** the script SHALL log the check operation
- **AND** the script SHALL log the result (found/not found)
- **AND** the script SHALL include a timestamp

#### Scenario: Logging Docker installation
- **WHEN** the deployment script installs Docker
- **THEN** the script SHALL log the installation start
- **AND** the script SHALL log installation progress
- **AND** the script SHALL log the installation completion
- **AND** the script SHALL log the Docker version installed

#### Scenario: Logging Docker daemon verification
- **WHEN** the deployment script verifies Docker daemon status
- **THEN** the script SHALL log the verification attempt
- **AND** the script SHALL log the daemon status
- **AND** the script SHALL log any issues encountered

#### Scenario: Logging group membership setup
- **WHEN** the deployment script sets up docker group membership
- **THEN** the script SHALL log the group addition attempt
- **AND** the script SHALL log the activation attempt
- **AND** the script SHALL log the final status

### Requirement: System must integrate with existing deployment flow
The system SHALL integrate Docker setup into the existing deployment flow at the appropriate point.

#### Scenario: Docker setup occurs after VM provisioning
- **WHEN** the deployment script completes VM provisioning
- **THEN** the script SHALL call Docker setup function
- **AND** the script SHALL wait for Docker setup to complete
- **AND** the script SHALL proceed to next deployment phase

#### Scenario: Docker setup occurs before image loading
- **WHEN** the deployment script is about to load Docker images
- **THEN** Docker setup SHALL already be complete
- **AND** Docker daemon SHALL be verified as running
- **AND** the script SHALL proceed with image loading

#### Scenario: Docker setup failure stops deployment
- **WHEN** Docker setup fails
- **THEN** the deployment script SHALL stop
- **AND** the script SHALL NOT attempt image loading
- **AND** the script SHALL NOT proceed with Kubernetes deployment
- **AND** the script SHALL exit with a non-zero status code
