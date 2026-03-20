# Kubernetes Deployment Explanation

This document provides detailed technical information about the Kubernetes deployment implementation for the my-ag-ui-app.

## Overview

The application has been containerized and deployed using a Kubernetes cluster running within a multipass-managed VM. This deployment provides isolation, resource control, and a production-ready environment for the application.

## VM Configuration

### Virtual Machine Specifications

The deployment uses a multipass VM with the following configuration:

- **CPU**: 4 cores
- **Memory**: 7.7GiB RAM
- **Disk**: 19.3GiB storage
- **Name**: my-ag-ui-app-k8s

These specifications were chosen to:
- Meet microk8s minimum requirements (2 CPUs, 4GB RAM)
- Provide sufficient resources for the application and Kubernetes overhead
- Match the proven configuration from outlook-monitor-vm

### VM Creation

The VM is created using the multipass command:

```bash
multipass launch --cpus 4 --memory 7.7G --disk 19.3G --name my-ag-ui-app-k8s
```

### VM Access

To access the VM for debugging:

```bash
# SSH into the VM
multipass shell my-ag-ui-app-k8s

# Execute commands in the VM
multipass exec my-ag-ui-app-k8s -- <command>
```

### VM Management

```bash
# Check VM status
multipass info my-ag-ui-app-k8s

# Stop the VM
multipass stop my-ag-ui-app-k8s

# Start the VM
multipass start my-ag-ui-app-k8s

# Delete the VM
multipass delete my-ag-ui-app-k8s
multipass purge
```

## Microk8s Configuration

### Microk8s Installation

Microk8s is installed within the VM using the snap package manager:

```bash
multipass exec my-ag-ui-app-k8s -- sudo snap install microk8s --classic
```

### Enabled Add-ons

The following microk8s add-ons are enabled:

1. **dns**: Provides DNS service for service discovery within the cluster
2. **storage**: Provides persistent storage capabilities
3. **ingress**: Provides ingress controller for external access

```bash
multipass exec my-ag-ui-app-k8s -- microk8s enable dns
multipass exec my-ag-ui-app-k8s -- microk8s enable storage
multipass exec my-ag-ui-app-k8s -- microk8s enable ingress
```

### Microk8s Status Check

To verify microk8s status:

```bash
multipass exec my-ag-ui-app-k8s -- microk8s status
```

### Microk8s Command Access

All microk8s commands are executed within the VM using:

```bash
multipass exec my-ag-ui-app-k8s -- microk8s kubectl <command>
```

For convenience, the deployment script creates an alias function in the VM:

```bash
kubectl() {
  multipass exec my-ag-ui-app-k8s -- microk8s kubectl "$@"
}
```

## Kubernetes Manifests

The deployment uses three main Kubernetes manifests located in the `k8s/` directory:

### 1. Deployment (k8s/deployment.yaml)

The deployment manifest defines how the application container is deployed:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-ag-ui-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-ag-ui-app
  template:
    metadata:
      labels:
        app: my-ag-ui-app
    spec:
      containers:
      - name: my-ag-ui-app
        image: my-ag-ui-app:latest
        ports:
        - containerPort: 3000
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 1
```

**Key Features:**
- **Replica Count**: 1 pod (can be increased for scaling)
- **Resource Limits**: CPU (100m-500m), Memory (128Mi-512Mi)
- **Health Checks**: Liveness and readiness probes on `/health` endpoint
- **Container Port**: 3000 (Next.js default)

### 2. Service (k8s/service.yaml)

The service manifest defines how the application is exposed within the cluster:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-ag-ui-app-service
spec:
  selector:
    app: my-ag-ui-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: ClusterIP
```

**Key Features:**
- **Service Type**: ClusterIP (internal only)
- **Port Mapping**: External port 80 to container port 3000
- **Selector**: Routes traffic to pods with `app: my-ag-ui-app` label

### 3. Ingress (k8s/ingress.yaml)

The ingress manifest defines how the application is exposed externally:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ag-ui-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-ag-ui-app-service
            port:
              number: 80
```

**Key Features:**
- **Ingress Class**: nginx (microk8s default)
- **Path Routing**: Root path (`/`) to the application
- **Backend Service**: Routes to `my-ag-ui-app-service` on port 80

## Ingress Configuration

### Ingress Controller

The deployment uses the built-in microk8s ingress controller (NGINX-based). This controller is automatically installed when the ingress add-on is enabled.

### Accessing the Application

The application is accessible through the ingress endpoint. To get the ingress URL:

```bash
kubectl get ingress my-ag-ui-app-ingress
```

For local development, you can also access the application using port forwarding:

```bash
kubectl port-forward svc/my-ag-ui-app-service 8080:80
```

Then access the application at `http://localhost:8080`.

### SSL/TLS Configuration

Currently, SSL/TLS is not configured for the ingress. For production use, you can:

1. Use Let's Encrypt certificates
2. Create a self-signed certificate for development
3. Use existing certificates

Example configuration for SSL (to be added when needed):

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ag-ui-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - your-domain.com
    secretName: my-ag-ui-app-tls
  rules:
  - host: your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-ag-ui-app-service
            port:
              number: 80
```

## Deployment Script Usage

### Main Deployment Script (deploy.sh)

The `deploy.sh` script automates the entire deployment process:

```bash
# Execute the deployment
./deploy.sh

# Execute with verbose output
./deploy.sh -v

# Execute in dry-run mode (shows what would be done)
./deploy.sh --dry-run
```

### Script Components

The deployment script consists of the following phases:

1. **Pre-deployment Checks**
   - Verify multipass installation
   - Verify Docker installation
   - Check system resources

2. **VM Provisioning**
   - Create multipass VM
   - Wait for VM readiness
   - Verify VM networking

3. **Microk8s Installation**
   - Install microk8s in VM
   - Enable required add-ons
   - Wait for microk8s to be ready

4. **Container Build**
   - Build Docker image
   - Tag image appropriately
   - Prepare image for Kubernetes

5. **Kubernetes Deployment**
   - Apply deployment manifest
   - Apply service manifest
   - Apply ingress manifest

6. **Verification**
   - Check pod status
   - Verify service accessibility
   - Test application access

### Cleanup Script (cleanup.sh)

The `cleanup.sh` script removes all deployed resources:

```bash
# Execute cleanup
./cleanup.sh

# Execute cleanup without confirmation
./cleanup.sh -f
```

## Environment Variables

### Required Environment Variables

The application requires the following environment variables:

| Variable | Description | Example |
|----------|-------------|---------|
| NODE_ENV | Node.js environment | `production` |
| PORT | Application port | `3000` |
| API_BASE_URL | Base URL for API calls | `http://localhost:3001/api` |
| DATABASE_URL | Database connection string | `postgresql://user:pass@localhost/db` |
| SECRET_KEY | Application secret key | `your-secret-key` |

### Configuration Methods

Environment variables can be configured using:

1. **Kubernetes Secrets** (for sensitive data):

```bash
kubectl create secret generic app-secrets \
  --from-literal=SECRET_KEY=your-secret-key \
  --from-literal=DATABASE_URL=postgresql://user:pass@localhost/db
```

2. **Kubernetes ConfigMaps** (for non-sensitive data):

```bash
kubectl create configmap app-config \
  --from-literal=NODE_ENV=production \
  --from-literal=PORT=3000
```

3. **Directly in the deployment manifest** (for non-sensitive data):

```yaml
env:
- name: NODE_ENV
  value: "production"
- name: PORT
  value: "3000"
```

## Resource Scaling Recommendations

### Vertical Scaling

To adjust resource limits for the deployment:

1. **CPU Limits**:
   - Minimum: 100m (0.1 CPU)
   - Recommended: 100m - 500m
   - Maximum: 1000m (1 CPU)

2. **Memory Limits**:
   - Minimum: 128Mi
   - Recommended: 128Mi - 512Mi
   - Maximum: 1Gi

### Horizontal Scaling

To increase the number of replicas:

```bash
# Scale to 3 replicas
kubectl scale deployment my-ag-ui-app --replicas=3

# Or edit the deployment manifest
kubectl edit deployment my-ag-ui-app
```

Consider scaling when:
- CPU usage consistently exceeds 80%
- Memory usage consistently exceeds 80%
- Response times increase significantly
- You need higher availability

### VM Scaling

To scale the VM resources:

1. **Delete the existing VM**:
   ```bash
   multipass delete my-ag-ui-app-k8s
   multipass purge
   ```

2. **Create a new VM with updated resources**:
   ```bash
   multipass launch --cpus 8 --memory 15G --disk 40G --name my-ag-ui-app-k8s
   ```

3. **Re-run the deployment script**:
   ```bash
   ./deploy.sh
   ```

## Rollback Procedures

### Quick Rollback

To quickly rollback to a previous deployment version:

```bash
# Rollback to previous revision
kubectl rollout undo deployment my-ag-ui-app

# Check rollback status
kubectl rollout status deployment my-ag-ui-app
```

### Complete Rollback

For a complete rollback to the previous state:

1. **Delete Kubernetes resources**:
   ```bash
   kubectl delete -f k8s/
   ```

2. **Remove microk8s** (if needed):
   ```bash
   multipass exec my-ag-ui-app-k8s -- sudo snap remove microk8s
   ```

3. **Delete VM** (if needed):
   ```bash
   multipass delete my-ag-ui-app-k8s
   multipass purge
   ```

4. **Restore previous state** (if applicable):
   - Restore database from backup
   - Restore configuration files
   - Re-deploy using previous deployment method

### Rollback to Specific Revision

To rollback to a specific revision:

```bash
# View revision history
kubectl rollout history deployment my-ag-ui-app

# Rollback to specific revision
kubectl rollout undo deployment my-ag-ui-app --to-revision=<revision-number>
```

## Common Issues and Solutions

### 1. VM Creation Fails

**Issue**: `multipass launch` fails with error messages.

**Possible Causes**:
- Multipass not installed
- Insufficient system resources
- Network connectivity issues

**Solutions**:
```bash
# Check multipass installation
multipass --version

# If not installed, install multipass
# Ubuntu/Debian:
sudo snap install multipass

# Check system resources
free -h
nproc

# Check available disk space
df -h
```

### 2. Microk8s Installation Fails

**Issue**: Microk8s installation fails or add-ons won't enable.

**Possible Causes**:
- VM resources insufficient
- Network connectivity issues
- Snap package issues

**Solutions**:
```bash
# Check VM resources
multipass exec my-ag-ui-app-k8s -- free -h
multipass exec my-ag-ui-app-k8s -- nproc

# Check network connectivity
multipass exec my-ag-ui-app-k8s -- ping google.com

# Reinstall microk8s
multipass exec my-ag-ui-app-k8s -- sudo snap remove microk8s
multipass exec my-ag-ui-app-k8s -- sudo snap install microk8s --classic
```

### 3. Pod Stuck in Pending State

**Issue**: Pods remain in pending state and don't start.

**Possible Causes**:
- Insufficient resources in cluster
- Image pull issues
- Node readiness issues

**Solutions**:
```bash
# Check pod events
kubectl describe pod <pod-name>

# Check node status
kubectl get nodes

# Check cluster resources
kubectl top nodes

# Check if image can be pulled
kubectl describe deployment my-ag-ui-app
```

### 4. Application Not Accessible via Ingress

**Issue**: Application is not accessible through the ingress endpoint.

**Possible Causes**:
- Ingress controller not ready
- Service not correctly configured
- Network policies blocking traffic

**Solutions**:
```bash
# Check ingress status
kubectl get ingress my-ag-ui-app-ingress

# Check ingress controller pods
kubectl get pods -n ingress

# Check service status
kubectl get svc my-ag-ui-app-service

# Check ingress controller logs
kubectl logs -n ingress <ingress-pod-name>
```

### 5. Container Build Fails

**Issue**: Docker build fails during deployment.

**Possible Causes**:
- Missing dependencies
- Syntax errors in Dockerfile
- Insufficient build resources

**Solutions**:
```bash
# Test build locally
docker build -t test-build .

# Check Dockerfile syntax
docker build --no-cache -t test-build .

# Check for missing files
ls -la
```

### 6. Health Check Failures

**Issue**: Liveness or readiness probes fail.

**Possible Causes**:
- Health endpoint not implemented
- Application not ready within timeout
- Network issues within pod

**Solutions**:
```bash
# Check health endpoint from inside pod
kubectl exec -it <pod-name> -- curl http://localhost:3000/health

# Check pod logs
kubectl logs <pod-name>

# Adjust probe timeouts in deployment.yaml
# Increase initialDelaySeconds or periodSeconds
```

### 7. Resource Limits Exceeded

**Issue**: Pods are being OOM killed or CPU throttled.

**Possible Causes**:
- Resource limits too low
- Memory leaks in application
- Insufficient VM resources

**Solutions**:
```bash
# Check resource usage
kubectl top pods

# Check for OOM events
kubectl describe pod <pod-name> | grep -i oom

# Adjust resource limits in deployment.yaml
# Increase requests and limits
```

### 8. Persistent Storage Issues

**Issue**: Data is lost when pods restart.

**Possible Causes**:
- No persistent volumes configured
- Persistent volume claims not bound

**Solutions**:
```bash
# Check persistent volume claims
kubectl get pvc

# Check persistent volumes
kubectl get pv

# Configure persistent storage in deployment.yaml if needed
```

## Monitoring and Maintenance

### Checking Deployment Status

```bash
# Check overall status
kubectl get pods,svc,ingress

# Check deployment details
kubectl describe deployment my-ag-ui-app

# Check pod logs
kubectl logs -f deployment/my-ag-ui-app
```

### Health Checks

The deployment includes liveness and readiness probes:

- **Liveness Probe**: Checks `/health` endpoint every 10 seconds
- **Readiness Probe**: Checks `/health` endpoint every 5 seconds

### Logging

Application logs can be viewed using:

```bash
# View all logs
kubectl logs -f deployment/my-ag-ui-app

# View logs for specific pod
kubectl logs -f <pod-name>

# View logs from previous container
kubectl logs -f <pod-name> --previous
```

### Backup and Recovery

To backup the deployment:

```bash
# Export all manifests
kubectl get all -o yaml > backup.yaml

# Backup any secrets
kubectl get secrets -o yaml > secrets-backup.yaml

# Backup configmaps
kubectl get configmaps -o yaml > configmaps-backup.yaml
```

## Next Steps and Enhancements

### Short-term Enhancements

1. **SSL/TLS Configuration**: Implement HTTPS using Let's Encrypt or self-signed certificates
2. **Resource Monitoring**: Add Prometheus/Grafana for monitoring
3. **Log Aggregation**: Implement centralized logging with ELK stack or similar
4. **Horizontal Pod Autoscaling**: Configure autoscaling based on CPU/memory usage

### Long-term Enhancements

1. **Multi-node Cluster**: Extend to multiple VMs for high availability
2. **CI/CD Integration**: Integrate with GitLab CI or GitHub Actions
3. **Database Deployment**: Deploy database within Kubernetes
4. **Backup Automation**: Implement automated backups and restore procedures

## Conclusion

This Kubernetes deployment provides a robust, scalable environment for the my-ag-ui-app. The combination of multipass for VM management, microk8s for Kubernetes, and automated deployment scripts creates a production-ready infrastructure that can be easily maintained and scaled.

The deployment follows best practices for resource management, health checking, and monitoring while maintaining simplicity for development and testing workflows.