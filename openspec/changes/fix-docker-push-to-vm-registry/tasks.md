## 1. Analysis and Preparation

- [x] 1.1 Review current deployment script to locate image tag and push operations
- [x] 1.2 Identify where Docker push command executes (currently on host)
- [ ] 1.3 Verify microk8s registry is enabled and accessible in VM
- [ ] 1.4 Document current deployment flow for tag and push operations

## 2. Modify Image Tag Operation

- [ ] 2.1 Modify image tag command to execute via `multipass exec` within VM
- [ ] 2.2 Update tag command to reference image built on host (already available in VM's Docker daemon)
- [ ] 2.3 Add validation to ensure source image exists in VM before tagging
- [ ] 2.4 Add error handling for image not found in VM
- [ ] 2.5 Add logging for tagging operations and success/failure status

## 3. Modify Image Push Operation

- [ ] 3.1 Modify image push command to execute via `multipass exec` within VM
- [ ] 3.2 Update push command to use `localhost:32000` (VM's registry endpoint)
- [ ] 3.3 Add validation to ensure registry is accessible before push
- [ ] 3.4 Implement retry logic with exponential backoff for transient network issues
- [ ] 3.5 Add error handling for registry not accessible in VM
- [ ] 3.6 Add error handling for push failures with clear recovery steps
- [ ] 3.7 Add logging for push operations, retry attempts, and success/failure status

## 4. Registry Accessibility Verification

- [ ] 4.1 Add function to verify microk8s registry is accessible at localhost:32000 within VM
- [ ] 4.2 Add registry accessibility check before image push operation
- [ ] 4.3 Add error handling for registry not enabled or not accessible
- [ ] 4.4 Add logging for registry status and accessibility checks

## 5. Error Handling and Logging

- [ ] 5.1 Update error messages for image tag operations to include VM context
- [ ] 5.2 Update error messages for image push operations to include VM context
- [ ] 5.3 Include recovery suggestions in all error messages
- [ ] 5.4 Ensure logging includes command outputs and error details for tag and push operations

## 6. Testing and Validation

- [ ] 6.1 Test image tagging within VM
- [ ] 6.2 Test image push to microk8s registry from VM
- [ ] 6.3 Test registry accessibility verification
- [ ] 6.4 Test error handling when image is not found in VM
- [ ] 6.5 Test error handling when registry is not accessible
- [ ] 6.6 Test retry logic for transient push failures
- [ ] 6.7 Verify pods reach Running state after successful registry push
- [ ] 6.8 Verify application is accessible via ingress after deployment
- [ ] 6.9 Test complete deployment flow end-to-end

## 7. Documentation and Cleanup

- [ ] 7.1 Update deployment script comments to explain VM-based tag and push operations
- [ ] 7.2 Document troubleshooting steps for registry push issues
- [ ] 7.3 Update project documentation with registry push workflow changes
- [ ] 7.4 Verify all code follows project coding standards
- [ ] 7.5 Commit changes with descriptive commit message referencing this change
