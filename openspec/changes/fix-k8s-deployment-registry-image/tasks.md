## 1. Analysis and Preparation

- [x] 1.1 Review current k8s/deployment.yaml to identify image reference
- [x] 1.2 Verify deployment script workflow to understand image build, tag, and push sequence
- [x] 1.3 Confirm microk8s registry is running and accessible at localhost:32000
- [x] 1.4 Document current deployment state and error patterns from deploy_log.md

## 2. Update Kubernetes Deployment Manifest

- [x] 2.1 Modify k8s/deployment.yaml to change image reference from `my-ag-ui-app:latest` to `localhost:32000/my-ag-ui-app:latest`
- [x] 2.2 Verify that all other deployment settings remain unchanged (replicas, resources, probes, environment variables)
- [x] 2.3 Ensure deployment manifest maintains compatibility with existing secrets and config maps
- [x] 2.4 Add comments to deployment.yaml explaining the local registry image reference
- [x] 2.5 Validate deployment.yaml syntax and structure

## 3. Registry Configuration Verification

- [x] 3.1 Verify microk8s registry is enabled and running
- [x] 3.2 Test registry accessibility at http://localhost:32000/v2/_catalog
- [x] 3.3 Confirm that my-ag-ui-app repository exists in registry catalog (catalog is empty - repository will be created during deployment testing)
- [x] 3.4 Verify registry pod status is Running
- [x] 3.5 Document registry configuration for future reference

## 4. Deployment Testing

- [x] 4.1 Run deployment script to build Docker image
- [x] 4.2 Verify image is tagged as localhost:32000/my-ag-ui-app:latest within VM
- [x] 4.3 Verify image is pushed to local microk8s registry
- [x] 4.4 Apply updated k8s/deployment.yaml to Kubernetes
- [x] 4.5 Trigger deployment restart to use new image reference
- [x] 4.6 Monitor pod creation and verify pods are pulling from localhost:32000/my-ag-ui-app:latest
- [x] 4.7 Wait for pods to reach Running state (no ImagePullBackOff errors)
- [x] 4.8 Verify pod logs show successful application startup

## 5. Health and Accessibility Verification

- [x] 5.1 Verify pod status is Running with 1/1 ready
- [x] 5.2 Confirm readiness probe passes
- [x] 5.3 Confirm liveness probe passes
- [x] 5.4 Test application accessibility via ingress endpoint
- [x] 5.5 Verify application responds to HTTP requests
- [x] 5.6 Confirm successful deployment end-to-end

## 6. Error Handling and Logging

- [x] 6.1 Add logging for deployment manifest application
- [x] 6.2 Add logging for registry accessibility checks
- [x] 6.3 Add error handling for registry not accessible scenarios
- [x] 6.4 Add error handling for image pull failures
- [x] 6.5 Ensure all error messages include recovery suggestions

## 7. Documentation Updates

- [x] 7.1 Update deployment documentation to reflect local registry configuration
- [x] 7.2 Document the localhost:32000 registry endpoint usage
- [x] 7.3 Update troubleshooting guides for registry-related issues
- [x] 7.4 Add notes about local-only deployment limitations
- [x] 7.5 Update README with registry configuration details

## 8. Integration and Validation

- [x] 8.1 Verify complete deployment flow works: build → tag → push → deploy → verify
- [x] 8.2 Test deployment rollback procedure (revert to old image reference if needed)
- [x] 8.3 Verify no external network access is required for deployment
- [x] 8.4 Confirm deployment works consistently across multiple runs
- [x] 8.5 Validate that all deployment script phases complete successfully

## 9. Code Quality and Standards

- [x] 9.1 Ensure all code changes follow project coding standards
- [x] 9.2 Add inline comments explaining registry configuration decisions
- [x] 9.3 Verify no hardcoded values that should be configurable
- [x] 9.4 Ensure error messages are clear and actionable
- [x] 9.5 Validate YAML formatting and indentation in deployment.yaml

## 10. Final Verification and Cleanup

- [ ] 10.1 Perform final end-to-end deployment test
- [ ] 10.2 Verify all pods are running and healthy
- [ ] 10.3 Confirm application is accessible and functional
- [ ] 10.4 Check for any remaining ImagePullBackOff errors
- [ ] 10.5 Document any manual intervention steps required
- [ ] 10.6 Commit changes with descriptive commit message referencing this change
