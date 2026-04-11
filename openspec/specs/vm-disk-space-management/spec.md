# Capability: VM Disk Space Management

## Purpose

Ensures VM has sufficient disk space for Docker image operations during deployment.

## Requirements

The VM SHALL have sufficient disk space available before loading Docker images.

The build system SHALL clean up unused Docker images and containers on VM before loading new images.

The build system SHALL verify available disk space before attempting Docker image load.

The build system SHALL fail with clear error message if insufficient disk space remains for image load.

The build system SHALL not trigger rollback when disk space is insufficient (this is a pre-deployment verification failure, not a deployment rollback scenario).

#### Scenario: Sufficient disk space on VM
- **WHEN** VM has at least 500MB of free disk space before image load
- **THEN** Docker image load SHALL succeed
- **THEN** deployment SHALL proceed without disk space errors
- **THEN** no "no space left on device" errors SHALL occur

#### Scenario: Insufficient disk space, cleanup succeeds
- **WHEN** VM has insufficient disk space for image load
- **WHEN** `docker system prune -f` on VM frees sufficient space
- **THEN** Docker image load SHALL succeed after cleanup
- **THEN** deployment SHALL proceed
- **THEN** "no space left on device" error SHALL not occur

#### Scenario: Insufficient disk space, cleanup insufficient
- **WHEN** VM has insufficient disk space for image load
- **WHEN** `docker system prune -f` does not free sufficient space
- **THEN** build script SHALL fail with error message "ERROR: Insufficient disk space on VM. Free up space or increase VM disk size."
- **THEN** script SHALL exit with non-zero code
- **THEN** rollback SHALL NOT be triggered (this is a pre-deployment verification failure)

#### Scenario: Disk space verification before image load
- **WHEN** Building and transferring Docker image to VM
- **THEN** build script SHALL check available disk space with `multipass exec "$VM_NAME" -- df -h /`
- **THEN** build script SHALL require minimum 500MB free space
- **THEN** build script SHALL fail with clear message if space below threshold
