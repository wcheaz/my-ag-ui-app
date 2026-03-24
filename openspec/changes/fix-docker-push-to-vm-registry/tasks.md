## 1. Analysis and Preparation

- [x] 1.1 Review current deployment script to locate image tag and push operations
- [x] 1.2 Identify where Docker push command executes (currently on host)
- [x] 1.3 Verify microk8s registry is enabled and accessible in VM
- [x] 1.4 Document current deployment flow for tag and push operations

## 2. Modify Image Tag Operation

- [x] 2.1 Modify image tag command to execute via `multipass exec` within VM
- [x] 2.2 Update tag command to reference image built on host (already available in VM's Docker daemon)
- [x] 2.3 Add validation to ensure source image exists in VM before tagging
- [x] 2.4 Add error handling for image not found in VM
- [x] 2.5 Add logging for tagging operations and success/failure status

## 3. Modify Image Push Operation

- [x] 3.1 Modify image push command to execute via `multipass exec` within VM
- [x] 3.2 Update push command to use `localhost:32000` (VM's registry endpoint)
- [x] 3.3 Add validation to ensure registry is accessible before push
- [x] 3.4 Implement retry logic with exponential backoff for transient network issues
- [x] 3.5 Add error handling for registry not accessible in VM
- [x] 3.6 Add error handling for push failures with clear recovery steps
- [x] 3.7 Add logging for push operations, retry attempts, and success/failure status

## 4. Registry Accessibility Verification

- [x] 4.1 Add function to verify microk8s registry is accessible at localhost:32000 within VM
- [x] 4.2 Add registry accessibility check before image push operation
- [x] 4.3 Add error handling for registry not enabled or not accessible
- [x] 4.4 Add logging for registry status and accessibility checks

## 5. Error Handling and Logging

- [x] 5.1 Update error messages for image tag operations to include VM context
- [x] 5.2 Update error messages for image push operations to include VM context
- [x] 5.3 Include recovery suggestions in all error messages
- [x] 5.4 Ensure logging includes command outputs and error details for tag and push operations

## 6. Testing and Validation

- [x] 6.1 Test image tagging within VM
- [x] 6.2 Test image push to microk8s registry from VM
- [x] 6.3 Test registry accessibility verification
- [x] 6.4 Test error handling when image is not found in VM
- [x] 6.5 Test error handling when registry is not accessible
- [x] 6.6 Test retry logic for transient push failures
- [x] 6.7 Verify pods reach Running state after successful registry push
- [x] 6.8 Verify application is accessible via ingress after deployment
- [x] 6.9 Test complete deployment flow end-to-end

## 7. Documentation and Cleanup

- [x] 7.1 Update deployment script comments to explain VM-based tag and push operations
- [x] 7.2 Document troubleshooting steps for registry push issues
- [x] 7.3 Update project documentation with registry push workflow changes
- [x] 7.4 Verify all code follows project coding standards
- [ ] 7.5 Commit changes with descriptive commit message referencing this change
