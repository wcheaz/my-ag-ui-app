# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

## Why

The deployment script fails because Kubernetes YAML files are not being copied to the VM during the deployment process, preventing the application from being deployed to the microk8s cluster. This is a critical bug that blocks the entire deployment workflow.

## What Changes

- Fix the deployment script to properly copy Kubernetes YAML files (secrets.yaml, deployment.yaml, service.yaml, ingress.yaml) from the host to the VM
- Ensure the k8s/ directory is created in the VM before copying files
- Add validation to verify files exist before attempting to apply them with kubectl
- Improve error handling and logging for file transfer operations

## Capabilities

### New Capabilities
- `vm-file-transfer`: Capability for transferring files from host to VM during deployment, including directory creation and file validation

### Modified Capabilities
- None (this is a bug fix, not a requirement change)

## Impact

- **Code**: The deploy.sh script will be modified to include proper file transfer logic
- **Deployment Workflow**: The deployment process will successfully transfer and apply Kubernetes manifests
- **Dependencies**: No new dependencies required - uses existing multipass and kubectl tools
- **Systems**: Affects the microk8s deployment on multipass VMs
- **Breaking Changes**: None - this is a bug fix that restores intended functionality

## Specifications

vm-file-transfer/spec.md
## ADDED Requirements

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



## Design

## Context

The deployment script ([`deploy.sh`](deploy.sh:1)) attempts to apply Kubernetes manifests to a microk8s cluster running inside a multipass VM. However, the script fails because the Kubernetes YAML files (secrets.yaml, deployment.yaml, service.yaml, ingress.yaml) are never transferred from the host system to the VM before the script attempts to apply them.

**Current State:**
- The script runs commands like `multipass exec "$VM_NAME" -- microk8s kubectl apply -f k8s/secrets.yaml` (line 128)
- These commands expect the files to exist at `/home/ubuntu/k8s/` inside the VM
- No file transfer logic exists in the script
- The k8s/ directory does not exist in the VM
- Result: "error: the path 'k8s/secrets.yaml' does not exist"

**Constraints:**
- Must use existing tools: multipass and kubectl
- Must not introduce new dependencies
- Must maintain backward compatibility with existing deployment workflow
- Must provide clear error messages and logging

**Stakeholders:**
- Developers who need to deploy the application to microk8s
- Operations team managing the deployment process

## Goals / Non-Goals

**Goals:**
- Transfer Kubernetes YAML files from host k8s/ directory to VM's /home/ubuntu/k8s/ directory
- Create the k8s/ directory in the VM before file transfer
- Validate that all required files exist in the VM before attempting to apply manifests
- Improve error handling and logging for file transfer operations
- Ensure the deployment process succeeds end-to-end

**Non-Goals:**
- Modifying the Kubernetes manifest files themselves
- Changing the VM configuration or microk8s setup
- Implementing a new deployment mechanism
- Adding file synchronization or monitoring capabilities

## Decisions

### 1. Use multipass transfer command for file copying

**Decision:** Use `multipass transfer` command to copy files from host to VM.

**Rationale:**
- multipass provides a built-in file transfer mechanism designed for this use case
- No need for additional tools or dependencies
- Simple and reliable for transferring individual files or directories
- Well-documented and supported

**Alternatives Considered:**
- **multipass exec with cat/tee**: More complex, error-prone for multiple files
- **SCP/SSH**: Requires SSH setup, adds complexity
- **Shared directory**: Requires VM reconfiguration, not always available

### 2. Create directory in VM before file transfer

**Decision:** Explicitly create the k8s/ directory in the VM before transferring files.

**Rationale:**
- Ensures the target directory exists before file transfer
- Prevents ambiguous error messages if directory doesn't exist
- Makes the deployment process more robust and predictable
- Allows for proper error handling if directory creation fails

**Alternatives Considered:**
- **Let multipass create it implicitly**: Less control over error handling
- **Transfer entire directory**: May transfer unwanted files

### 3. Validate files after transfer

**Decision:** Verify each required file exists in the VM after transfer before attempting to apply manifests.

**Rationale:**
- Catches transfer failures early
- Provides clear error messages about which files are missing
- Prevents cascading failures when kubectl can't find files
- Improves debugging and troubleshooting

**Alternatives Considered:**
- **Skip validation**: Would lead to confusing kubectl errors
- **Validate before transfer**: Doesn't catch transfer failures

### 4. Fail fast on file transfer errors

**Decision:** Exit immediately with a clear error message if file transfer or validation fails.

**Rationale:**
- Prevents wasting time on partial deployments
- Makes failures immediately obvious
- Provides actionable error messages
- Maintains script reliability

**Alternatives Considered:**
- **Continue with warnings**: Could lead to partial/broken deployments
- **Retry automatically**: Adds complexity, may mask underlying issues

### 5. Preserve existing logging structure

**Decision:** Use the existing [`log()`](deploy.sh:13) function for all new logging statements.

**Rationale:**
- Maintains consistency with existing code
- Ensures all messages are written to both stdout and log file
- Preserves timestamp formatting
- No need to modify existing logging infrastructure

**Alternatives Considered:**
- **Create new logging functions**: Unnecessary complexity
- **Use echo directly**: Would lose log file output

## Risks / Trade-offs

### Risk 1: File transfer may fail silently
**Risk:** `multipass transfer` may not properly report all failure modes.

**Mitigation:** Validate file existence after transfer using `multipass exec` with `test -f` command. Log detailed error messages including the transfer command and exit code.

### Risk 2: VM may not be running or accessible
**Risk:** The VM may not be in a state where file transfer is possible.

**Mitigation:** The existing script already checks VM status. Add explicit check before file transfer. Provide clear error message if VM is not accessible.

### Risk 3: Large files may cause timeout
**Risk:** If YAML files become very large, transfer may timeout.

**Mitigation:** Current files are small (<10KB). Monitor file sizes. Consider adding timeout configuration if files grow significantly in the future.

### Risk 4: Concurrent deployments may conflict
**Risk:** Multiple deployment runs may interfere with each other's file transfers.

**Mitigation:** Document that deployments should be run sequentially. Consider adding a lock mechanism if concurrent deployments become a requirement.

### Trade-off: Additional deployment time
**Trade-off:** File transfer adds time to the deployment process.

**Justification:** The transfer time is negligible for small YAML files (<1 second). The benefit of a working deployment far outweighs this minimal overhead.

### Trade-off: Increased script complexity
**Trade-off:** Adding file transfer logic increases script complexity.

**Justification:** The complexity is necessary for the script to function correctly. The logic is straightforward and well-contained, making it maintainable.

## Migration Plan

### Deployment Steps

1. **Add file transfer section** before Kubernetes manifest application (after line 125)
   - Create k8s/ directory in VM
   - Transfer secrets.yaml, deployment.yaml, service.yaml, ingress.yaml
   - Validate all files exist in VM

2. **Update error handling** to include file transfer errors
   - Add new error codes for file transfer failures
   - Provide specific recovery suggestions for each error type

3. **Test deployment** with the updated script
   - Verify files are transferred correctly
   - Verify deployment succeeds end-to-end
   - Verify error messages are clear and actionable

### Rollback Strategy

If issues arise after deployment:

1. **Revert to previous version** of deploy.sh from version control
2. **Clean up VM** by removing transferred files if necessary
3. **Document the issue** and investigate root cause

The rollback is straightforward because:
- No changes are made to the VM configuration
- No changes are made to Kubernetes manifests
- Only the deployment script is modified
- The previous script version is preserved in version control

## Open Questions

None identified at this time. The design is straightforward and addresses a clear bug with a well-defined solution.

## Current Task Context

## Current Task
- 1.1 Add VM directory creation logic to deploy.sh after line 125 (after VM_NAME validation)
