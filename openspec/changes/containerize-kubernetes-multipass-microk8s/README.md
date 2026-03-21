# my-ag-ui-app - Kubernetes Deployment

This project provides a containerized deployment of the my-ag-ui-app using Kubernetes, multipass, and microk8s.

## Prerequisites

Before deploying, ensure you have the following installed:

- **multipass**: VM management tool
  - Installation: https://multipass.run/install
  - Verify: `multipass version`

- **Docker**: Container platform
  - Installation: https://docs.docker.com/get-docker/
  - Verify: `docker --version`

## Deployment Instructions

### Automated Deployment

Run the deployment script to set up the entire infrastructure:

```bash
./deploy.sh
```

The deployment script will:
1. Create a multipass VM with 4 CPUs, 7.7GiB RAM, and 19.3GiB disk
2. Install microk8s in the VM
3. Enable required microk8s add-ons (dns, storage, ingress)
4. Build the Docker image
5. Deploy the application to Kubernetes
6. Set up ingress for external access
7. Verify all components are working

### Manual Deployment (Advanced)

If you prefer to deploy components manually:

1. **Create VM:**
    ```bash
    multipass launch -c 4 -m 7.7G -d 19.3G -n my-ag-ui-app-k8s
    ```

2. **Install microk8s:**
    ```bash
    multipass exec my-ag-ui-app-k8s -- sudo snap install microk8s --classic
    multipass exec my-ag-ui-app-k8s -- sudo microk8s status --wait
    ```

3. **Enable add-ons:**
    ```bash
    multipass exec my-ag-ui-app-k8s -- sudo microk8s enable dns storage ingress
    ```

4. **Build and deploy application:**
    ```bash
    # Build Docker image
    docker build -t my-ag-ui-app:latest .
    
    # Load image into microk8s
    docker save my-ag-ui-app:latest | multipass exec my-ag-ui-app-k8s -- docker load
    
    # Apply Kubernetes manifests
    multipass exec my-ag-ui-app-k8s -- bash -c "microk8s kubectl apply -f k8s/"
    ```

## Application Access Instructions

After successful deployment, the application will be accessible through the following endpoints:

### Local Access

- **HTTP:** http://localhost
- **HTTPS:** https://localhost (self-signed certificate)

You can also access using the IP address:

- **HTTP:** http://127.0.0.1
- **HTTPS:** https://127.0.0.1 (self-signed certificate)

### Browser Access

1. Open your web browser
2. Navigate to http://localhost or https://localhost
3. If using HTTPS, you'll need to accept the self-signed certificate warning
4. The application should load and be fully functional

### Command Line Access

To test access from the command line:

```bash
# HTTP test
curl http://localhost

# HTTPS test (ignore certificate warning)
curl -k https://localhost
```

### Access from the VM

If you need to access the application from within the VM:

```bash
multipass exec my-ag-ui-app-k8s -- curl http://localhost
multipass exec my-ag-ui-app-k8s -- curl -k https://localhost
```

## Ingress Configuration

The application is exposed through a Kubernetes ingress with the following configuration:

- **Ingress Name:** my-ag-ui-app-ingress
- **Service Name:** my-ag-ui-app-service
- **Internal Port:** 3000 (Next.js default)
- **External Ports:** 80 (HTTP), 443 (HTTPS)
- **Hosts:** localhost, 127.0.0.1
- **SSL/TLS:** Self-signed certificate for local development

## Troubleshooting

### Common Issues

1. **Application not accessible:**
   - Check if the deployment completed successfully
   - Verify the ingress is properly configured:
     ```bash
     multipass exec my-ag-ui-app-k8s -- microk8s kubectl get ingress
     ```
   - Check pod status:
     ```bash
     multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods
     ```
   - Verify service endpoints:
     ```bash
     multipass exec my-ag-ui-app-k8s -- microk8s kubectl get endpoints
     ```

2. **Deployment script failures:**
   - **VM creation fails:**
     - Verify multipass is installed: `multipass version`
     - Check available system resources: `free -h` and `df -h`
     - Ensure no existing VM with same name: `multipass list`
     - Increase VM resources if needed: `multipass delete my-ag-ui-app-k8s && multipass purge`

   - **Microk8s installation fails:**
     - Check microk8s status: `multipass exec my-ag-ui-app-k8s -- microk8s status`
     - Verify required add-ons are enabled:
       ```bash
multipass exec my-ag-ui-app-k8s -- microk8s status --wait-ready
        multipass exec my-ag-ui-app-k8s -- sudo microk8s enable dns storage ingress
       ```
     - Check microk8s logs: `multipass exec my-ag-ui-app-k8s -- sudo journalctl -u snap.microk8s.daemon-k8s-controller-manager`

   - **Container build fails:**
     - Verify Docker is installed: `docker --version`
     - Check Docker daemon is running: `docker info`
     - Ensure Dockerfile exists and is valid
     - Check for syntax errors in Dockerfile
     - Verify all required files are present in build context

3. **SSL certificate warnings:**
   - The deployment uses self-signed certificates for local development
   - This is normal for local testing
   - In production, use proper certificates (Let's Encrypt, etc.)
   - To bypass certificate warning in browser, click "Advanced" and "Proceed to localhost"

4. **Connection timeouts:**
   - Ensure the deployment completed successfully
- Check if the application pods are running:
      ```bash
      multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -w
      ```
    - Verify service endpoints:
      ```bash
      multipass exec my-ag-ui-app-k8s -- microk8s kubectl get endpoints
      ```
    - Check ingress controller status:
      ```bash
      multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -n ingress
      ```

5. **Pod stuck in pending/ContainerCreating state:**
- Check for resource constraints:
      ```bash
      multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe pod <pod-name>
      ```
    - Verify sufficient resources in VM: `multipass exec my-ag-ui-app-k8s -- free -h`
   - Check if image pull is failing:
     ```bash
     multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe pod <pod-name> | grep -i image
     ```

6. **Network connectivity issues:**
   - Verify VM networking: `multipass exec my-ag-ui-app-k8s -- ping 8.8.8.8`
   - Check DNS resolution: `multipass exec my-ag-ui-app-k8s -- nslookup google.com`
   - Verify ingress controller can route traffic:
     ```bash
     multipass exec my-ag-ui-app-k8s -- microk8s kubectl get ingress
     multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe ingress <ingress-name>
     ```

### Debugging Steps

#### 1. Check Deployment Logs
```bash
# View deployment script logs
tail -f deployment.log

# View application logs
POD_NAME=$(multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].metadata.name}')
multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs $POD_NAME
multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs -f $POD_NAME

# View previous logs if pod crashed
multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs $POD_NAME --previous
```

#### 2. Verify Component Status
```bash
# Check VM status
multipass list

# Check microk8s status
multipass exec my-ag-ui-app-k8s -- microk8s status

# Check all Kubernetes resources
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get all

# Check ingress controller
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -n ingress
```

#### 3. Network and Connectivity Tests
```bash
# Test application access from VM
multipass exec my-ag-ui-app-k8s -- curl http://localhost
multipass exec my-ag-ui-app-k8s -- curl -k https://localhost

# Test service connectivity
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get service
multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe service <service-name>
```

#### 4. Resource Usage
```bash
# Check VM resources
multipass exec my-ag-ui-app-k8s -- free -h
multipass exec my-ag-ui-app-k8s -- df -h
multipass exec my-ag-ui-app-k8s -- top

# Check Kubernetes resource usage
multipass exec my-ag-ui-app-k8s -- microk8s kubectl top pods
multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe nodes
```

### Ralph-loop Execution Issues

#### 1. Script Timeout
- Check deployment logs: `cat deployment.log`
- Verify script execution time: `time ./deploy.sh`
- Increase timeout values in script if needed
- Break deployment into smaller phases if timeout persists

#### 2. Missing Dependencies
- Verify multipass: `multipass version`
- Verify Docker: `docker --version`
- Check script permissions: `ls -la deploy.sh`
- Ensure script is executable: `chmod +x deploy.sh`

#### 3. Non-zero Exit Codes
- Check last command exit code: `echo $?`
- Review deployment logs for errors: `cat deployment.log | grep ERROR`
- Verify script completion status in logs

### Common Error Messages and Solutions

#### Error: "multipass: command not found"
- **Cause**: Multipass is not installed
- **Solution**: Install multipass from https://multipass.run/install

#### Error: "Error: instance already exists"
- **Cause**: VM with same name already exists
- **Solution**: Delete existing VM: `multipass delete my-ag-ui-app-k8s && multipass purge`

#### Error: "Insufficient resources"
- **Cause**: System lacks required resources
- **Solution**: Free up system resources or reduce VM specifications

#### Error: "Failed to pull image"
- **Cause**: Image not found or network issues
- **Solution**: Check image name, verify network connectivity, build image locally

#### Error: "pods are pending"
- **Cause**: Insufficient resources in cluster
- **Solution**: Scale up VM or reduce resource requests in deployment

#### Error: "path does not exist" for YAML files
- **Cause**: YAML files not properly copied to VM or generated in wrong location
- **Solution**: The deployment script now handles file copying and generation automatically using multipass transfer
- **Prevention**: Ensure k8s/ directory exists with all required YAML files before running deployment
- **File Copy Process**: The script automatically copies YAML files from the host k8s/ directory to the VM's /home/ubuntu/k8s/ directory before running kubectl commands
- **Verification**: Check files are properly copied to VM with `multipass exec my-ag-ui-app-k8s -- ls -la /home/ubuntu/k8s/`

### Performance Issues

#### 1. Slow Deployment
- Check system resources: `free -h`, `df -h`
- Monitor network speed: `multipass exec my-ag-ui-app-k8s -- speedtest-cli` (if installed)
- Optimize Docker build with layer caching
- Reduce VM resources if over-provisioned

#### 2. High CPU/Memory Usage
- Identify resource-hungry pods:
  ```bash
  multipass exec my-ag-ui-app-k8s -- microk8s kubectl top pods
  ```
- Check application logs for memory leaks
- Adjust resource limits in deployment manifest
- Consider scaling the deployment

### Environment Variables and Configuration

#### 1. Missing Environment Variables
- Check required environment variables in application
- Verify Kubernetes secrets:
  ```bash
  multipass exec my-ag-ui-app-k8s -- microk8s kubectl get secrets
  multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe secret <secret-name>
  ```
- Update secrets if needed

#### 2. Configuration Issues
- Verify Kubernetes manifests are correct
- Check deployment configuration:
  ```bash
  multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe deployment <deployment-name>
  ```
- Compare with expected configuration in design documentation

### Cleanup and Reset

#### 1. Complete Reset
```bash
# Run cleanup script
./cleanup.sh

# Manual cleanup if script fails
multipass exec my-ag-ui-app-k8s -- microk8s kubectl delete -f k8s/
multipass delete my-ag-ui-app-k8s
multipass purge
```

#### 2. Selective Cleanup
```bash
# Delete only Kubernetes resources
multipass exec my-ag-ui-app-k8s -- microk8s kubectl delete deployment,service,ingress --all

# Reset microk8s (last resort)
multipass exec my-ag-ui-app-k8s -- sudo microk8s reset
```

### Getting Help

1. **Check Logs First**: Always review deployment.log and application logs
2. **Verify Prerequisites**: Ensure all required tools are installed and working
3. **Consult Documentation**: Review this README and hidden/KUBERNETES-EXPLANATION.md
4. **Test Components Individually**: Test VM, microk8s, and deployment separately
5. **Check Online Resources**: Consult multipass, microk8s, and Kubernetes documentation

### Cleanup

To remove all deployed resources:

```bash
./cleanup.sh
```

Or manually:
```bash
# Delete Kubernetes resources
multipass exec my-ag-ui-app-k8s -- microk8s kubectl delete -f k8s/

# Delete VM
multipass delete my-ag-ui-app-k8s
multipass purge
```

## Monitoring

### Application Logs

To view application logs:

```bash
# Get pod name
POD_NAME=$(multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].metadata.name}')

# View logs
multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs $POD_NAME

# Follow logs
multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs -f $POD_NAME
```

### Deployment Status

Check the status of all components:

```bash
# Check VM status
multipass list

# Check microk8s status
multipass exec my-ag-ui-app-k8s -- microk8s status

# Check Kubernetes resources
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get all
```

## Scaling

To scale the application:

```bash
# Scale to 3 replicas
multipass exec my-ag-ui-app-k8s -- microk8s kubectl scale deployment my-ag-ui-app-deployment --replicas=3

# Check replica status
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app-deployment
```

## Development Notes

- This deployment is designed for development and testing
- For production deployment, consider:
  - Proper SSL certificates (Let's Encrypt)
  - Resource limits and monitoring
  - Persistent storage for data
  - High availability setup
  - Security hardening

For detailed technical implementation, see `hidden/KUBERNETES-EXPLANATION.md`.