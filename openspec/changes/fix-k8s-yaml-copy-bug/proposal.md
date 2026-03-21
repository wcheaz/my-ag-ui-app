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
