## 1. Containerization Setup

- [x] 1.1 Review and optimize existing Dockerfile for multi-stage builds
- [x] 1.2 Create build stage with all build dependencies (Node.js, npm)
- [x] 1.3 Create runtime stage with lightweight Alpine base image
- [x] 1.4 Configure Dockerfile to expose port 3000
- [x] 1.5 Add health check endpoint configuration to Dockerfile
- [x] 1.6 Configure environment variable support in Dockerfile
- [x] 1.7 Test Docker build locally to ensure it works correctly
- [x] 1.8 Verify container runs successfully with `docker run`
- [x] 1.9 Verify container responds to HTTP requests on port 3000

## 2. Kubernetes Manifests

- [x] 2.1 Create k8s/deployment.yaml with deployment configuration
- [x] 2.2 Configure deployment with appropriate replica count (start with 1)
- [x] 2.3 Add resource requests and limits to deployment (CPU and memory)
- [x] 2.4 Configure liveness probe in deployment manifest
- [x] 2.5 Configure readiness probe in deployment manifest
- [x] 2.6 Create k8s/service.yaml with service configuration
- [x] 2.7 Configure service to listen on port 80 and forward to port 3000
- [x] 2.8 Set up service selector to match deployment pods
- [x] 2.9 Create k8s/ingress.yaml with ingress configuration
- [x] 2.10 Configure ingress to route traffic to the service
- [x] 2.11 Set up ingress class for microk8s ingress controller
- [x] 2.12 Add host-based routing configuration (if needed)
- [x] 2.13 Test Kubernetes manifests locally with `microk8s kubectl apply --dry-run`

## 3. VM Provisioning

- [x] 3.1 Create VM provisioning script section in deployment script
- [x] 3.2 Add multipass installation check to deployment script
- [x] 3.3 Configure VM creation with 4 CPUs, 7.7GiB RAM, 19.3GiB disk
- [x] 3.4 Add VM readiness verification to deployment script
- [x] 3.5 Configure VM networking verification
- [x] 3.6 Add VM status monitoring during deployment
- [x] 3.7 Implement VM cleanup capability in cleanup script
- [x] 3.8 Add VM error handling and recovery suggestions
- [x] 3.9 Test VM creation and deletion

## 4. Microk8s Installation

- [x] 4.1 Create microk8s installation section in deployment script
- [x] 4.2 Install microk8s in the VM
- [x] 4.3 Enable dns add-on in microk8s
- [x] 4.4 Enable storage add-on in microk8s
- [x] 4.5 Enable ingress add-on in microk8s
- [x] 4.6 Wait for microk8s to be ready
- [x] 4.7 Verify microk8s status after installation
- [x] 4.8 Add microk8s error handling to deployment script
- [x] 4.9 Test microk8s installation and add-on enablement

## 5. Container Image Deployment

- [x] 5.1 Build Docker image in deployment script
- [x] 5.2 Tag Docker image appropriately
- [x] 5.3 Load Docker image into microk8s (or configure image pull)
- [x] 5.4 Create Kubernetes secrets for sensitive environment variables
- [x] 5.5 Apply deployment manifest to microk8s cluster
- [x] 5.6 Apply service manifest to microk8s cluster
- [x] 5.7 Apply ingress manifest to microk8s cluster
- [x] 5.8 Wait for pods to be ready
- [x] 5.9 Verify deployment status
- [x] 5.10 Verify application is accessible via ingress

## 6. Ingress Configuration

- [x] 6.1 Verify ingress controller is running
- [x] 6.2 Get ingress endpoint URL/IP
- [x] 6.3 Test application access via ingress
- [x] 6.4 Configure SSL/TLS certificates (if needed)
- [x] 6.5 Test HTTPS access (if SSL is configured)
- [x] 6.6 Verify ingress logs are working
- [x] 6.7 Test ingress error handling
- [x] 6.8 Verify load balancing across pods (if replicas > 1)

## 7. Deployment Automation Script

- [x] 7.1 Create main deployment script (deploy.sh)
- [x] 7.2 Add pre-deployment checks (multipass, Docker, resources)
- [x] 7.3 Add VM provisioning section
- [x] 7.4 Add microk8s installation section
- [x] 7.5 Add container build section
- [x] 7.6 Add Kubernetes deployment section
- [x] 7.7 Add verification steps after each section
- [x] 7.8 Add progress feedback messages throughout script
- [x] 7.9 Add error handling for each step
- [x] 7.10 Add timeout configuration for each step
- [x] 7.11 Add logging to file throughout script
- [x] 7.12 Make script executable
- [x] 7.13 Test full deployment script execution
- [x] 7.14 Verify script is idempotent (can run multiple times)
- [x] 7.15 Verify script works with ralph-loop (no human interaction)
- [x] 7.16 Verify appropriate exit codes (0 for success, non-zero for failure)

## 8. Cleanup Script

- [x] 8.1 Create cleanup script (cleanup.sh)
- [x] 8.2 Add Kubernetes resource cleanup (delete ingress, service, deployment)
- [x] 8.3 Add microk8s cleanup (optional)
- [x] 8.4 Add VM deletion (multipass delete and purge)
- [x] 8.5 Add cleanup confirmation prompt (or flag for non-interactive)
- [x] 8.6 Add error handling for cleanup failures
- [x] 8.7 Make cleanup script executable
- [x] 8.8 Test cleanup script

## 9. Documentation

- [x] 9.1 Update README.md with deployment prerequisites (multipass, Docker)
- [x] 9.2 Add deployment instructions to README.md
- [x] 9.3 Add application access instructions to README.md (URL, hostname)
- [x] 9.4 Add troubleshooting section to README.md
- [x] 9.5 Create hidden/KUBERNETES-EXPLANATION.md
- [x] 9.6 Document VM configuration in KUBERNETES-EXPLANATION.md
- [x] 9.7 Document microk8s configuration in KUBERNETES-EXPLANATION.md
- [x] 9.8 Document Kubernetes manifests in KUBERNETES-EXPLANATION.md
- [x] 9.9 Document ingress configuration in KUBERNETES-EXPLANATION.md
- [x] 9.10 Document deployment script usage in KUBERNETES-EXPLANATION.md
- [x] 9.11 Document environment variables in KUBERNETES-EXPLANATION.md
- [x] 9.12 Document resource scaling recommendations in KUBERNETES-EXPLANATION.md
- [x] 9.13 Document rollback procedures in KUBERNETES-EXPLANATION.md
- [x] 9.14 Document common issues and solutions in KUBERNETES-EXPLANATION.md

## 10. Testing and Validation

- [x] 10.1 Test container build process
- [x] 10.2 Test container execution locally
- [x] 10.3 Test VM creation and deletion
- [x] 10.4 Test microk8s installation
- [x] 10.5 Test Kubernetes deployment
- [x] 10.6 Test service connectivity
- [x] 10.7 Test ingress routing
- [x] 10.8 Test application access via ingress
- [x] 10.9 Test health checks (liveness and readiness)
- [x] 10.10 Test resource limits
- [x] 10.11 Test deployment script end-to-end
- [x] 10.12 Test cleanup script
- [x] 10.13 Test error handling (simulate failures)
- [x] 10.14 Test script idempotency
- [x] 10.15 Test with ralph-loop automation
- [x] 10.16 Verify all requirements from specs are met

## 11. Configuration and Environment Variables

- [x] 11.1 Identify required environment variables for the application
- [x] 11.2 Create .env.example file with required variables
- [x] 11.3 Configure environment variable injection in deployment manifest
- [x] 11.4 Add environment variable validation to deployment script
- [x] 11.5 Document environment variables in KUBERNETES-EXPLANATION.md
- [x] 11.6 Test environment variable configuration

## 12. Security and Best Practices

- [x] 12.1 Ensure Dockerfile uses non-root user if possible
- [x] 12.2 Ensure no sensitive information is hardcoded in manifests
- [x] 12.3 Use secrets for sensitive data (API keys, passwords)
- [x] 12.4 Configure network policies if needed
- [x] 12.5 Review and apply security best practices
- [x] 12.6 Document security considerations in KUBERNETES-EXPLANATION.md

## 13. Final Review and Polish

- [x] 13.1 Review all code for consistency and best practices
- [x] 13.2 Review all documentation for clarity and completeness
- [x] 13.3 Test complete deployment flow one final time
- [x] 13.4 Verify all artifacts are created and correct
- [x] 13.5 Ensure all scripts are executable
- [x] 13.6 Verify all file permissions are correct
- [x] 13.7 Create summary of what was implemented
- [x] 13.8 Prepare for archiving the change

## 14. Cleanup and Organization

- [x] 14.1 Verify deploy.sh is the working deployment script (2,376 lines, per IMPLEMENTATION_SUMMARY.md)
- [x] 14.2 Remove unnecessary deployment scripts (deploy_app.sh, deploy_final.sh, deploy_fixed.sh, deploy_test.sh, deploy_working.sh)
- [x] 14.3 Keep only working deployment script (deploy.sh)
- [x] 14.4 Create test/kubernetes/ directory if it doesn't exist
- [x] 14.5 Move test scripts to test/kubernetes/ directory (test_script_idempotency.sh, test_script.sh, test-container-build.sh, test-docker-build.sh)
- [x] 14.6 Clean up log files (deployment_test.log, deployment.log, test_deployment.log, vm-test.log, service-connectivity-test.log)
- [x] 14.7 Remove SCRIPT_IDEMPOTENCY_TEST_RESULTS.md if no longer needed
- [x] 14.8 Remove performance_analysis.md if no longer needed
- [x] 14.9 Remove env_loading_performance_results.txt if no longer needed
- [x] 14.10 Remove tls.crt if no longer needed
- [ ] 14.11 Verify project root directory is clean and organized
- [ ] 14.12 Update .gitignore if needed to exclude test/kubernetes/ directory
- [ ] 14.13 Document cleanup changes in CHANGELOG.md
