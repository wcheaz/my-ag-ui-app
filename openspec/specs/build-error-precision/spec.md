# Capability: Build Error Precision

## Purpose

Ensures build scripts accurately distinguish between actual build failures and non-critical cleanup failures.

## Requirements

### Requirement: Build scripts accurately distinguish between actual build failures and non-critical cleanup failures

The build system SHALL accurately determine build success or failure based on Docker build and image load operations, not on cleanup operations.

The build script SHALL NOT fail when non-critical cleanup operations fail after successful Docker build and image load.

The build script SHALL fail with non-zero exit code when Docker build operations fail.

The build script SHALL use Docker build exit codes via PIPESTATUS to determine build success.

The build script SHALL NOT attempt to clean up tar files after successful transfer to VM.

#### Scenario: Successful Docker build with cleanup failure
- **WHEN** Docker build completes successfully and image is loaded to VM
- **THEN** build script SHALL exit with code 0
- **THEN** deploy-all.sh SHALL proceed to next step
- **THEN** rollback SHALL NOT be triggered

#### Scenario: Failed Docker build
- **WHEN** Docker build encounters errors and exits with non-zero code
- **THEN** build script SHALL exit with same non-zero code
- **THEN** deploy-all.sh SHALL report "STEP 2 FAILED"
- **THEN** rollback SHALL be triggered

#### Scenario: Image load failure to VM
- **WHEN** Docker image transfer to VM fails or image load fails
- **THEN** build script SHALL exit with non-zero code
- **THEN** deploy-all.sh SHALL report "STEP 2 FAILED"
- **THEN** rollback SHALL be triggered

#### Scenario: Non-critical cleanup failure after successful build
- **WHEN** cleanup operations (tar deletion, container cleanup) fail after successful Docker build
- **THEN** build script SHALL log the failure
- **THEN** build script SHALL continue and exit with code 0
- **THEN** deployment SHALL proceed without rollback
