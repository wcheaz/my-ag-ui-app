# Proposal: Fix Docker Push to Microk8s Registry

## Why

The deployment script successfully builds the Docker image on the host system and verifies the microk8s registry is running in the VM. However, when attempting to push the image to the registry, it fails with "connection refused" because the host's Docker daemon tries to connect to `localhost:32000` (host's localhost) instead of the VM's `localhost:32000` where the registry actually runs. This prevents successful Kubernetes deployment.

## What Changes

- **Execute Docker push from within VM**: Modify the image push command to execute via `multipass exec` so it runs inside the VM where `localhost:32000` resolves to the microk8s registry
- **Tag image for registry within VM**: Update image tagging to execute inside the VM so the tagged image is available to the VM's Docker daemon
- **Keep Docker build on host**: Maintain existing Docker build workflow on the host system (no changes needed)
- **Minimal deployment script changes**: Only modify the image tag and push operations in [`deploy.sh`](deploy.sh)

## Capabilities

### New Capabilities
- `vm-registry-push`: Capability for pushing Docker images to microk8s registry from within the VM. This covers tagging images and pushing to the local registry where it's accessible.

### Modified Capabilities
- `docker-image-build-load`: Update requirements to execute image tag and push operations within the VM instead of on the host system. The Docker build remains on host, but tag and push move to VM context.

## Impact

- **Affected Code**: [`deploy.sh`](deploy.sh) - modify only the image tag and push sections to execute via `multipass exec`
- **Affected Configuration**: No configuration changes needed - [`k8s/deployment.yaml`](k8s/deployment.yaml) already references correct image location
- **Dependencies**: Requires Docker to be installed and running within the multipass VM (already present)
- **Systems**: 
  - Host system: Docker build continues to execute here
  - Multipass VM: Image tag and push operations execute here
  - Microk8s cluster: Local registry at localhost:32000 receives images pushed from within VM
- **Deployment Flow**: Minimal change - only tag and push operations move to VM, build remains on host
