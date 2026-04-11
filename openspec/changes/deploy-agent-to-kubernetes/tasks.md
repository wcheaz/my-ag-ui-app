# File Placement Rules (CRITICAL)

When creating test files or documentation files, follow these rules:

## Test Files
- **Placement**: All test files MUST be placed in the `test/` directory at project root
- **Forbidden locations**: DO NOT create test files in the change directory, agent/ directory, or project root
- **File patterns**: test*.py, debug*.py, check*.py, measure*.py, performance*.py, verify*.py, validate*.py
- **Naming conventions**: Use appropriate prefixes (test_, debug_, check_, measure_, performance_, verify_, validate_)
- **Example**: Task "Write unit tests for component extraction" → Create: test/test_component_extraction.py

## Documentation Files
- **Placement**: All .md documentation files MUST be placed in the `ralph-docs/` directory at project root
- **Forbidden locations**: DO NOT create .md documentation files in the project root (except core files: README.md, CHANGELOG.md, SETUP.md, TESTING.md, DEPENDENCIES.md, deploy_log.md)
- **Examples**: Task "Create deployment summary" → Create: ralph-docs/DEPLOYMENT_SUMMARY.md

---

## 1. Agent Deployment Manifest

- [ ] 1.1 Create `k8s/agent-deployment.yaml` — a Kubernetes Deployment named `agent` in namespace `default` with 1 replica, image `localhost:32000/agent:latest`, container port 8000, label `app: agent`, `envFrom` referencing `my-ag-ui-app-secrets` Secret and `my-ag-ui-app-config` ConfigMap, liveness and readiness probes on `GET /api/health` port 8000 (initialDelaySeconds: 10, periodSeconds: 15, failureThreshold: 3, timeoutSeconds: 5), and resource requests/limits (memory requests 256Mi, memory limits 512Mi, CPU requests 100m, CPU limits 500m).
  - **Done when**: `k8s/agent-deployment.yaml` exists and contains all of the above fields. Verify with: `grep -c 'agent-deployment\|agent\|localhost:32000/agent\|8000\|envFrom\|livenessProbe\|readinessProbe\|/api/health\|256Mi\|512Mi' k8s/agent-deployment.yaml` returning at least 10 matches.

## 2. Agent Service Manifest

- [ ] 2.1 Create `k8s/agent-service.yaml` — a Kubernetes ClusterIP Service named `agent-service` in namespace `default`, selecting pods with label `app: agent`, mapping port 8000 to targetPort 8000, protocol TCP.
  - **Done when**: `k8s/agent-service.yaml` exists with `type: ClusterIP`, selector `app: agent`, and port mapping `8000:8000`. Verify with: `grep -c 'agent-service\|ClusterIP\|app: agent\|port: 8000\|targetPort: 8000' k8s/agent-service.yaml` returning at least 5 matches.

## 3. Frontend Deployment Update

- [ ] 3.1 Update `k8s/deployment.yaml` — add `env` entry `AGENT_URL=http://agent-service:8000/` and add `envFrom` entries referencing `my-ag-ui-app-secrets` Secret and `my-ag-ui-app-config` ConfigMap. Preserve all existing fields (replicas: 3, image, ports, labels).
  - **Done when**: `k8s/deployment.yaml` contains `name: AGENT_URL`, `value: "http://agent-service:8000/"`, `secretRef` referencing `my-ag-ui-app-secrets`, and `configMapRef` referencing `my-ag-ui-app-config`. Verify with: `grep -c 'AGENT_URL\|agent-service:8000\|my-ag-ui-app-secrets\|my-ag-ui-app-config' k8s/deployment.yaml` returning at least 4 matches.

## 4. Manifest Validation

- [ ] 4.1 Validate all three manifests pass `kubectl --dry-run=client` validation. Run `microk8s kubectl apply --dry-run=client -f k8s/agent-deployment.yaml && microk8s kubectl apply --dry-run=client -f k8s/agent-service.yaml && microk8s kubectl apply --dry-run=client -f k8s/deployment.yaml` and confirm all three return `created (dry run)` or `configured (dry run)` with no errors.
  - **Done when**: All three dry-run commands exit with code 0 and produce no error output.

---

## Human Handoff (NOT for autonomous execution)

The following steps require human action after the manifests are validated:

1. **Build and push agent image**:
   ```bash
   docker build -t localhost:32000/agent:latest ./agent
   docker push localhost:32000/agent:latest
   ```

2. **Verify secrets are current**:
   ```bash
   microk8s kubectl get secret my-ag-ui-app-secrets -o yaml
   # If stale or missing: update k8s/secrets.yaml and re-apply
   ```

3. **Apply agent manifests**:
   ```bash
   microk8s kubectl apply -f k8s/agent-deployment.yaml
   microk8s kubectl apply -f k8s/agent-service.yaml
   ```

4. **Apply updated frontend**:
   ```bash
   microk8s kubectl apply -f k8s/deployment.yaml
   microk8s kubectl rollout restart deployment/my-ag-ui-app
   ```

5. **Verify rollout**:
   ```bash
   microk8s kubectl rollout status deployment/agent
   microk8s kubectl rollout status deployment/my-ag-ui-app
   ```

6. **End-to-end test**: Open `http://my-ag-ui-app.local/`, submit a chat prompt, confirm a response is received.

7. **Rollback** (if needed):
   ```bash
   microk8s kubectl rollout undo deployment/agent
   microk8s kubectl rollout undo deployment/my-ag-ui-app
   ```
