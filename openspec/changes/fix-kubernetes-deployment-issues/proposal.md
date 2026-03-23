# Proposal: Fix Kubernetes Deployment Issues

## Why

The deployment script fails to successfully deploy the application to the Kubernetes cluster running in the multipass VM (my-ag-ui-app-k8s) using microk8s. The root cause is that while Docker images are successfully loaded into the VM's Docker daemon, microk8s uses containerd as its container runtime and cannot access images stored only in Docker. This causes pods to remain in `ImagePullBackOff` state, preventing the application from running. This fix is needed to complete the deployment automation and enable reliable, repeatable deployments to the Kubernetes cluster.

## What Changes

- **Fix container runtime compatibility**: Modify the image loading process to import Docker images into containerd's namespace so microk8s can access them
- **Update deployment manifest**: Configure the deployment to use `imagePullPolicy: Never` to prevent Kubernetes from attempting to pull from external registries
- **Improve error handling**: Add validation to ensure images are properly available in containerd before attempting deployment
- **Enhance verification**: Add checks to verify image availability in both Docker and containerd runtimes
- **Streamline deployment**: Remove unnecessary retry logic and improve the deployment flow based on successful image loading patterns

## Capabilities

### New Capabilities
- `containerd-image-import`: Capability for importing Docker images into containerd's namespace for microk8s compatibility. This covers the process of converting Docker images to containerd format and importing them into the microk8s container runtime.

### Modified Capabilities
- `docker-image-build-load`: Update the image loading requirements to support both Docker and containerd runtimes. The current spec only covers loading into Docker daemon; this change adds containerd import as the primary method for microk8s deployments.

- `kubernetes-deployment`: Update the deployment requirements to include image pull policy configuration and containerd-specific image availability verification. The current spec assumes images are pulled from registries; this change adds support for locally imported images.

## Impact

- **Affected Code**: [`deploy.sh`](deploy.sh) - main deployment script requiring modifications to image loading and Kubernetes deployment phases
- **Affected Configuration**: [`k8s/deployment.yaml`](k8s/deployment.yaml) - may need `imagePullPolicy: Never` added
- **Dependencies**: Requires `ctr` or `crictl` tools in the VM for containerd image management (typically available with microk8s)
- **Systems**: 
  - Host system: Docker build and image save operations
  - Multipass VM: Image transfer and containerd import operations
  - Microk8s cluster: Pod deployment using locally imported images
- **Deployment Flow**: Changes the image availability verification to check containerd instead of Docker for microk8s deployments
