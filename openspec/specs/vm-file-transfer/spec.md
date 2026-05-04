# VM File Transfer

## Purpose

Capability for transferring files from host to VM during deployment, including directory creation and file validation. This enables the deployment script to copy Kubernetes YAML files to the multipass VM before applying them with kubectl.

## Requirements

### Requirement: VM directory creation
The deployment script SHALL create the target directory in the VM before attempting to copy files.

#### Scenario: Directory creation success
- **WHEN** the deployment script starts the file transfer process
- **THEN** the script SHALL create the k8s/ directory in the VM at /home/ubuntu/k8s/
- **AND** the script SHALL verify the directory exists before proceeding

#### Scenario: Directory already exists
- **WHEN** the deployment script attempts to create a directory that already exists
- **THEN** the script SHALL continue without error
- **AND** the script SHALL log that the directory already exists

### Requirement: File transfer from host to VM
The deployment script SHALL copy Kubernetes YAML files from the host system to the VM.

#### Scenario: Successful file transfer
- **WHEN** the deployment script executes the file transfer command
- **THEN** the script SHALL copy all required files (secrets.yaml, deployment.yaml, service.yaml, ingress.yaml) from the host k8s/ directory to the VM
- **AND** the script SHALL verify each file was successfully transferred

#### Scenario: File transfer failure
- **WHEN** the file transfer command fails for any reason
- **THEN** the script SHALL log a detailed error message
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT attempt to apply Kubernetes manifests

### Requirement: File validation
The deployment script SHALL validate that all required files exist in the VM before attempting to apply Kubernetes manifests.

#### Scenario: All files present
- **WHEN** the deployment script validates files after transfer
- **THEN** the script SHALL verify that secrets.yaml, deployment.yaml, service.yaml, and ingress.yaml all exist in /home/ubuntu/k8s/
- **AND** the script SHALL proceed to apply the manifests

#### Scenario: Missing file detected
- **WHEN** the deployment script detects a missing required file
- **THEN** the script SHALL log which file is missing
- **AND** the script SHALL exit with a non-zero status code
- **AND** the script SHALL NOT attempt to apply any Kubernetes manifests

### Requirement: Error handling and logging
The deployment script SHALL provide clear error messages and logging throughout the file transfer process.

#### Scenario: Successful transfer logging
- **WHEN** files are successfully transferred to the VM
- **THEN** the script SHALL log a success message with the number of files transferred
- **AND** the script SHALL log the destination path

#### Scenario: Error logging
- **WHEN** an error occurs during file transfer or validation
- **THEN** the script SHALL log the specific error with context (command, exit code, timestamp)
- **AND** the script SHALL provide actionable error messages to help diagnose the issue
