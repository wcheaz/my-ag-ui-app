# Proposal: Fix Kubernetes Deployment Issues

## Why

The deployment script fails to successfully deploy the application to the Kubernetes cluster running in the multipass VM (my-ag-ui-app-k8s) using microk8s. The root cause is that while Docker images are successfully loaded into the VM's Docker daemon, Kubernetes attempts to pull images from external registries (docker.io) instead of using the locally available images. This causes pods to remain in `ImagePullBackOff` state, preventing the application from running. This fix is needed to complete the deployment automation and enable reliable, repeatable deployments to the Kubernetes cluster using microk8s's built-in local registry.

## What Changes

- **Enable microk8s local registry**: Configure microk8s registry add-on to provide a local, trusted registry for image distribution
- **Tag images for local registry**: Modify deployment script to tag Docker images with the local registry endpoint (localhost:32000)
- **Push images to local registry**: Add functionality to push tagged images to the microk8s registry
- **Update deployment manifest**: Configure the deployment to reference images from the local registry (localhost:32000/my-ag-ui-app:latest)
- **Improve error handling**: Add validation to ensure registry is enabled and images are successfully pushed before attempting deployment
- **Streamline deployment**: Remove unnecessary retry logic and improve the deployment flow based on successful registry operations

## Capabilities

### New Capabilities
- `microk8s-registry-integration`: Capability for using microk8s's built-in local registry to distribute Docker images. This covers enabling the registry, tagging images for local registry, pushing images, and referencing them in Kubernetes deployments.

### Modified Capabilities
- `docker-image-build-load`: Update the image loading requirements to support pushing images to microk8s local registry instead of loading into Docker daemon. The current spec only covers loading into Docker daemon; this change adds registry push as the primary method for microk8s deployments.

- `kubernetes-deployment`: Update the deployment requirements to include local registry image references and registry availability verification. The current spec assumes images are pulled from external registries; this change adds support for microk8s local registry images.

## Impact

- **Affected Code**: [`deploy.sh`](deploy.sh) - main deployment script requiring modifications to enable registry, tag/push images, and verify registry operations
- **Affected Configuration**: [`k8s/deployment.yaml`](k8s/deployment.yaml) - needs image reference updated to `localhost:32000/my-ag-ui-app:latest`
- **Dependencies**: Requires microk8s registry add-on (standard with microk8s installation)
- **Systems**: 
  - Host system: Docker build and image tagging operations
  - Multipass VM: Registry enablement and image push operations
  - Microk8s cluster: Local registry at localhost:32000, pod deployment using registry images
- **Deployment Flow**: Changes the image distribution to use microk8s local registry (push) instead of direct daemon loading
