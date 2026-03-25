# Microk8s Registry Configuration Documentation

## Overview

This document provides detailed information about the microk8s registry configuration used in this project. The local registry enables reliable, self-contained Kubernetes deployments without requiring external network access.

## Registry Details

### Basic Configuration
- **Registry Type**: microk8s built-in registry
- **Registry Endpoint**: `http://localhost:32000`
- **Registry Namespace**: `container-registry`
- **Authentication**: None required (internal cluster access only)
- **Storage**: 20GB persistent volume (default microk8s configuration)

### Image References
- **Local Image Format**: `localhost:32000/my-ag-ui-app:latest`
- **Deployment Reference**: `localhost:32000/my-ag-ui-app:latest`
- **External Image Format**: Not supported (local-only deployment)

## Registry Setup

### Prerequisites
1. Multipass VM running with name `my-ag-ui-app-k8s`
2. Microk8s installed and running in the VM
3. Sufficient disk space (minimum 20GB recommended)

### Installation and Enablement
```bash
# Enable microk8s registry
multipass exec my-ag-ui-app-k8s -- microk8s enable registry

# Wait for registry to start (approximately 30 seconds)
multipass exec my-ag-ui-app-k8s -- sleep 30

# Verify registry is accessible
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/_catalog
```

### Registry Service Details
The microk8s registry creates the following Kubernetes resources:

#### Service
```yaml
# Service details
Namespace: container-registry
Name: registry
Type: ClusterIP
Port: 32000
Target Port: 5000
```

#### Pod
```yaml
# Pod details
Namespace: container-registry
Name: registry-xxxxx (dynamic suffix)
Image: registry:2.8.1
Port: 5000
```

#### Persistent Volume
```yaml
# Storage details
Storage Class: microk8s-hostpath
Capacity: 20Gi
Access Modes: ReadWriteOnce
Mount Path: /var/lib/registry
```

## Image Management

### Building and Tagging Images
```bash
# Build image locally
docker build -t my-ag-ui-app:latest .

# Tag image for local registry
docker tag my-ag-ui-app:latest localhost:32000/my-ag-ui-app:latest

# Push to local registry
docker push localhost:32000/my-ag-ui-app:latest
```

### Verifying Images in Registry
```bash
# List all repositories
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/_catalog

# List tags for specific repository
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list
```

### Deleting Images from Registry
```bash
# Note: Microk8s registry doesn't provide built-in delete functionality
# To clear the registry, you may need to delete and recreate the registry pod
multipass exec my-ag-ui-app-k8s -- microk8s kubectl delete pod -n container-registry -l app=registry
```

## Deployment Configuration

### Required Deployment Manifest Settings
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
        image: localhost:32000/my-ag-ui-app:latest
        imagePullPolicy: IfNotPresent  # or Always for forced refresh
        # No imagePullSecrets required for local registry
```

### Important Notes
1. **No imagePullSecrets**: The local registry doesn't require authentication
2. **Image Pull Policy**: Use `IfNotPresent` for development, `Always` for production
3. **Registry Access**: Pods can only access the registry from within the cluster
4. **External Access**: The registry is not accessible from outside the VM

## Local-Only Deployment Limitations

### Deployment Environment Restrictions
The current microk8s registry configuration is designed specifically for **local development only** and has the following important limitations:

#### 1. VM-Only Deployment
- **Restriction**: Deployments can only run within the `my-ag-ui-app-k8s` multipass VM
- **Impact**: Cannot be used for production deployments or external cloud environments
- **Reason**: The `localhost:32000` registry endpoint is only accessible within the VM

#### 2. No External Registry Access
- **Restriction**: No support for external registry connections (Docker Hub, GCR, ECR, etc.)
- **Impact**: All images must be built, tagged, and pushed to the local registry
- **Workaround**: For production, a separate deployment configuration with external registry references would be needed

#### 3. Single Environment Limitation
- **Restriction**: Only supports one deployment environment (local development)
- **Impact**: Cannot easily deploy to staging, QA, or production environments
- **Consideration**: Environment-specific deployments would require separate registry configurations

#### 4. Storage Persistence Limitations
- **Restriction**: Registry storage is tied to the VM's persistent volume
- **Impact**: If the VM is deleted or recreated, all registry images are lost
- **Mitigation**: Export important images before VM maintenance or recreation

#### 5. Network Isolation
- **Restriction**: Registry is completely isolated within the VM
- **Impact**: Cannot share images between different VMs or development machines
- **Workaround**: Each developer needs their own local registry setup

#### 6. Scaling Limitations
- **Restriction**: Not designed for high-availability or multi-node deployments
- **Impact**: Limited to single-node development scenarios
- **Production Alternative**: Consider external registry services for production needs

### Migration to External Environments
When moving from local development to production environments, the following changes would be required:

#### 1. Registry Configuration Changes
```yaml
# Current (Local Development)
image: localhost:32000/my-ag-ui-app:latest

# Production (External Registry)
image: registry.example.com/my-ag-ui-app:latest
# OR
image: gcr.io/project/my-ag-ui-app:latest
# OR
image: your-dockerhub-username/my-ag-ui-app:latest
```

#### 2. Authentication Setup
```yaml
# External registries typically require authentication
spec:
  template:
    spec:
      imagePullSecrets:
      - name: registry-credentials
      containers:
      - name: my-ag-ui-app
        image: registry.example.com/my-ag-ui-app:latest
```

#### 3. Network and Security Configuration
- **External Access**: Configure registry endpoints accessible from production environment
- **Security**: Implement proper authentication and authorization
- **Network Policies**: Configure appropriate network access controls
- **HTTPS**: Enable secure registry communication

### Development Workflow Implications
These limitations affect the development workflow in the following ways:

#### 1. Developer Onboarding
- **Requirement**: Each developer must set up their own local registry
- **Process**: Follow VM setup and registry enablement procedures
- **Documentation**: Provide clear setup instructions for new team members

#### 2. Image Management
- **Process**: Images must be built and pushed locally before deployment
- **Versioning**: Use consistent tagging strategies within the local environment
- **Cleanup**: Regular cleanup of unused local images to manage storage

#### 3. Testing Strategy
- **Limitation**: Testing is restricted to the local VM environment
- **Consideration**: Additional testing stages needed for production-like environments
- **Recommendation**: Implement CI/CD pipeline with separate registry configurations for different environments

### Future Considerations
For teams planning to scale beyond local development, consider these enhancements:

#### 1. Hybrid Registry Approach
- **Local Registry**: Continue using for local development speed
- **External Registry**: Implement for staging and production deployments
- **Automation**: Create scripts to sync images between local and external registries

#### 2. Environment-Specific Configurations
- **Development**: Maintain `localhost:32000/my-ag-ui-app:latest`
- **Staging**: Use `staging-registry.example.com/my-ag-ui-app:latest`
- **Production**: Use `registry.example.com/my-ag-ui-app:latest`

#### 3. Registry Proxy Configuration
- **Local Cache**: Configure local registry as a cache for external registries
- **Fallback**: Enable pulling from external registries when images don't exist locally
- **Bandwidth Optimization**: Reduce external registry access for frequently used images

### Summary
The local-only deployment limitation is a **design choice** that prioritizes development simplicity and self-contained deployments over production scalability. This approach is ideal for:

- Individual developers working on the application
- Rapid development and testing cycles
- Environments with limited or no external network access
- Situations where deployment consistency is more important than scalability

For production deployments, a separate configuration with external registry support should be implemented, following the migration guidelines outlined above.

## Network Configuration

### Internal Network Access
- **Cluster Internal**: All pods can access `localhost:32000`
- **Service Discovery**: Registry service is available at `registry.container-registry.svc.cluster.local:5000`
- **Pod Access**: Direct access via `localhost:32000` from any pod

### External Network Access
- **Not Supported**: The registry is designed for internal cluster use only
- **Security Consideration**: External access would require additional security configuration

### Port Configuration
- **Registry Container Port**: 5000 (internal)
- **Service Port**: 32000 (external)
- **NodePort**: Not applicable (ClusterIP service)

## Storage Configuration

### Persistent Volume
- **Storage Class**: `microk8s-hostpath`
- **Default Size**: 20GB
- **Mount Path**: `/var/lib/registry`
- **Persistence**: Survives registry pod restarts

### Storage Management
```bash
# Check registry storage usage
multipass exec my-ag-ui-app-k8s -- microk8s kubectl exec -n container-registry -l app=registry -- du -sh /var/lib/registry

# Clean up unused images (requires manual pod restart)
multipass exec my-ag-ui-app-k8s -- microk8s kubectl delete pod -n container-registry -l app=registry
```

## Monitoring and Maintenance

### Health Checks
```bash
# Check registry service status
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get svc -n container-registry

# Check registry pod status
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -n container-registry

# Test registry accessibility
multipass exec my-ag-ui-app-k8s -- curl -s -o /dev/null -w "%{http_code}" http://localhost:32000/v2/
```

### Log Management
```bash
# View registry pod logs
multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs -n container-registry -l app=registry

# Follow registry pod logs
multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs -f -n container-registry -l app=registry
```

### Registry Restart
```bash
# Restart registry pod
multipass exec my-ag-ui-app-k8s -- microk8s kubectl delete pod -n container-registry -l app=registry

# The pod will be automatically recreated by the deployment
```

## Security Considerations

### Internal Security
- **Authentication**: Not required for internal cluster access
- **Authorization**: All pods have access to the registry
- **Network Policies**: No restrictions by default (can be added if needed)

### External Security
- **Exposure**: Registry is not exposed outside the cluster
- **Firewall Rules**: No external access required
- **HTTPS**: Not configured (internal HTTP only)

### Best Practices
1. **Local Development Only**: This configuration is intended for local development
2. **No Sensitive Data**: Do not store sensitive information in registry images
3. **Regular Cleanup**: Periodically clean unused images to manage storage
4. **Monitor Storage**: Keep an eye on registry storage usage

## Troubleshooting

### Common Issues
1. **Registry Not Accessible**: Enable with `microk8s enable registry`
2. **Image Pull Failures**: Verify image exists in registry and correct image reference
3. **Storage Issues**: Monitor disk usage and clean up unused images
4. **Pod Restarts**: Check registry pod logs for error messages

### Diagnostic Commands
```bash
# Complete registry health check
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get all -n container-registry

# Registry connectivity test
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/_catalog

# Image verification
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list
```

For more detailed troubleshooting information, see `REGISTRY_TROUBLESHOOTING.md`.

## Integration with Deployment Pipeline

### Deployment Script Integration
The deployment script (`deploy.sh`) handles the complete registry workflow:
1. **Build**: Creates Docker image on local machine
2. **Tag**: Tags image for local registry (`localhost:32000/my-ag-ui-app:latest`)
3. **Push**: Pushes image to microk8s registry
4. **Deploy**: Applies Kubernetes deployment with correct image reference
5. **Verify**: Confirms successful deployment and pod status

### Automated Registry Checks
The deployment script includes automated registry verification:
- Registry accessibility check
- Image existence verification
- Deployment image reference validation
- Pod status monitoring

## Configuration Reference

### Environment Variables
No specific environment variables are required for the registry configuration.

### Configuration Files
- **Kubernetes Deployment**: `k8s/deployment.yaml` (updated to use `localhost:32000/my-ag-ui-app:latest`)
- **Registry Configuration**: Managed by microk8s (no manual configuration required)

### Ports
- **32000**: External registry access port
- **5000**: Internal registry container port

## Version Information

### Current Configuration
- **Microk8s Version**: Check with `microk8s version`
- **Registry Image**: `registry:2.8.1` (default microk8s version)
- **Kubernetes API Version**: v1 (compatible with current microk8s)

### Compatibility Notes
- **Microk8s**: Tested with microk8s 1.20+ 
- **Docker**: Compatible with Docker 20.10+
- **Kubernetes**: Works with Kubernetes 1.20+ (microk8s version)

## Future Enhancements

### Potential Improvements
1. **Registry UI**: Add web interface for registry management
2. **Storage Quotas**: Implement storage limits and monitoring
3. **Image Signing**: Add image verification and signing
4. **Registry Mirroring**: Support for external registry caching
5. **Backup/Restore**: Implement registry data backup and restore

### Scaling Considerations
- **Horizontal Scaling**: Not required for local development
- **Vertical Scaling**: Increase storage if needed (VM resize required)
- **Multi-Registry Support**: Could be added for complex deployment scenarios

## Conclusion

This microk8s registry configuration provides a simple, reliable solution for local Kubernetes deployments. It eliminates the need for external network access and ensures consistent deployment behavior in development environments.

For any questions or issues with the registry configuration, please refer to the troubleshooting guide or contact the development team.

---

**Last Updated**: March 24, 2026  
**Maintainer**: Development Team  
**Version**: 1.0