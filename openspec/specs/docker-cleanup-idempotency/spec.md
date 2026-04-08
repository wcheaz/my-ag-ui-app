# Docker Cleanup Idempotency

## Purpose
Ensure Docker cleanup operations are idempotent and handle failures gracefully by stopping containers before image deletion and providing appropriate error handling. (TBD: expand with more context)

## Requirements

### Requirement: Docker cleanup removes containers before images
The cleanup script MUST stop all containers with label `app=my-ag-ui-app` before attempting to delete Docker images. The script MUST remove stopped containers before deleting images to prevent conflict errors.

#### Scenario: Cleanup with stopped containers referencing images
- **GIVEN** Docker has stopped containers with label `app=my-ag-ui-app` referencing the image to be deleted
- **WHEN** the cleanup script runs
- **THEN** all stopped containers with that label are removed
- **AND** no conflict errors occur during image deletion
- **AND** the cleanup script exits with code 0

#### Scenario: Cleanup with no containers
- **GIVEN** no containers exist with label `app=my-ag-ui-app`
- **WHEN** the cleanup script runs
- **THEN** the cleanup script exits with code 0
- **AND** no error messages are logged
- **AND** the script continues to image deletion phase

#### Scenario: Cleanup with running containers
- **GIVEN** Docker has running containers with label `app=my-ag-ui-app`
- **WHEN** the cleanup script runs
- **THEN** running containers are stopped
- **AND** stopped containers are removed
- **AND** images can be deleted without conflict errors
- **AND** the cleanup script exits with code 0

### Requirement: Cleanup handles non-critical failures gracefully
The cleanup script MUST log warnings for non-critical failures but MUST NOT fail the deployment pipeline. The script MUST continue execution after logging warnings for cleanup failures.

#### Scenario: Cleanup encounters non-critical error
- **GIVEN** a non-critical cleanup operation fails (e.g., unused images cannot be removed)
- **WHEN** the error occurs
- **THEN** the script logs a warning message
- **AND** the script continues with next cleanup phase
- **AND** the deployment pipeline is not blocked

#### Scenario: Cleanup encounters critical error
- **GIVEN** Docker daemon is not accessible
- **WHEN** the cleanup script attempts cleanup
- **THEN** the script logs an error message
- **AND** the script exits with non-zero code
- **AND** the deployment pipeline is halted
