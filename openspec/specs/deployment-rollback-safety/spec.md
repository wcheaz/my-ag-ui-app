# Deployment Rollback Safety

## Purpose
Ensure safe rollback capabilities for Kubernetes deployments by creating backups before applying changes and providing reliable rollback functionality. (TBD: expand with more context)

## Requirements

### Requirement: Backup file created before deployment changes
The deployment pipeline MUST create a backup of `k8s/deployment.yaml` at `k8s/deployment.yaml.backup` before applying any Kubernetes changes. The backup MUST be created after the Docker build succeeds but before registry setup.

#### Scenario: Successful backup creation
- **GIVEN** `k8s/deployment.yaml` exists and Docker build succeeded
- **WHEN** the deployment pipeline reaches backup creation step
- **THEN** `k8s/deployment.yaml` is copied to `k8s/deployment.yaml.backup`
- **AND** the backup file exists
- **AND** the backup file content matches the original
- **AND** the deployment pipeline continues to next step

#### Scenario: Backup file already exists
- **GIVEN** `k8s/deployment.yaml.backup` already exists from previous deployment
- **WHEN** the deployment pipeline reaches backup creation step
- **THEN** the existing backup file is overwritten
- **AND** the backup file contains the current `k8s/deployment.yaml` content
- **AND** the deployment pipeline continues to next step
- **AND** no error is logged

#### Scenario: Deployment manifest missing
- **GIVEN** `k8s/deployment.yaml` does not exist
- **WHEN** the deployment pipeline reaches backup creation step
- **THEN** an error is logged
- **AND** the deployment pipeline halts
- **AND** no backup is created

### Requirement: Rollback can restore from backup
The rollback function MUST restore the deployment state from `k8s/deployment.yaml.backup`. The rollback MUST handle resource version conflicts and use appropriate strategies to apply the backup.

#### Scenario: Successful rollback with backup present
- **GIVEN** `k8s/deployment.yaml.backup` exists
- **WHEN** a deployment failure triggers rollback
- **THEN** the backup file is transferred to the VM
- **AND** Kubernetes applies the backup deployment manifest
- **AND** the deployment returns to previous state
- **AND** rollback logs success message

#### Scenario: Rollback encounters resource version conflict
- **GIVEN** backup file exists and Kubernetes reports resource version conflict
- **WHEN** rollback applies the backup
- **THEN** rollback attempts to apply with `--force` flag
- **OR** rollback deletes and recreates the deployment
- **AND** deployment is restored to previous state
- **AND** rollback logs success message with conflict resolution strategy used

#### Scenario: Rollback with missing backup file
- **GIVEN** `k8s/deployment.yaml.backup` does not exist
- **WHEN** a deployment failure triggers rollback
- **THEN** rollback logs error message "No backup deployment manifest found"
- **AND** rollback exits with non-zero code
- **AND** manual intervention is required
