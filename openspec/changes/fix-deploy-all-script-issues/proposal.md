## Why

The deploy-all.sh script has critical failures that prevent successful Kubernetes deployment: secrets setup fails but continues execution, pods fail health checks with HTTP 404 errors, containers terminate immediately instead of staying running, and image verification fails. These issues cause deployments to fail and require manual intervention, blocking reliable automated deployments.

## What Changes

- **BREAKING**: Fix Kubernetes secrets setup to halt deployment on validation failure instead of continuing with invalid configuration
- Add proper error handling and exit codes for all deploy script steps
- Fix container health check endpoint configuration to ensure /api/health is properly accessible
- Add container startup verification to ensure application runs continuously instead of completing
- Improve image verification logic to handle registry catalog delays and provide accurate status
- Add comprehensive logging and error reporting for debugging deployment failures
- Implement proper rollback procedures when deployment steps fail

## Capabilities

### New Capabilities
- `deploy-error-handling`: Robust error handling and validation for all deployment steps with proper exit codes and failure recovery
- `container-health-checking`: Proper configuration of liveness and readiness probes with correct endpoint paths and response handling
- `deployment-verification`: Multi-step verification including image registry validation, secrets validation, and pod startup verification
- `deploy-logging`: Comprehensive logging infrastructure for deployment pipeline with structured error messages and debugging information

### Modified Capabilities
- None (this is a new deployment capability fixing fundamental issues)

## Impact

- **Affected Scripts**: deploy-all.sh, deploy_scripts/setup-k8s-secrets.sh, deploy_scripts/deploy-to-k8s.sh, deploy_scripts/push-docker-image.sh
- **Affected Configuration**: k8s/deployment.yaml (health check configuration), k8s/setup-secrets.sh (validation logic)
- **Dependencies**: No new dependencies required
- **Systems**: Kubernetes deployment pipeline, Microk8s registry, Docker image build and push workflow
- **Development Workflow**: Will enable reliable automated deployments through ralph-loops with proper error handling and rollback capabilities
