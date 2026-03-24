## 1. Analysis and Preparation

- [x] 1.1 Review current k8s/deployment.yaml to identify image reference
- [x] 1.2 Verify deployment script workflow to understand image build, tag, and push sequence
- [x] 1.3 Confirm microk8s registry is running and accessible at localhost:32000
- [x] 1.4 Document current deployment state and error patterns from deploy_log.md

## 2. Update Kubernetes Deployment Manifest

- [x] 2.1 Modify k8s/deployment.yaml to change image reference from `my-ag-ui-app:latest` to `localhost:32000/my-ag-ui-app:latest`
- [ ] 2.2 Verify that all other deployment settings remain unchanged (replicas, resources, probes, environment variables)
- [ ] 2.3 Ensure deployment manifest maintains compatibility with existing secrets and config maps
- [ ] 2.4 Add comments to deployment.yaml explaining the local registry image reference
- [ ] 2.5 Validate deployment.yaml syntax and structure

## 3. Registry Configuration Verification

- [ ] 3.1 Verify microk8s registry is enabled and running
- [ ] 3.2 Test registry accessibility at http://localhost:32000/v2/_catalog
- [ ] 3.3 Confirm that my-ag-ui-app repository exists in registry catalog
- [ ] 3.4 Verify registry pod status is Running
- [ ] 3.5 Document registry configuration for future reference

## 4. Deployment Testing

- [ ] 4.1 Run deployment script to build Docker image
- [ ] 4.2 Verify image is tagged as localhost:32000/my-ag-ui-app:latest within VM
- [ ] 4.3 Verify image is pushed to local microk8s registry
- [ ] 4.4 Apply updated k8s/deployment.yaml to Kubernetes
- [ ] 4.5 Trigger deployment restart to use new image reference
- [ ] 4.6 Monitor pod creation and verify pods are pulling from localhost:32000/my-ag-ui-app:latest
- [ ] 4.7 Wait for pods to reach Running state (no ImagePullBackOff errors)
- [ ] 4.8 Verify pod logs show successful application startup

## 5. Health and Accessibility Verification

- [ ] 5.1 Verify pod status is Running with 1/1 ready
- [ ] 5.2 Confirm readiness probe passes
- [ ] 5.3 Confirm liveness probe passes
- [ ] 5.4 Test application accessibility via ingress endpoint
- [ ] 5.5 Verify application responds to HTTP requests
- [ ] 5.6 Confirm successful deployment end-to-end

## 6. Error Handling and Logging

- [ ] 6.1 Add logging for deployment manifest application
- [ ] 6.2 Add logging for registry accessibility checks
- [ ] 6.3 Add error handling for registry not accessible scenarios
- [ ] 6.4 Add error handling for image pull failures
- [ ] 6.5 Ensure all error messages include recovery suggestions

## 7. Documentation Updates

- [ ] 7.1 Update deployment documentation to reflect local registry configuration
- [ ] 7.2 Document the localhost:32000 registry endpoint usage
- [ ] 7.3 Update troubleshooting guides for registry-related issues
- [ ] 7.4 Add notes about local-only deployment limitations
- [ ] 7.5 Update README with registry configuration details

## 8. Integration and Validation

- [ ] 8.1 Verify complete deployment flow works: build → tag → push → deploy → verify
- [ ] 8.2 Test deployment rollback procedure (revert to old image reference if needed)
- [ ] 8.3 Verify no external network access is required for deployment
- [ ] 8.4 Confirm deployment works consistently across multiple runs
- [ ] 8.5 Validate that all deployment script phases complete successfully

## 9. Code Quality and Standards

- [ ] 9.1 Ensure all code changes follow project coding standards
- [ ] 9.2 Add inline comments explaining registry configuration decisions
- [ ] 9.3 Verify no hardcoded values that should be configurable
- [ ] 9.4 Ensure error messages are clear and actionable
- [ ] 9.5 Validate YAML formatting and indentation in deployment.yaml

## 10. Final Verification and Cleanup

- [ ] 10.1 Perform final end-to-end deployment test
- [ ] 10.2 Verify all pods are running and healthy
- [ ] 10.3 Confirm application is accessible and functional
- [ ] 10.4 Check for any remaining ImagePullBackOff errors
- [ ] 10.5 Document any manual intervention steps required
- [ ] 10.6 Commit changes with descriptive commit message referencing this change
