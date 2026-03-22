## Why

The deployment script fails because Kubernetes YAML files are not being copied to the VM during the deployment process, preventing the application from being deployed to the microk8s cluster. Additionally, even after fixing the file transfer issue, the deployment fails with ImagePullBackOff because the Docker image is not built or loaded into the VM. These are critical bugs that block the entire deployment workflow.

## What Changes

- Fix the deployment script to properly copy Kubernetes YAML files (secrets.yaml, deployment.yaml, service.yaml, ingress.yaml) from the host to the VM
- Ensure the k8s/ directory is created in the VM before copying files
- Add validation to verify files exist before attempting to apply them with kubectl
- Improve error handling and logging for file transfer operations
- Build the Docker image from the project's Dockerfile
- Load the Docker image into the multipass VM's Docker daemon
- Verify the pod can successfully start with the loaded image

## Capabilities

### New Capabilities
- `vm-file-transfer`: Capability for transferring files from host to VM during deployment, including directory creation and file validation
- `docker-image-build-load`: Capability for building Docker images and loading them into the multipass VM's Docker daemon

### Modified Capabilities
- None (this is a bug fix, not a requirement change)

## Impact

- **Code**: The deploy.sh script will be modified to include proper file transfer logic
- **Deployment Workflow**: The deployment process will successfully transfer and apply Kubernetes manifests
- **Dependencies**: No new dependencies required - uses existing multipass and kubectl tools
- **Systems**: Affects the microk8s deployment on multipass VMs
- **Breaking Changes**: None - this is a bug fix that restores intended functionality
