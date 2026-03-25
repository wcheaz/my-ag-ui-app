# Configurable Values Analysis - Task 9.3
# =======================================

This document analyzes the hardcoded values in the Kubernetes deployment configuration and identifies which values are appropriately hardcoded vs. which should be made configurable.

## Summary of Changes Made
- Fixed registry URL inconsistency in deployment.yaml comments (localhost:5000 → localhost:32000)
- Added infrastructure configuration values to ConfigMap (secrets.yaml)
- Added explanatory comments to all configuration files
- Documented the rationale for hardcoded vs. configurable values

## Analysis by File

### deployment.yaml
**Values that are appropriately hardcoded:**
- `containerPort: 3000` - Application port is defined by the application itself
- `imagePullPolicy: IfNotPresent` - Optimal for local development
- Probe timing values - Configured for optimal startup and health check behavior
- Resource limits - Set for local development environment constraints

**Values made configurable:**
- Infrastructure values moved to ConfigMap:
  - `app-port: "3000"`
  - `cpu-request: "100m"`, `cpu-limit: "500m"`
  - `memory-request: "256Mi"`, `memory-limit: "512Mi"`
  - Probe timing parameters (liveness and readiness)
  - Note: These values are documented in ConfigMap but remain hardcoded in deployment due to Kubernetes limitations

**Issues Fixed:**
- Fixed registry URL inconsistency in comments (localhost:5000 → localhost:32000)
- Updated documentation to reflect microk8s instead of minikube

### service.yaml
**Values that are appropriately hardcoded:**
- `port: 80` - Standard HTTP port for ClusterIP service
- `targetPort: 3000` - Must match application container port
- `type: ClusterIP` - Appropriate for internal service access

**Rationale:** Service configuration is typically static for cluster-internal services but could be made configurable if external exposure requirements change.

### ingress.yaml
**Values that are appropriately hardcoded:**
- `host: my-ag-ui-app.local` - Local development hostname
- `path: /` - Root path for application access
- `ingressClassName: nginx` - Using NGINX ingress controller
- `rewrite-target: /` - Standard path rewriting

**Rationale:** Ingress configuration is typically environment-specific and would be configured differently for production vs. development environments.

### secrets.yaml (ConfigMap)
**Values made configurable:**
- **Application settings:** `llm-max-tokens`, `llm-context-window`
- **Infrastructure settings:** 
  - Port mappings: `app-port`, `service-port`
  - Resource limits: `cpu-request`, `cpu-limit`, `memory-request`, `memory-limit`
  - Probe timing: liveness and readiness probe parameters
  - Ingress configuration: `ingress-host`, `ingress-path`, etc.

## Recommendations for Future Configuration

### Values that could be made configurable for different environments:
1. **Resource limits and requests** - Different for development vs. production
2. **Probe timing values** - May need adjustment for different application startup times
3. **Ingress host and path** - Different for different deployment environments
4. **Service type** - ClusterIP for development, LoadBalancer for production

### Values that should remain hardcoded:
1. **Application port** - Defined by the application code itself
2. **Health check paths** - Defined by the application code
3. **Secret references** - These are already properly externalized

## Implementation Notes

- Kubernetes has limitations on which values can be referenced from ConfigMaps in deployment manifests
- Container ports, resource limits, and probe timings cannot directly reference ConfigMap values
- For truly configurable infrastructure, consider using Helm charts or Kustomize overlays
- The current approach documents configuration intent while maintaining Kubernetes compatibility