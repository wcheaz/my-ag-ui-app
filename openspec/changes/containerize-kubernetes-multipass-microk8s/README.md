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
   multipass launch -c 4 -m 7.7G -d 19.3G -n my-ag-ui-app-vm
   ```

2. **Install microk8s:**
   ```bash
   multipass exec my-ag-ui-app-vm -- sudo snap install microk8s --classic
   multipass exec my-ag-ui-app-vm -- sudo microk8s status --wait
   ```

3. **Enable add-ons:**
   ```bash
   multipass exec my-ag-ui-app-vm -- sudo microk8s enable dns storage ingress
   ```

4. **Build and deploy application:**
   ```bash
   # Build Docker image
   docker build -t my-ag-ui-app:latest .
   
   # Load image into microk8s
   docker save my-ag-ui-app:latest | multipass exec my-ag-ui-app-vm -- docker load
   
   # Apply Kubernetes manifests
   multipass exec my-ag-ui-app-vm -- bash -c "microk8s kubectl apply -f k8s/"
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
multipass exec my-ag-ui-app-vm -- curl http://localhost
multipass exec my-ag-ui-app-vm -- curl -k https://localhost
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
     multipass exec my-ag-ui-app-vm -- microk8s kubectl get ingress
     ```
   - Check pod status:
     ```bash
     multipass exec my-ag-ui-app-vm -- microk8s kubectl get pods
     ```

2. **SSL certificate warnings:**
   - The deployment uses self-signed certificates for local development
   - This is normal for local testing
   - In production, use proper certificates (Let's Encrypt, etc.)

3. **Connection timeouts:**
   - Ensure the deployment completed successfully
   - Check if the application pods are running:
     ```bash
     multipass exec my-ag-ui-app-vm -- microk8s kubectl get pods -w
     ```
   - Verify service endpoints:
     ```bash
     multipass exec my-ag-ui-app-vm -- microk8s kubectl get endpoints
     ```

### Cleanup

To remove all deployed resources:

```bash
./cleanup.sh
```

Or manually:
```bash
# Delete Kubernetes resources
multipass exec my-ag-ui-app-vm -- microk8s kubectl delete -f k8s/

# Delete VM
multipass delete my-ag-ui-app-vm
multipass purge
```

## Monitoring

### Application Logs

To view application logs:

```bash
# Get pod name
POD_NAME=$(multipass exec my-ag-ui-app-vm -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].metadata.name}')

# View logs
multipass exec my-ag-ui-app-vm -- microk8s kubectl logs $POD_NAME

# Follow logs
multipass exec my-ag-ui-app-vm -- microk8s kubectl logs -f $POD_NAME
```

### Deployment Status

Check the status of all components:

```bash
# Check VM status
multipass list

# Check microk8s status
multipass exec my-ag-ui-app-vm -- microk8s status

# Check Kubernetes resources
multipass exec my-ag-ui-app-vm -- microk8s kubectl get all
```

## Scaling

To scale the application:

```bash
# Scale to 3 replicas
multipass exec my-ag-ui-app-vm -- microk8s kubectl scale deployment my-ag-ui-app-deployment --replicas=3

# Check replica status
multipass exec my-ag-ui-app-vm -- microk8s kubectl get deployment my-ag-ui-app-deployment
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