# Microk8s Registry Integration

## Purpose

Capability for using microk8s's built-in local registry to distribute Docker images for Kubernetes deployment. This enables standard Docker push/pull workflow with Docker daemon and registry co-located within the VM, eliminating host-to-VM communication issues.

## ADDED Requirements

### Requirement: System must enable microk8s local registry
The deployment process SHALL enable microk8s's built-in registry add-on to provide a local, trusted registry for image distribution within the VM.

#### Scenario: Successful registry enablement
- **WHEN** deployment script executes `microk8s enable registry` command via multipass exec
- **AND** microk8s is installed and running in VM
- **THEN** script SHALL enable registry add-on
- **AND** script SHALL verify registry is running at localhost:32000 within VM
- **AND** script SHALL log successful enablement

#### Scenario: Registry enablement failure due to microk8s not running
- **WHEN** deployment script attempts to enable registry
- **AND** microk8s is not running in VM
- **THEN** script SHALL log clear error that microk8s is not available
- **AND** script SHALL provide instructions to start microk8s
- **AND** script SHALL exit with non-zero status code
- **AND** script SHALL NOT proceed with deployment

#### Scenario: Registry enablement failure due to port conflict
- **WHEN** deployment script attempts to enable registry
- **AND** port 32000 is already in use within VM
- **THEN** script SHALL log error about port conflict
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL exit with non-zero status code

#### Scenario: Registry is already enabled
- **WHEN** deployment script attempts to enable registry
- **AND** registry is already enabled and running
- **THEN** script SHALL verify registry is accessible
- **AND** script SHALL log that registry is already enabled
- **AND** script SHALL proceed with deployment

### Requirement: System must verify registry accessibility within VM
The deployment process SHALL verify that microk8s registry is accessible at localhost:32000 from within the VM before attempting push operations.

#### Scenario: Registry is accessible and ready
- **WHEN** deployment script checks registry status via multipass exec
- **AND** registry is enabled and running within VM
- **THEN** script SHALL confirm registry is accessible at localhost:32000 within VM
- **AND** script SHALL display registry status
- **AND** script SHALL proceed with push operations

#### Scenario: Registry is not accessible
- **WHEN** deployment script checks registry status via multipass exec
- **AND** registry is not accessible at localhost:32000 within VM
- **THEN** script SHALL log error that registry is unavailable
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL exit with non-zero status code
- **AND** script SHALL NOT attempt push operations

### Requirement: System must provide clear error messages for registry operations
The deployment process SHALL provide actionable error messages with specific recovery steps for each failure scenario in registry operations.

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
