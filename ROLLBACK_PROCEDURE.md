# Rollback Procedures

This document describes the error handling and rollback procedures for the deployment pipeline.

## Overview

The deployment pipeline includes automatic rollback capabilities to ensure service availability and minimize downtime when deployment failures occur. The system is designed to detect failures, log structured error information, and automatically restore the previous stable deployment state.

## Automatic Rollback Process

### Trigger Conditions

Automatic rollback is triggered when any of the following conditions occur:
1. **Script Failure**: Any deployment script exits with a non-zero code
2. **Command Timeout**: Any command exceeds its timeout limit
3. **Validation Failure**: Kubernetes manifest validation fails
4. **Resource Unavailable**: Required resources (VM, registry, Kubernetes) are unavailable

### Rollback Sequence

When a failure is detected, the system performs the following steps:

1. **Error Detection**
   ```bash
   [2026-03-27 18:05:55] ERROR: ❌ STEP 1 FAILED: Failed to set up Kubernetes secrets
   ```

2. **Rollback Initiation**
   ```bash
   [2026-03-27 18:05:55] ERROR: 🔄 INITIATING ROLLBACK PROCEDURE
   [2026-03-27 18:05:55] ERROR: Deployment failed - attempting to restore previous state
   ```

3. **Backup File Transfer**
   ```bash
   [2026-03-27 18:05:55] INFO: 🔄 Transferring backup deployment manifest to VM...
   ```

4. **Backup Application**
   ```bash
   deployment.apps/my-ag-ui-app configured
   ```

5. **Rollback Completion**
   ```bash
   [2026-03-27 18:05:55] INFO: ✅ ROLLBACK SUCCESSFUL: Previous deployment state restored
   [2026-03-27 18:05:55] INFO:    Services should be returning to previous stable state
   ```

### Rollback Components

The rollback system uses the following components:

- **Backup Manifest**: `k8s/deployment.yaml.backup` - Contains the last known good deployment configuration
- **Rollback Function**: `rollback_deployment()` in `deploy-all.sh` - Handles the rollback process
- **Error Handling**: `log_structured_error()` in `deploy_scripts/common.sh` - Provides structured error information
- **Backup Transfer**: Multipass file transfer to ensure backup is available in the VM

## Manual Rollback Procedures

### Scenario 1: Automatic Rollback Failed

If the automatic rollback fails, you can manually restore the deployment:

```bash
# Check if backup file exists
ls -la k8s/deployment.yaml.backup

# Manually apply the backup deployment
multipass transfer k8s/deployment.yaml.backup my-ag-ui-app-k8s:/home/ubuntu/deployment.yaml.backup
multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/deployment.yaml.backup
```

### Scenario 2: Need to Rollback to Specific Version

If you need to rollback to a specific previous version:

```bash
# List available backup files
ls -la k8s/deployment.yaml.backup*

# Choose the appropriate backup file and apply it
multipass transfer k8s/deployment.yaml.backup.20260327_213120 my-ag-ui-app-k8s:/home/ubuntu/backup.yaml
multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/backup.yaml
```

### Scenario 3: Complete Environment Reset

For a complete environment reset:

```bash
# Delete the current deployment
multipass exec my-ag-ui-app-k8s -- microk8s kubectl delete deployment my-ag-ui-app

# Apply the backup deployment
multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/deployment.yaml.backup

# Wait for pods to be ready
multipass exec my-ag-ui-app-k8s -- microk8s kubectl wait --for=condition=ready pod -l app=my-ag-ui-app --timeout=300s
```

## Common Error Scenarios and Recovery

### 1. IMAGE_VERIFICATION_TIMEOUT

**Error Message**:
```
ERROR TYPE: IMAGE_VERIFICATION_TIMEOUT
DIAGNOSTIC: Image verification failed after 7 attempts with exponential backoff
COMMON CAUSES: Registry catalog update delays, registry connectivity issues, or registry service problems
RECOVERY: 1. Manual verification: curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list 2. Check registry status: verify_microk8s_registry 3. Proceed with deployment if image exists 4. Or retry verification after waiting
```

**Recovery Steps**:
1. Verify the image exists in the registry:
   ```bash
   curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list
   ```
2. Check registry status:
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -n registry
   ```
3. If image exists, continue with deployment:
   ```bash
   # Skip image verification by temporarily modifying the script
   ```
4. Or wait and retry the deployment

### 2. KUBERNETES SECRETS VALIDATION FAILURE

**Error Message**:
```
ERROR TYPE: KUBERNETES SECRETS VALIDATION FAILURE
DIAGNOSTIC: Generated secrets YAML file is invalid or incompatible with Kubernetes API server
COMMON CAUSES: YAML syntax errors in generated secrets file, Invalid base64 encoding of secret values, Missing required fields or incorrect Kubernetes API version, Kubernetes cluster connectivity issues
RECOVERY: 1. Check the generated file for errors: cat k8s/secrets.yaml 2. Verify Kubernetes cluster connectivity: multipass exec ${VM_NAME:-my-ag-ui-app-k8s} -- microk8s kubectl cluster-info 3. Ensure you have necessary permissions: multipass exec ${VM_NAME:-my-ag-ui-app-k8s} -- microk8s kubectl auth can-i create secret 4. Fix any environment variable issues and regenerate the file
```

**Recovery Steps**:
1. Check the generated secrets file:
   ```bash
   cat k8s/secrets.yaml
   ```
2. Verify Kubernetes connectivity:
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl cluster-info
   ```
3. Check permissions:
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl auth can-i create secret
   ```
4. Fix environment variables and regenerate:
   ```bash
   # Check .env file and fix any issues
   ./deploy_scripts/setup-k8s-secrets.sh
   ```

### 3. ROLLBACK FAILED

**Error Message**:
```
ERROR: ❌ ROLLBACK FAILED: Could not apply backup deployment manifest
ERROR:    Manual intervention required to restore deployment state
```

**Recovery Steps**:
1. Check if backup file exists:
   ```bash
   ls -la k8s/deployment.yaml.backup
   ```
2. If backup exists, apply manually:
   ```bash
   multipass transfer k8s/deployment.yaml.backup my-ag-ui-app-k8s:/home/ubuntu/backup.yaml
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/backup.yaml
   ```
3. If no backup exists, recreate from running pods:
   ```bash
   # Get current deployment configuration
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app -o yaml > k8s/deployment.yaml.backup
   ```

## Interpreting Rollback Logs

### Log Structure

Rollback logs follow a structured format:

```
[2026-03-27 18:05:55] ERROR: 🔄 INITIATING ROLLBACK PROCEDURE
[2026-03-27 18:05:55] ERROR: Deployment failed - attempting to restore previous state
[2026-03-27 18:05:55] INFO: 🔄 Rolling back using backup deployment manifest...
[2026-03-27 18:05:55] INFO: 🔄 Transferring backup deployment manifest to VM...
[2026-03-27 18:05:55] ERROR: ❌ ROLLBACK FAILED: Could not apply backup deployment manifest
[2026-03-27 18:05:55] ERROR:    Manual intervention required to restore deployment state
```

### Key Log Indicators

- **🔄 INITIATING ROLLBACK**: Rollback process started
- **🔄 Rolling back**: Backup deployment being applied
- **🔄 Transferring**: Backup file being transferred to VM
- **✅ ROLLBACK SUCCESSFUL**: Rollback completed successfully
- **❌ ROLLBACK FAILED**: Rollback failed, manual intervention needed

### Log Locations

Rollback logs are written to:
- **Console**: Real-time output during deployment
- **Log Files**: `/tmp/deploy-*.log` (timestamped)
- **Structured Errors**: Detailed error information with recovery steps

## Best Practices

### Before Deployment

1. **Verify Prerequisites**
   - Ensure VM is running: `multipass list`
   - Check Kubernetes status: `multipass exec my-ag-ui-app-k8s -- microk8s status`
   - Verify registry access: `curl -s http://localhost:32000/v2/_catalog`

2. **Backup Current State**
   - Ensure `k8s/deployment.yaml.backup` exists
   - Test backup file validity

3. **Environment Preparation**
   - Verify `.env` file exists and is correct
   - Check all required environment variables are set

### During Deployment

1. **Monitor Progress**
   - Watch deployment output for errors
   - Check log files: `tail -f /tmp/deploy-*.log`

2. **Use VERBOSE Mode for Debugging**
   ```bash
   VERBOSE=true ./deploy-all.sh
   ```

### After Rollback

1. **Verify Service Recovery**
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app
   ```

2. **Check Application Health**
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe pod <pod-name>
   ```

3. **Review Rollback Logs**
   ```bash
   grep -A 10 -B 5 "ROLLBACK" /tmp/deploy-*.log
   ```

## Troubleshooting Rollback Issues

### Common Issues

1. **Backup File Missing**
   - **Cause**: `k8s/deployment.yaml.backup` doesn't exist
   - **Solution**: Create backup from current deployment

2. **VM Connectivity Issues**
   - **Cause**: Cannot connect to Multipass VM
   - **Solution**: Check VM status: `multipass list`

3. **Permission Issues**
   - **Cause**: Insufficient Kubernetes permissions
   - **Solution**: Check permissions: `multipass exec my-ag-ui-app-k8s -- microk8s kubectl auth can-i create deployment`

4. **Registry Issues**
   - **Cause**: Microk8s registry not accessible
   - **Solution**: Check registry: `curl -s http://localhost:32000/v2/_catalog`

### Debug Commands

Use these commands to debug rollback issues:

```bash
# Check VM status
multipass list

# Check Kubernetes cluster status
multipass exec my-ag-ui-app-k8s -- microk8s kubectl cluster-info

# Check deployment status
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app

# Check pod status
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods

# Check recent rollback logs
grep -A 10 -B 5 "ROLLBACK" /tmp/deploy-*.log | tail -30
```

## Contact and Support

If you encounter rollback issues that cannot be resolved with the procedures in this document:

1. Check the project README for additional resources
2. Review deployment logs for detailed error information
3. Create an issue in the project repository with:
   - Complete error messages
   - Relevant log excerpts
   - Steps you've already tried
   - Environment information (OS, Multipass version, etc.)