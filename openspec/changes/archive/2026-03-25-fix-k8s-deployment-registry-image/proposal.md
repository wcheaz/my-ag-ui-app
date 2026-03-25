## Why

The Kubernetes deployment is failing with `ImagePullBackOff` errors because the deployment manifest references `my-ag-ui-app:latest` (which attempts to pull from Docker Hub) instead of `localhost:32000/my-ag-ui-app:latest` (the local microk8s registry). Despite the successful implementation of image pushing to the local registry in the `fix-docker-push-to-vm-registry` change, the deployment configuration was not updated to use the local registry image reference, causing pods to fail during image pull.

## What Changes

- Update `k8s/deployment.yaml` to reference `localhost:32000/my-ag-ui-app:latest` instead of `my-ag-ui-app:latest`
- Verify that the deployment correctly pulls images from the local microk8s registry
- Update any documentation that references the deployment image configuration
- Ensure the deployment script properly handles the updated image reference

## Capabilities

### New Capabilities
- `k8s-registry-image-reference`: Configures Kubernetes deployment to use local microk8s registry image references for reliable local deployments

### Modified Capabilities
- `docker-image-build-load`: The deployment phase now requires the image to be tagged and pushed to the local registry before deployment

## Impact

- **Affected Files**: `k8s/deployment.yaml`, deployment documentation
- **Kubernetes Deployment**: Pods will now pull images from `localhost:32000/my-ag-ui-app:latest` instead of Docker Hub
- **Deployment Flow**: The deployment script will continue to build, tag, and push images to the local registry, and the Kubernetes deployment will successfully pull from that registry
- **No Breaking Changes**: This is a configuration fix that aligns the deployment with the existing registry push workflow
