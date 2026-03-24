# Current Deployment State and Error Patterns

## Deployment State Analysis (March 24, 2026)

### Successful Components
1. **Docker Image Build**: ✅ Successfully built `my-ag-ui-app:latest` image (546MB)
2. **Image Tagging**: ✅ Successfully tagged as `localhost:32000/my-ag-ui-app:latest` for local registry
3. **Microk8s Registry**: ✅ Registry enabled, running, and accessible at `localhost:32000`
4. **Image Push**: ✅ Image successfully pushed to local microk8s registry
5. **Registry Verification**: ✅ Registry contains `my-ag-ui-app` repository

### Critical Failure Point
**Kubernetes Deployment**: ❌ Pods failing with `ImagePullBackOff` errors

### Error Patterns Identified

#### 1. Image Reference Mismatch
- **Current Manifest**: References `my-ag-ui-app:latest`
- **Expected Reference**: Should reference `localhost:32000/my-ag-ui-app:latest`
- **Result**: Kubernetes attempts to pull from Docker Hub instead of local registry

#### 2. Pod Status Timeline
```
Initial State: ContainerCreating (1s)
→ ErrImagePull (5s)
→ ImagePullBackOff (15s)
→ Persistent ImagePullBackOff (89s+)
```

#### 3. Detailed Error Analysis
From pod events (lines 1838-1842):
```
Normal   Pulling    48s (x3 over 87s)  kubelet  Pulling image "my-ag-ui-app:latest"
Warning  Failed     47s (x3 over 87s)  kubelet  Failed to pull image "my-ag-ui-app:latest": 
  rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/my-ag-ui-app:latest": 
  failed to unpack image on snapshotter overlayfs: unexpected media type text/html for sha256:...: not found
Warning  Failed     47s (x3 over 87s)  kubelet  Error: ErrImagePull
Normal   BackOff    8s (x5 over 86s)   kubelet  Back-off pulling image "my-ag-ui-app:latest"
Warning  Failed     8s (x5 over 86s)   kubelet  Error: ImagePullBackOff
```

#### 4. Root Cause Confirmation
Pod container details (line 1790):
```yaml
Image: my-ag-ui-app:latest  # ← Should be: localhost:32000/my-ag-ui-app:latest
```

### Environment Context
- **VM**: my-ag-ui-app-k8s (multipass)
- **Registry**: microk8s built-in registry at `localhost:32000`
- **Registry Status**: Running (registry-6cf7b9fcc-4kfg7 pod, 1/1 ready)
- **Available Images**: 
  - `my-ag-ui-app:latest` (local Docker)
  - `localhost:32000/my-ag-ui-app:latest` (in microk8s registry)

### Impact Assessment
- **Deployment Flow**: Build → Tag → Push ✅ WORKING
- **Kubernetes Deployment**: ❌ FAILING at pod creation
- **Pod Status**: 1 old pod Running (nginx:latest), 1 new pod stuck in ImagePullBackOff
- **Application Availability**: Partially available (old version running)

### Required Fix
Update `k8s/deployment.yaml` to change:
```yaml
image: my-ag-ui-app:latest
```
to:
```yaml
image: localhost:32000/my-ag-ui-app:latest
```

This will ensure Kubernetes pulls from the local microk8s registry instead of attempting to pull from Docker Hub.

### Next Steps
1. Update deployment manifest image reference
2. Reapply deployment configuration
3. Verify pods successfully pull from local registry
4. Confirm application reaches Running state