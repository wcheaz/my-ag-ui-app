# Containerd Image Import

## Purpose

Capability for importing Docker images into containerd's namespace to enable microk8s to use locally built images. This bridges the gap between Docker (used for building images) and containerd (used by microk8s as container runtime), ensuring images are available to Kubernetes without requiring an external registry.

## ADDED Requirements

### Requirement: System must import Docker images into containerd namespace
The deployment process SHALL convert Docker images to containerd format and import them into the microk8s container runtime using ctr or crictl tools.

#### Scenario: Successful image import with ctr
- **WHEN** deployment script executes ctr image import command
- **AND** Docker image file exists on host system
- **THEN** script SHALL import image into containerd's namespace
- **AND** script SHALL verify image is available in containerd
- **AND** script SHALL log successful import with image ID

#### Scenario: Successful image import with crictl
- **WHEN** ctr tool is not available
- **AND** crictl tool is available in VM
- **THEN** script SHALL use crictl to import image
- **AND** script SHALL verify image is available in containerd
- **AND** script SHALL log successful import with image ID

#### Scenario: Image import failure due to missing tools
- **WHEN** deployment script attempts to import image
- **AND** neither ctr nor crictl is available in VM
- **THEN** script SHALL log clear error that containerd tools are not available
- **AND** script SHALL provide instructions to install required tools
- **AND** script SHALL exit with non-zero status code
- **AND** script SHALL NOT proceed with deployment

#### Scenario: Image import failure due to invalid image file
- **WHEN** deployment script attempts to import image
- **AND** image file is corrupted or invalid
- **THEN** script SHALL log import error with context
- **AND** script SHALL verify image file integrity before import
- **AND** script SHALL exit with non-zero status code
- **AND** script SHALL NOT proceed with deployment

### Requirement: System must verify image availability in containerd
The deployment process SHALL verify that imported images are accessible to containerd before attempting Kubernetes deployment.

#### Scenario: Image is available in containerd
- **WHEN** deployment script checks for image in containerd
- **AND** image was successfully imported
- **THEN** script SHALL confirm image exists in containerd's namespace
- **AND** script SHALL display image details (ID, size, tags)
- **AND** script SHALL proceed with Kubernetes deployment

#### Scenario: Image is not available in containerd
- **WHEN** deployment script checks for image in containerd
- **AND** image was not successfully imported
- **THEN** script SHALL log error that image is not available
- **AND** script SHALL provide troubleshooting steps
- **AND** script SHALL exit with non-zero status code
- **AND** script SHALL NOT attempt Kubernetes deployment

### Requirement: System must handle image naming for containerd
The deployment process SHALL ensure imported images use correct naming conventions that match Kubernetes deployment specifications.

#### Scenario: Image is imported with correct tag
- **WHEN** deployment script imports Docker image
- **AND** image is tagged as my-ag-ui-app:latest
- **THEN** script SHALL import with tag preserved
- **AND** script SHALL verify tag is accessible in containerd
- **AND** script SHALL confirm tag matches deployment manifest

#### Scenario: Image requires retagging for containerd
- **WHEN** deployment script imports Docker image
- **AND** image tag needs adjustment for containerd
- **THEN** script SHALL retag image after import
- **AND** script SHALL verify new tag is accessible
- **AND** script SHALL log tag change for reference

### Requirement: System must clean up temporary image files
The deployment process SHALL remove temporary Docker image files after successful import into containerd to conserve disk space.

#### Scenario: Temporary file cleanup after successful import
- **WHEN** deployment script successfully imports image into containerd
- **AND** temporary image file exists on host
- **THEN** script SHALL remove temporary image file
- **AND** script SHALL log cleanup action
- **AND** script SHALL verify disk space freed

#### Scenario: Temporary file retention after failed import
- **WHEN** deployment script fails to import image
- **AND** temporary image file exists on host
- **THEN** script SHALL retain temporary file for debugging
- **AND** script SHALL log file retention with path
- **AND** script SHALL provide manual cleanup instructions

### Requirement: System must support both Docker save and direct import methods
The deployment process SHALL support importing images either from Docker save output or directly from Docker daemon using containerd-compatible tools.

#### Scenario: Import from Docker save file
- **WHEN** deployment script uses docker save to export image
- **AND** image file is created on host system
- **THEN** script SHALL transfer image file to VM
- **THEN** script SHALL import file into containerd
- **AND** script SHALL verify import success
- **AND** script SHALL remove temporary file

#### Scenario: Direct import from Docker daemon
- **WHEN** deployment script uses containerd tools to pull directly
- **AND** Docker daemon is accessible in VM
- **THEN** script SHALL pull image directly into containerd
- **AND** script SHALL verify image is available
- **AND** script SHALL skip file transfer step
- **AND** script SHALL log direct import method used
