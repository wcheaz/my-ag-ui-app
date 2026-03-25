# Microk8s Registry Troubleshooting Guide

This guide provides comprehensive troubleshooting steps for common issues encountered with the microk8s registry approach in Kubernetes deployments.

## Table of Contents

1. [Quick Diagnosis](#quick-diagnosis)
2. [Common Registry Issues](#common-registry-issues)
3. [Step-by-Step Troubleshooting](#step-by-step-troubleshooting)
4. [Diagnostic Commands](#diagnostic-commands)
5. [Frequently Asked Questions](#frequently-asked-questions)
6. [Advanced Troubleshooting](#advanced-troubleshooting)

---

## Quick Diagnosis

Use this quick checklist to identify the most common registry issues:

```bash
# 1. Check if VM is running
multipass list

# 2. Check if microk8s is running
multipass exec my-ag-ui-app-k8s -- microk8s status

# 3. Check if registry is accessible
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/_catalog

# 4. Check if image exists in registry
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list
```

If any of these commands fail, refer to the corresponding sections below.

---

## Common Registry Issues

### 1. Registry Not Accessible

**Symptoms:**
- `curl: (7) Failed to connect to localhost port 32000: Connection refused`
- Deployment pods stuck in `ImagePullBackOff` state
- Timeout errors when accessing registry

**Causes:**
- microk8s is not running
- Registry addon is not enabled
- Network connectivity issues
- Port conflicts (rare with microk8s NodePort architecture)

**Solutions:**
```bash
# Check microk8s status
multipass exec my-ag-ui-app-k8s -- microk8s status

# If microk8s is not running, start it
multipass exec my-ag-ui-app-k8s -- microk8s start

# Enable registry if not enabled
multipass exec my-ag-ui-app-k8s -- microk8s enable registry

# Wait for registry to start (about 30 seconds)
multipass exec my-ag-ui-app-k8s -- sleep 30

# Test registry accessibility
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/_catalog
```

### 2. Image Not Found in Registry

**Symptoms:**
- `manifest unknown` or `not found` errors
- Pods fail to start with image pull errors
- Empty repository list when querying registry

**Causes:**
- Image was not pushed to registry
- Image was pushed with wrong tag
- Registry was reset or cleared
- Image name doesn't match deployment specification

**Solutions:**
```bash
# Check what images exist in registry
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/_catalog

# Check specific image tags
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list

# If image doesn't exist, rebuild and push it:
# On your local machine:
docker build -t my-ag-ui-app:latest .
docker tag my-ag-ui-app:latest localhost:32000/my-ag-ui-app:latest
docker push localhost:32000/my-ag-ui-app:latest

# Verify image is now in registry
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list
```

### 3. Deployment Using Wrong Image Reference

**Symptoms:**
- Pods pull from wrong registry (e.g., Docker Hub instead of local registry)
- Image pull errors for external registories
- Unexpected application versions running
- Persistent ImagePullBackOff errors despite images being in local registry

**Causes:**
- Deployment manifest not updated to use local registry
- Image reference still points to old registry (e.g., `my-ag-ui-app:latest` instead of `localhost:32000/my-ag-ui-app:latest`)
- Incorrect image tag format
- Manual deployment without proper image reference updates

**Solutions:**
```bash
# Check current deployment image
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.spec.template.spec.containers[0].image}'

# Expected output: localhost:32000/my-ag-ui-app:latest
# If output shows: my-ag-ui-app:latest (without localhost:32000/), this is the issue

# Update deployment to use local registry image
multipass exec my-ag-ui-app-k8s -- microk8s kubectl set image deployment/my-ag-ui-app my-ag-ui-app=localhost:32000/my-ag-ui-app:latest

# Verify the update
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Manual Deployment Manifest Fix:**
If you're deploying from YAML files, ensure your deployment.yaml contains:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-ag-ui-app
spec:
  template:
    spec:
      containers:
      - name: my-ag-ui-app
        image: localhost:32000/my-ag-ui-app:latest  # CRITICAL: Must include localhost:32000/
        # ... other container configuration
```

**Common Pitfalls:**
- Forgetting to include `localhost:32000/` prefix in image reference
- Using external registry references when local registry is intended
- Mixed image references in multi-container deployments
- Not updating all relevant deployment environments (dev, staging, prod)

### 4. Pod Stuck in ImagePullBackOff

**Symptoms:**
- Pod status shows `ImagePullBackOff`
- Pod events indicate image pull failures
- Pod never reaches `Running` state

**Causes:**
- Image not accessible in registry
- Network connectivity issues
- Registry service not running
- Incorrect image reference

**Solutions:**
```bash
# Check pod status and events
multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe pod <pod-name>

# Check if registry is accessible
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/_catalog

# Check if image exists in registry
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list

# If image doesn't exist, follow steps in "Image Not Found in Registry" section

# If all else fails, delete and recreate the pod
multipass exec my-ag-ui-app-k8s -- microk8s kubectl delete pod <pod-name>
```

### 5. Registry Storage Issues

**Symptoms:**
- Registry becomes unresponsive after storing large images
- Image push operations fail with space errors
- Registry pod shows OOM (Out of Memory) errors

**Causes:**
- Insufficient disk space in VM
- Registry storage quota exceeded
- Memory pressure on registry pod

**Solutions:**
```bash
# Check VM disk space
multipass exec my-ag-ui-app-k8s -- df -h

# Check registry pod status
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -n container-registry

# Check registry pod logs
multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs -n container-registry -l app=registry

# Clean up unused images (if needed)
multipass exec my-ag-ui-app-k8s -- docker system prune -f

# If disk space is critically low, consider increasing VM size
multipass stop my-ag-ui-app-k8s
multipass delete my-ag-ui-app-k8s
multipass launch --name my-ag-ui-app-k8s --cpus 4 --memory 7.7G --disk 30G  # Increased disk
```

### 6. Local Registry Deployment Integration Issues

**Symptoms:**
- Deployment successfully builds and pushes images, but pods still fail with ImagePullBackOff
- Registry contains correct images, but deployment references wrong registry
- Inconsistent deployment behavior between manual and automated deployments
- Deployment script succeeds but application pods don't start

**Causes:**
- Deployment manifest not updated to use local registry image reference
- Mismatch between image push location and deployment pull location
- Deployment automation not using updated image references
- Manual deployment using outdated YAML files

**Solutions:**
```bash
# Verify image exists in local registry
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list

# Check deployment image reference
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.spec.template.spec.containers[0].image}'

# Compare with registry content - they must match!
# If deployment shows: my-ag-ui-app:latest
# But registry contains: localhost:32000/my-ag-ui-app:latest
# This is the mismatch causing ImagePullBackOff

# Fix deployment manifest to match registry
# Method 1: Using kubectl set image
multipass exec my-ag-ui-app-k8s -- microk8s kubectl set image deployment/my-ag-ui-app my-ag-ui-app=localhost:32000/my-ag-ui-app:latest

# Method 2: Edit deployment directly
multipass exec my-ag-ui-app-k8s -- microk8s kubectl edit deployment my-ag-ui-app
# Change image: my-ag-ui-app:latest to image: localhost:32000/my-ag-ui-app:latest

# Method 3: Apply updated YAML file
multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f k8s/deployment.yaml

# Verify the fix
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Deployment Automation Integration:**
If you're using a deployment script, ensure it:
1. Builds the image: `docker build -t my-ag-ui-app:latest .`
2. Tags for local registry: `docker tag my-ag-ui-app:latest localhost:32000/my-ag-ui-app:latest`
3. Pushes to local registry: `docker push localhost:32000/my-ag-ui-app:latest`
4. Updates deployment manifest: Uses `localhost:32000/my-ag-ui-app:latest` in deployment.yaml
5. Applies the deployment: `microk8s kubectl apply -f k8s/deployment.yaml`

**Verification Steps:**
```bash
# 1. Confirm image in registry
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list

# 2. Confirm deployment image reference
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.spec.template.spec.containers[0].image}'

# 3. Check if they match (both should show localhost:32000/my-ag-ui-app:latest)
# 4. Monitor pod status
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -l app=my-ag-ui-app -w
```

---

## Step-by-Step Troubleshooting

### Complete Registry Health Check

Follow these steps to perform a comprehensive registry health check:

#### Step 1: VM Health Check
```bash
# Check if VM exists and is running
multipass list | grep my-ag-ui-app-k8s

# Check VM system resources
multipass exec my-ag-ui-app-k8s -- df -h
multipass exec my-ag-ui-app-k8s -- free -h
multipass exec my-ag-ui-app-k8s -- uptime
```

#### Step 2: Microk8s Health Check
```bash
# Check microk8s status
multipass exec my-ag-ui-app-k8s -- microk8s status --wait 60

# Check microk8s addons
multipass exec my-ag-ui-app-k8s -- microk8s status --addon

# If registry addon is not enabled, enable it
multipass exec my-ag-ui-app-k8s -- microk8s enable registry
```

#### Step 3: Registry Service Check
```bash
# Check registry service status
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get svc -n container-registry

# Check registry pod status
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -n container-registry

# Check registry service endpoint
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get endpoints -n container-registry
```

#### Step 4: Registry Accessibility Check
```bash
# Test basic registry connectivity
multipass exec my-ag-ui-app-k8s -- curl -s -o /dev/null -w "%{http_code}" http://localhost:32000/v2/

# Expected response: 200 (OK)
# If 401, registry requires authentication (normal for /v2/ endpoint)
# If 404, registry endpoint not found
# If connection refused, registry service not running

# Test registry catalog access
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/_catalog

# Expected response: {"repositories":["my-ag-ui-app"]} or empty list
```

#### Step 5: Image Verification Check
```bash
# Check if your application image exists
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list

# Expected response: {"name":"my-ag-ui-app","tags":["latest"]}
# If error, image doesn't exist in registry
```

#### Step 6: Deployment Verification Check
```bash
# Check deployment configuration
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app -o yaml

# Check pod status
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -l app=my-ag-ui-app

# Check pod events for image pull issues
multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe pod -l app=my-ag-ui-app
```

---

## Diagnostic Commands

### Essential Commands

| Command | Purpose | Expected Output |
|---------|---------|-----------------|
| `multipass list` | Check VM status | VM should be Running |
| `microk8s status` | Check microk8s status | All services should be running |
| `curl -s http://localhost:32000/v2/_catalog` | Test registry accessibility | JSON list of repositories |
| `kubectl get pods -l app=my-ag-ui-app` | Check application pods | Pods should be Running |
| `kubectl get deployment my-ag-ui-app -o jsonpath='{.spec.template.spec.containers[0].image}'` | Check deployment image | Should be `localhost:32000/my-ag-ui-app:latest` |

### Advanced Diagnostic Commands

```bash
# Check registry pod logs
multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs -n container-registry -l app=registry

# Check registry pod resource usage
multipass exec my-ag-ui-app-k8s -- microk8s kubectl top pod -n container-registry -l app=registry

# Check network connectivity to registry
multipass exec my-ag-ui-app-k8s -- microk8s kubectl exec -it <pod-name> -- curl -s http://localhost:32000/v2/_catalog

# Check image pull details
multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe pod <pod-name> | grep -A 20 "Events:"
```

---

## Frequently Asked Questions

### Q: Why am I getting "connection refused" when accessing the registry?
**A:** This usually means the microk8s registry service is not running. Enable it with:
```bash
multipass exec my-ag-ui-app-k8s -- microk8s enable registry
```

### Q: Why are my pods stuck in ImagePullBackOff state?
**A:** This typically means the image specified in the deployment doesn't exist in the local registry. Check if the image exists and ensure the deployment is using the correct image reference (`localhost:32000/my-ag-ui-app:latest`).

### Q: Do I need to configure authentication for the local registry?
**A:** No, the microk8s local registry doesn't require authentication within the cluster. It's only accessible from within the Kubernetes cluster.

### Q: Can I access the local registry from outside the VM?
**A:** Not directly. The local registry is designed for internal cluster use. If you need external registry access, consider using an external registry service.

### Q: How much storage does the microk8s registry use?
**A:** By default, the microk8s registry uses 20GB of storage. This is usually sufficient for development and small deployments.

### Q: Can I use a different port for the registry?
**A:** No, the microk8s registry is hardcoded to use port 32000. This is the standard port for microk8s registry.

### Q: Why does my deployment keep pulling old versions of the image?
**A:** Kubernetes caches images locally. To force a new image pull, you can either:
1. Use a different tag (e.g., `v1.0.1` instead of `latest`)
2. Delete the existing pods to force new ones to pull the image
3. Use `imagePullPolicy: Always` in your deployment

### Q: Why do I get ImagePullBackOff errors even after successfully pushing to the local registry?
**A:** This is a classic mismatch issue. Your deployment manifest is likely still referencing `my-ag-ui-app:latest` instead of `localhost:32000/my-ag-ui-app:latest`. The registry contains the correct image, but Kubernetes is trying to pull from Docker Hub instead of your local registry.

### Q: What's the difference between `my-ag-ui-app:latest` and `localhost:32000/my-ag-ui-app:latest`?
**A:** `my-ag-ui-app:latest` tells Kubernetes to pull from Docker Hub (or the default Docker registry), while `localhost:32000/my-ag-ui-app:latest` explicitly tells Kubernetes to pull from your local microk8s registry. For local deployments to work reliably, you must use the `localhost:32000/` prefix.

### Q: I updated my deployment manifest but still get ImagePullBackOff. What else could be wrong?
**A:** Check these common issues:
1. **Image not actually in registry**: Verify with `curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list`
2. **Registry not running**: Check with `microk8s kubectl get pods -n container-registry`
3. **Wrong image reference**: Ensure deployment uses exactly `localhost:32000/my-ag-ui-app:latest`
4. **Network connectivity**: Test registry access with `curl -s http://localhost:32000/v2/_catalog`

### Q: How do I transition from external registry to local registry?
**A:** To migrate from external registry references to local registry:
1. Build and tag image for local registry: `docker tag my-ag-ui-app:latest localhost:32000/my-ag-ui-app:latest`
2. Push to local registry: `docker push localhost:32000/my-ag-ui-app:latest`
3. Update deployment.yaml: Change `image: my-ag-ui-app:latest` to `image: localhost:32000/my-ag-ui-app:latest`
4. Apply updated deployment: `microk8s kubectl apply -f k8s/deployment.yaml`
5. Verify pods pull from local registry and reach Running state

---

## Advanced Troubleshooting

### Debugging ImagePullBackOff with Local Registry

When using the local registry, ImagePullBackOff errors can be particularly frustrating because the images are often right there in the registry. Use this systematic approach:

```bash
# Step 1: Verify the problem is ImagePullBackOff
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -l app=my-ag-ui-app
# Look for STATUS: ImagePullBackOff

# Step 2: Get detailed error information
multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe pod <pod-name> | grep -A 10 "Events:"
# Look for "Failed to pull image" or "ImagePullBackOff" messages

# Step 3: Check what image the deployment is trying to pull
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.spec.template.spec.containers[0].image}'

# Step 4: Check what images are actually in the registry
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/_catalog
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list

# Step 5: Compare - if Step 3 shows "my-ag-ui-app:latest" but Step 4 shows
# repositories containing "localhost:32000/my-ag-ui-app:latest", you've found the mismatch

# Step 6: Fix the deployment image reference
multipass exec my-ag-ui-app-k8s -- microk8s kubectl set image deployment/my-ag-ui-app my-ag-ui-app=localhost:32000/my-ag-ui-app:latest

# Step 7: Delete the failing pod to trigger recreation with correct image
multipass exec my-ag-ui-app-k8s -- microk8s kubectl delete pod <pod-name>

# Step 8: Monitor the new pod
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -l app=my-ag-ui-app -w
```

### Registry Pod Issues

If the registry pod is having problems:

```bash
# Check registry pod status
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -n container-registry

# If pod is CrashLoopBackOff or ImagePullBackOff:
multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe pod -n container-registry -l app=registry

# Check registry pod logs
multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs -n container-registry -l app=registry --previous

# Restart registry pod
multipass exec my-ag-ui-app-k8s -- microk8s kubectl delete pod -n container-registry -l app=registry
```

### Persistent Volume Issues

If the registry is having storage issues:

```bash
# Check persistent volumes
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pv -n container-registry

# Check persistent volume claims
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pvc -n container-registry

# Check storage classes
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get storageclass
```

### Network Issues

If you suspect network connectivity issues:

```bash
# Test DNS resolution
multipass exec my-ag-ui-app-k8s -- nslookup localhost

# Test network connectivity
multipass exec my-ag-ui-app-k8s -- ping -c 3 localhost

# Check firewall rules
multipass exec my-ag-ui-app-k8s -- sudo iptables -L -n

# Check network policies
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get networkpolicy -A
```

---

## Getting Help

If you're still having issues after following this troubleshooting guide:

1. **Check the logs**: Always check the relevant pod logs first
2. **Search existing issues**: Check if your issue has been reported before
3. **Provide diagnostic information**: When asking for help, include:
   - Output of the Quick Diagnosis commands
   - Exact error messages you're seeing
   - Steps you've already tried
   - Your environment details (OS, multipass version, etc.)
   - For ImagePullBackOff issues: include both the deployment image reference AND the registry contents

4. **Create a minimal reproduction**: If possible, create a simple test case that demonstrates the issue

### Common Issues to Check Before Asking for Help

**For ImagePullBackOff Issues:**
Before reporting ImagePullBackOff problems, run these checks:

```bash
# 1. Check deployment image reference
DEPLOYMENT_IMAGE=$(multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.spec.template.spec.containers[0].image}')
echo "Deployment image: $DEPLOYMENT_IMAGE"

# 2. Check registry contents
REGISTRY_CONTENTS=$(multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list 2>/dev/null)
echo "Registry contents: $REGISTRY_CONTENTS"

# 3. If you see "my-ag-ui-app:latest" vs "localhost:32000/my-ag-ui-app:latest" mismatch,
#    this is your issue - fix the deployment image reference
```

**For Registry Access Issues:**
```bash
# 1. Check registry pod status
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -n container-registry

# 2. Test registry accessibility
multipass exec my-ag-ui-app-k8s -- curl -s -o /dev/null -w "%{http_code}" http://localhost:32000/v2/
```

---

**Remember**: Most registry issues are related to either the registry not being enabled, images not being pushed correctly, or deployments using the wrong image reference. The most common issue with local registry deployments is ImagePullBackOff caused by using `my-ag-ui-app:latest` instead of `localhost:32000/my-ag-ui-app:latest` in the deployment manifest. Start with the Quick Diagnosis section and work your way through the troubleshooting steps systematically.