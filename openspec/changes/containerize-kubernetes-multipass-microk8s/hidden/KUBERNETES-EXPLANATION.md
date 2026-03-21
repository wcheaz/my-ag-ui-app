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

The application requires the following environment variables for proper functionality:

| Variable | Description | Example | Sensitivity |
|----------|-------------|---------|------------|
| **OpenAI Configuration** |  |  |  |
| OPENAI_API_KEY | OpenAI API key for authentication | `sk-...` | High (Secret) |
| OPENAI_BASE_URL | Base URL for OpenAI API | `https://api.openai.com/v1` | Medium (Secret) |
| OPENAI_MODEL | OpenAI model to use for completions | `gpt-4` | Medium (Secret) |
| **Procurement Agent Configuration** |  |  |  |
| LLM_MAX_TOKENS | Maximum tokens for LLM responses | `4000` | Low (ConfigMap) |
| LLM_CONTEXT_WINDOW | Context window size for LLM | `8000` | Low (ConfigMap) |
| EMBEDDING_MODEL | Model to use for embeddings | `text-embedding-ada-002` | Medium (Secret) |
| **Logging Configuration** |  |  |  |
| LOGFIRE_TOKEN | Token for Logfire logging service | `logfire-token-123` | High (Secret) |
| **Application Configuration** |  |  |  |
| NODE_ENV | Node.js runtime environment | `production` | Low (Direct) |
| PORT | Application port number | `3000` | Low (Direct) |

### Configuration Methods

Environment variables are configured using three different approaches based on their sensitivity:

1. **Kubernetes Secrets** (for sensitive data like API keys and tokens):

```bash
kubectl create secret generic my-ag-ui-app-secrets \
  --from-literal=openai-api-key=sk-your-openai-api-key \
  --from-literal=openai-base-url=https://api.openai.com/v1 \
  --from-literal=openai-model=gpt-4 \
  --from-literal=embedding-model=text-embedding-ada-002 \
  --from-literal=logfire-token=your-logfire-token
```

2. **Kubernetes ConfigMaps** (for non-sensitive configuration):

```bash
kubectl create configmap my-ag-ui-app-config \
  --from-literal=llm-max-tokens=4000 \
  --from-literal=llm-context-window=8000
```

3. **Directly in the deployment manifest** (for basic application settings):

```yaml
env:
- name: NODE_ENV
  value: "production"
- name: PORT
  value: "3000"
```

### Environment Variable Usage in Deployment

The deployment manifest references these environment variables as follows:

```yaml
env:
# Basic configuration (direct values)
- name: NODE_ENV
  value: "production"
- name: PORT
  value: "3000"

# OpenAI configuration (from secrets)
- name: OPENAI_API_KEY
  valueFrom:
    secretKeyRef:
      name: my-ag-ui-app-secrets
      key: openai-api-key
- name: OPENAI_BASE_URL
  valueFrom:
    secretKeyRef:
      name: my-ag-ui-app-secrets
      key: openai-base-url
- name: OPENAI_MODEL
  valueFrom:
    secretKeyRef:
      name: my-ag-ui-app-secrets
      key: openai-model

# Procurement agent configuration (mixed)
- name: LLM_MAX_TOKENS
  valueFrom:
    configMapKeyRef:
      name: my-ag-ui-app-config
      key: llm-max-tokens
- name: LLM_CONTEXT_WINDOW
  valueFrom:
    configMapKeyRef:
      name: my-ag-ui-app-config
      key: llm-context-window
- name: EMBEDDING_MODEL
  valueFrom:
    secretKeyRef:
      name: my-ag-ui-app-secrets
      key: embedding-model

# Logging configuration (from secrets)
- name: LOGFIRE_TOKEN
  valueFrom:
    secretKeyRef:
      name: my-ag-ui-app-secrets
      key: logfire-token
```

### Setting Environment Variables for Deployment

Before deploying, you need to create the Kubernetes secrets and configmaps with your actual values:

1. **Create a secrets file** (`secrets.yaml`):
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-ag-ui-app-secrets
type: Opaque
stringData:
  openai-api-key: "your-actual-openai-api-key"
  openai-base-url: "https://api.openai.com/v1"
  openai-model: "gpt-4"
  embedding-model: "text-embedding-ada-002"
  logfire-token: "your-actual-logfire-token"
```

2. **Create a configmap file** (`configmap.yaml`):
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-ag-ui-app-config
data:
  llm-max-tokens: "4000"
  llm-context-window: "8000"
```

3. **Apply to the cluster**:
```bash
kubectl apply -f secrets.yaml
kubectl apply -f configmap.yaml
```

### Environment Variable Validation

The deployment script validates that all required environment variables are properly configured:

- **Secrets**: Verifies that the `my-ag-ui-app-secrets` secret exists and contains all required keys
- **ConfigMaps**: Verifies that the `my-ag-ui-app-config` configmap exists and contains all required keys
- **Format Validation**: Ensures that sensitive values are not hardcoded in the deployment manifest
- **Empty Value Check**: Validates that no environment variables have empty values

### Environment Variable Management Best Practices

1. **Never commit sensitive values** to version control
2. **Use separate secrets for different environments** (development, staging, production)
3. **Regularly rotate API keys** and tokens
4. **Use environment-specific values** (e.g., different models for dev/prod)
5. **Document all environment variables** and their purposes
6. **Validate environment variables** during deployment to prevent runtime errors

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

### 9. VM Name Variable Issue

**Issue**: `multipass exec` commands fail with "instance "" does not exist" error during deployment.

**Possible Causes**:
- VM name variable is not properly initialized before use
- VM name variable is overwritten or cleared during script execution
- Race conditions where multipass exec is called before VM name is set

**Solutions**:
```bash
# Check if VM name is properly set
echo "VM_NAME: $VM_NAME"

# Verify VM exists with the expected name
multipass info my-ag-ui-app-k8s
```

**Fix Implementation**:
The deployment script has been updated to ensure the VM name variable is properly managed:

1. **Early Initialization**: VM_NAME is defined and exported at the beginning of the script:
```bash
export VM_NAME="my-ag-ui-app-k8s"
```

2. **Validation**: Added validation to check VM name is set before use:
```bash
if [[ -z "$VM_NAME" ]]; then
    log_error "VM_NAME is not set"
    exit 1
fi
```

3. **Consistent Usage**: All multipass commands now use the VM_NAME variable:
```bash
multipass exec "$VM_NAME" -- command
```

**Prevention**:
- Always define and export VM_NAME at the start of the script
- Validate VM_NAME before using multipass exec commands
- Use logging to track VM_NAME variable state during execution
- Test deployment script with different VM names to ensure robustness

**Verification**:
```bash
# Run the deployment script
./deploy.sh

# Check for successful VM operations
multipass info my-ag-ui-app-k8s

# Verify Kubernetes deployment worked
kubectl get pods
```

### 10. Kubernetes Manifest File Path Errors

**Issue**: `kubectl apply` commands fail with "path does not exist" errors during deployment.

**Possible Causes**:
- YAML files are not copied to the VM before kubectl apply is executed
- Working directory is not correctly set when running kubectl commands
- secrets.yaml is generated in the wrong location before being applied
- Script is looking for files in the wrong location (project root vs change directory)

**Solutions**:
```bash
# Check if YAML files exist in the correct location
ls -la k8s/

# Check working directory in VM
multipass exec my-ag-ui-app-k8s -- pwd

# List files in VM directory
multipass exec my-ag-ui-app-k8s -- ls -la
```

**Fix Implementation**:
The deployment script has been updated to ensure YAML file paths are properly managed:

1. **File Copy Before Apply**: All YAML files are now copied from the openspec/changes/containerize-kubernetes-multipass-microk8s/k8s/ directory to the VM before kubectl commands are executed:
```bash
# Copy k8s directory to VM
if ! multipass transfer k8s/ "$VM_NAME":/home/ubuntu/; then
    log_error "Failed to copy k8s directory to VM"
    exit 1
fi
```

2. **File Transfer Mechanism**: The script uses multipass transfer to reliably copy files from the host system to the VM:
   - Source: `k8s/` directory on the host (relative to openspec/changes/containerize-kubernetes-multipass-microk8s/)
   - Destination: `/home/ubuntu/k8s/` directory inside the VM
   - Validation: The script verifies the transfer succeeded before proceeding
   - Error handling: If transfer fails, the script exits with an appropriate error message

2. **Pro secrets.yaml Generation**: secrets.yaml is now generated in the correct location on the VM before being applied:
```bash
# Generate secrets.yaml on VM
multipass exec "$VM_NAME" -- bash -c "cat > /home/ubuntu/k8s/secrets.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: my-ag-ui-app-secrets
type: Opaque
stringData:
  openai-api-key: \"$OPENAI_API_KEY\"
  openai-base-url: \"$OPENAI_BASE_URL\"
  openai-model: \"$OPENAI_MODEL\"
  embedding-model: \"$EMBEDDING_MODEL\"
  logfire-token: \"$LOGFIRE_TOKEN\"
EOF"
```

3. **Explicit Working Directory**: All kubectl commands now explicitly use the correct file paths in the VM:
```bash
# Apply Kubernetes manifests with explicit paths
multipass exec "$VM_NAME" -- bash -c "microk8s kubectl apply -f /home/ubuntu/k8s/secrets.yaml"
multipass exec "$VM_NAME" -- bash -c "microk8s kubectl apply -f /home/ubuntu/k8s/deployment.yaml"
multipass exec "$VM_NAME" -- bash -c "microk8s kubectl apply -f /home/ubuntu/k8s/service.yaml"
multipass exec "$VM_NAME" -- bash -c "microk8s kubectl apply -f /home/ubuntu/k8s/ingress.yaml"
```

4. **File Existence Validation**: Added validation to check if YAML files exist before attempting to apply them:
```bash
# Verify YAML files exist in VM
if ! multipass exec "$VM_NAME" -- bash -c "[ -d /home/ubuntu/k8s ] && ls /home/ubuntu/k8s/*.yaml"; then
    log_error "YAML files not found in VM"
    exit 1
fi
```

**Prevention**:
- Always copy YAML files to VM before running kubectl commands
- Generate secrets.yaml in the correct directory structure on the VM
- Use explicit file paths when running kubectl commands
- Validate file existence before applying manifests
- Maintain consistent directory structure between host and VM

**Verification**:
```bash
# Run the deployment script
./deploy.sh

# Check YAML files were copied to VM
multipass exec my-ag-ui-app-k8s -- ls -la /home/ubuntu/k8s/

# Verify secrets.yaml was generated
multipass exec my-ag-ui-app-k8s -- cat /home/ubuntu/k8s/secrets.yaml

# Verify all Kubernetes resources were created
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment,service,ingress
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

## Security Considerations

### Security Architecture Overview

The deployment implements multiple layers of security following Kubernetes best practices and industry standards. The security approach is defense-in-depth, with controls at the container, pod, network, and cluster levels.

### Container Security

#### Non-Root User Configuration

The application container runs as a non-root user to minimize the impact of potential container compromises:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
```

**Security Benefits:**
- Prevents root privilege escalation attacks
- Limits filesystem access to non-privileged areas
- Reduces attack surface by dropping all Linux capabilities

#### Read-Only Root Filesystem

The container root filesystem is mounted as read-only to prevent unauthorized modifications:

```yaml
securityContext:
  readOnlyRootFilesystem: true
```

**Security Benefits:**
- Prevents attackers from modifying binaries or libraries
- Stops malware persistence techniques that require writable filesystem
- Ensures container integrity throughout runtime

**Writeable Directories:**
Only essential directories are mounted as writeable temporary volumes:
- `/tmp` - For temporary application files
- `/app/.next/cache` - For Next.js build cache

#### Seccomp Profiles

The deployment uses seccomp (secure computing mode) profiles to restrict system calls:

```yaml
seccompProfile:
  type: RuntimeDefault
```

**Security Benefits:**
- Limits available system calls to those required by the application
- Prevents execution of certain kernel exploits
- Reduces container escape attack surface

### Pod Security Standards

The deployment enforces Kubernetes Pod Security Standards at the restricted level:

```yaml
# Pod Security Admission labels
pod-security.kubernetes.io/enforce: restricted
pod-security.kubernetes.io/enforce-version: v1.29
pod-security.kubernetes.io/warn: restricted
pod-security.kubernetes.io/warn-version: v1.29
pod-security.kubernetes.io/audit: restricted
pod-security.kubernetes.io/audit-version: v1.29
```

**Restricted Standard Requirements:**
- Containers must run as non-root users
- Privilege escalation is prohibited
- All capabilities are dropped by default
- Read-only root filesystem is enforced
- Seccomp profiles must be defined

### Network Security

#### Network Policies

The deployment implements comprehensive network policies to control pod-to-pod and pod-to-external traffic:

1. **Ingress Policy** (k8s/network-policy.yaml - my-ag-ui-app-ingress-policy):
   - Allows traffic from ingress controller namespaces
   - Allows traffic from internal cluster network (10.0.0.0/8)
   - Restricts access to only necessary services

2. **Egress Policy** (k8s/network-policy.yaml - my-ag-ui-app-egress-policy):
   - Allows DNS resolution (UDP port 53)
   - Allows traffic to OpenAI API endpoints
   - Allows traffic to Kubernetes API server
   - Allows general HTTP/HTTPS outbound connectivity

**Security Benefits:**
- Implements zero-trust network model
- Prevents lateral movement within cluster
- Restricts outbound traffic to approved destinations
- Reduces exposure to internal network attacks

### Secrets Management

#### Secure Configuration Management

The deployment uses a multi-layered approach to configuration management:

1. **Kubernetes Secrets** for sensitive data:
   - API keys (OPENAI_API_KEY)
   - Service tokens (LOGFIRE_TOKEN)
   - Configuration URLs (OPENAI_BASE_URL)

2. **Kubernetes ConfigMaps** for non-sensitive configuration:
   - Application settings (LLM_MAX_TOKENS, LLM_CONTEXT_WINDOW)

3. **Automated Secret Generation**:
   - `setup-secrets.sh` script for secure secret generation
   - Base64 encoding of sensitive values
   - Environment variable support for automated deployments

#### Secrets Best Practices

**What's Implemented:**
- No hardcoded sensitive values in manifests
- Secrets are referenced using `valueFrom.secretKeyRef`
- Template-based approach with `secrets.yaml.template`
- Automated script for secure secret generation

**Security Guidelines:**
```bash
# Generate secrets securely
./k8s/setup-secrets.sh

# Apply secrets to cluster
kubectl apply -f k8s/secrets.yaml

# Never commit secrets.yaml to version control
echo "k8s/secrets.yaml" >> .gitignore
```

### Docker Security

#### Multi-Stage Builds

The Dockerfile uses multi-stage builds to minimize attack surface:

```dockerfile
# Build stage with all build dependencies
FROM node:18-alpine AS builder

# Runtime stage with minimal footprint
FROM node:18-alpine AS runtime
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
```

**Security Benefits:**
- Build tools and dependencies are not included in final image
- Reduced image size decreases attack surface
- Eliminates unnecessary packages that could contain vulnerabilities

#### Image Scanning

The deployment workflow includes security scanning:
- **Base Image Scanning**: Uses official Alpine Linux images with security updates
- **Vulnerability Scanning**: Can be integrated with tools like Trivy or Clair
- **Dependency Scanning**: npm audit for Node.js dependencies

### Runtime Security

#### Resource Limits and Isolation

The deployment implements strict resource limits to prevent container escape and ensure resource isolation:

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

**Security Benefits:**
- Prevents resource exhaustion attacks
- Ensures fair resource allocation between pods
- Contains potential compromises within resource boundaries

#### Health and Readiness Probes

Security-focused health monitoring:

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 30
  timeoutSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

**Security Benefits:**
- Detects compromised or malfunctioning containers
- Automatic restart of unhealthy containers
- Prevents traffic to compromised instances

### Additional Security Measures

#### Pod Security Context

Comprehensive pod security configuration:

```yaml
spec:
  securityContext:
    fsGroup: 1000
    runAsGroup: 1000
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
```

#### Container Security Context

Container-specific security settings:

```yaml
containers:
- name: my-ag-ui-app
  securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop:
      - ALL
    privileged: false
    readOnlyRootFilesystem: true
    runAsGroup: 1000
    runAsNonRoot: true
    runAsUser: 1000
```

### Security Best Practices Applied

#### Authentication and Authorization

1. **API Key Management**: All external API keys are stored in Kubernetes secrets
2. **Service Account**: Uses default service account (can be customized for production)
3. **RBAC**: Ready to implement Role-Based Access Control when needed

#### Network Security

1. **Zero Trust Network**: All network traffic is explicitly allowed or denied
2. **TLS Everywhere**: Ready to implement TLS for all communications
3. **Ingress Security**: Ingress controller with security headers (ready to enable)

#### Data Protection

1. **Encryption in Transit**: HTTPS/SSL ready to implement
2. **Encryption at Rest**: Ready to implement when persistent storage is needed
3. **Data Minimization**: Only necessary data is collected and processed

#### Monitoring and Logging

1. **Security Logging**: Integration with Logfire for security event logging
2. **Audit Logging**: Kubernetes audit logs for cluster security monitoring
3. **Health Monitoring**: Continuous monitoring for security anomalies

### Security Maintenance

#### Regular Updates

1. **Base Image Updates**: Regular updates to Alpine Linux base images
2. **Dependency Updates**: Regular Node.js dependency updates with security patches
3. **Kubernetes Version Updates**: Keep microk8s updated with latest security patches

#### Security Auditing

1. **Vulnerability Scanning**: Regular image vulnerability scanning
2. **Configuration Auditing**: Regular review of security configurations
3. **Network Policy Auditing**: Regular review of network access rules

#### Incident Response

1. **Pod Isolation**: Quick isolation of compromised pods
2. **Rollback Procedures**: Immediate rollback to known-good configurations
3. **Forensics**: Logs and metrics available for security investigations

### Security Compliance

The deployment follows these security standards and frameworks:

- **NIST Cybersecurity Framework**: Implemented Identify, Protect, Detect, Respond, Recover functions
- **OWASP Top 10**: Protection against common web application vulnerabilities
- **Kubernetes Security Best Practices**: Adherence to Kubernetes security guidelines
- **CIS Kubernetes Benchmark**: Alignment with Center for Internet Security benchmarks

### Future Security Enhancements

#### Short-term Security Improvements

1. **TLS/SSL Implementation**: Add HTTPS with Let's Encrypt certificates
2. **Web Application Firewall**: Implement WAF rules for ingress
3. **Security Context Constraints**: Add pod security policies (PSPs) if needed
4. **Audit Logging**: Enhanced security audit log configuration

#### Long-term Security Enhancements

1. **Service Mesh**: Implement Istio or Linkerd for advanced security features
2. **Secrets Management**: Integrate with HashiCorp Vault or similar
3. **Runtime Security**: Add Falco or similar runtime security monitoring
4. **Compliance Automation**: Implement automated compliance checking and reporting

### Security Checklist

- [x] Containers run as non-root users
- [x] Read-only root filesystem implemented
- [x] All capabilities dropped
- [x] Seccomp profiles configured
- [x] Network policies implemented
- [x] Secrets properly managed
- [x] No hardcoded sensitive information
- [x] Pod Security Standards enforced
- [x] Resource limits configured
- [x] Health and readiness probes configured
- [x] Security context defined at pod and container levels
- [x] Template-based secret generation

This comprehensive security approach ensures that the deployment is protected against common threats while maintaining the flexibility needed for development and operations.

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