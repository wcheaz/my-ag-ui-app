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

## 0. Fix Secret and ConfigMap Key Names (Prerequisite)

- [x] 0.1 Update `k8s/setup-secrets.sh` — rename all Secret keys from kebab-case to SCREAMING_SNAKE_CASE: `openai-api-key` → `OPENAI_API_KEY`, `openai-base-url` → `OPENAI_BASE_URL`, `openai-model` → `OPENAI_MODEL`, `embedding-model` → `EMBEDDING_MODEL`, `logfire-token` → `LOGFIRE_TOKEN`. Also rename ConfigMap keys: `llm-max-tokens` → `LLM_MAX_TOKENS`, `llm-context-window` → `LLM_CONTEXT_WINDOW`.
  - **Done when**: `grep -cE 'OPENAI_API_KEY|OPENAI_BASE_URL|OPENAI_MODEL|EMBEDDING_MODEL|LOGFIRE_TOKEN|LLM_MAX_TOKENS|LLM_CONTEXT_WINDOW' k8s/setup-secrets.sh` returns at least 7 matches and no kebab-case key names remain in the generated YAML template section.

- [x] 0.2 Regenerate `k8s/secrets.yaml` — run `bash k8s/setup-secrets.sh` (or `deploy_scripts/setup-k8s-secrets.sh`) to regenerate the file with SCREAMING_SNAKE_CASE keys.
  - **Done when**: `grep -cE 'OPENAI_API_KEY|OPENAI_BASE_URL|OPENAI_MODEL|EMBEDDING_MODEL|LOGFIRE_TOKEN|LLM_MAX_TOKENS|LLM_CONTEXT_WINDOW' k8s/secrets.yaml` returns at least 7 matches and `grep -cE 'openai-api-key|openai-base-url|openai-model|embedding-model|logfire-token|llm-max-tokens|llm-context-window' k8s/secrets.yaml` returns 0 matches.

- [x] 0.3 Re-apply secrets to the cluster — `multipass transfer k8s/secrets.yaml my-ag-ui-app-k8s:/home/ubuntu/secrets.yaml && multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/secrets.yaml`
  - **Done when**: `multipass exec my-ag-ui-app-k8s -- microk8s kubectl get secret my-ag-ui-app-secrets -o jsonpath='{.data}'` shows keys in SCREAMING_SNAKE_CASE format.

---

## 1. Agent Deployment Manifest

- [x] 1.1 Create `k8s/agent-deployment.yaml` — a Kubernetes Deployment named `agent` in namespace `default` with 1 replica, image `localhost:32000/agent:latest`, container port 8000, label `app: agent`, `envFrom` referencing `my-ag-ui-app-secrets` Secret and `my-ag-ui-app-config` ConfigMap, liveness and readiness probes on `GET /api/health` port 8000 (initialDelaySeconds: 10, periodSeconds: 15, failureThreshold: 3, timeoutSeconds: 5), and resource requests/limits (memory requests 256Mi, memory limits 512Mi, CPU requests 100m, CPU limits 500m).
  - **Done when**: `k8s/agent-deployment.yaml` exists and contains all of the above fields. Verify with: `grep -c 'agent-deployment\|agent\|localhost:32000/agent\|8000\|envFrom\|livenessProbe\|readinessProbe\|/api/health\|256Mi\|512Mi' k8s/agent-deployment.yaml` returning at least 10 matches.

## 2. Agent Service Manifest

- [x] 2.1 Create `k8s/agent-service.yaml` — a Kubernetes ClusterIP Service named `agent-service` in namespace `default`, selecting pods with label `app: agent`, mapping port 8000 to targetPort 8000, protocol TCP.
  - **Done when**: `k8s/agent-service.yaml` exists with `type: ClusterIP`, selector `app: agent`, and port mapping `8000:8000`. Verify with: `grep -c 'agent-service\|ClusterIP\|app: agent\|port: 8000\|targetPort: 8000' k8s/agent-service.yaml` returning at least 5 matches.

## 3. Frontend Deployment Update

- [x] 3.1 Update `k8s/deployment.yaml` — add `env` entry `AGENT_URL=http://agent-service:8000/` and add `envFrom` entries referencing `my-ag-ui-app-secrets` Secret and `my-ag-ui-app-config` ConfigMap. Preserve all existing fields (replicas: 3, image, ports, labels).
  - **Done when**: `k8s/deployment.yaml` contains `name: AGENT_URL`, `value: "http://agent-service:8000/"`, `secretRef` referencing `my-ag-ui-app-secrets`, and `configMapRef` referencing `my-ag-ui-app-config`. Verify with: `grep -c 'AGENT_URL\|agent-service:8000\|my-ag-ui-app-secrets\|my-ag-ui-app-config' k8s/deployment.yaml` returning at least 4 matches.

## 4. Manifest Validation

- [x] 4.1 Validate all three manifests pass `kubectl --dry-run=client` validation. Transfer each manifest to the VM and run dry-run validation there. Run: `multipass transfer k8s/agent-deployment.yaml my-ag-ui-app-k8s:/tmp/agent-deployment.yaml && multipass transfer k8s/agent-service.yaml my-ag-ui-app-k8s:/tmp/agent-service.yaml && multipass transfer k8s/deployment.yaml my-ag-ui-app-k8s:/tmp/deployment.yaml && multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply --dry-run=client -f /tmp/agent-deployment.yaml && multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply --dry-run=client -f /tmp/agent-service.yaml && multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply --dry-run=client -f /tmp/deployment.yaml` and confirm all three return `created (dry run)` or `configured (dry run)` with no errors.
  - **Done when**: All three dry-run commands exit with code 0 and produce no error output.

---

## Human Handoff (NOT for autonomous execution)

All `microk8s kubectl` commands must be run through the Multipass VM. VM name: `my-ag-ui-app-k8s`.

Task 0 (secret key rename) is already complete. The following steps deploy the agent service:

1. **Regenerate and apply secrets** (validates against the cluster via stdin, then applies):
   ```bash
   bash k8s/setup-secrets.sh --apply
   ```
   This single command generates `k8s/secrets.yaml`, validates it against the Kubernetes API server via `multipass exec` stdin piping, and applies it. No manual `multipass transfer` is needed.

2. **Build the agent image on the host** (Python/uv Dockerfile in `agent/`):
   ```bash
   docker build -t agent:latest ./agent
   ```

3. **Transfer image to the Multipass VM**:
   ```bash
   IMAGE_ID=$(docker images agent:latest --format "{{.ID}}" | head -n1)
   docker save "$IMAGE_ID" -o ./agent.tar
   multipass transfer ./agent.tar my-ag-ui-app-k8s:/tmp/
   multipass exec my-ag-ui-app-k8s -- docker load -i /tmp/agent.tar
   ```

4. **Tag and push in the VM**:
   ```bash
   VM_IMAGE_ID=$(multipass exec my-ag-ui-app-k8s -- docker images --format "{{.ID}}" | head -n1)
   multipass exec my-ag-ui-app-k8s -- docker tag "$VM_IMAGE_ID" localhost:32000/agent:latest
   multipass exec my-ag-ui-app-k8s -- docker push localhost:32000/agent:latest
   ```

5. **Verify secrets and config are current on the cluster**:
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl get secret my-ag-ui-app-secrets -o jsonpath='{.data}' | grep -o 'OPENAI_API_KEY'
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl get configmap my-ag-ui-app-config -o yaml
   ```

6. **Transfer and apply agent manifests**:
   ```bash
   multipass transfer k8s/agent-deployment.yaml my-ag-ui-app-k8s:/home/ubuntu/agent-deployment.yaml
   multipass transfer k8s/agent-service.yaml my-ag-ui-app-k8s:/home/ubuntu/agent-service.yaml
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/agent-deployment.yaml
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/agent-service.yaml
   ```

7. **Transfer and apply updated frontend**:
   ```bash
   multipass transfer k8s/deployment.yaml my-ag-ui-app-k8s:/home/ubuntu/deployment.yaml
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/deployment.yaml
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout restart deployment/my-ag-ui-app
   ```

8. **Verify rollout**:
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout status deployment/agent
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout status deployment/my-ag-ui-app
   ```

9. **End-to-end test**: Open `http://my-ag-ui-app.local/`, submit a chat prompt, confirm a response is received.

10. **Rollback** (if needed):
    ```bash
    multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout undo deployment/agent
    multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout undo deployment/my-ag-ui-app
    ```

11. **Cleanup** (remove temporary tar files):
    ```bash
    rm -f ./agent.tar
    multipass exec my-ag-ui-app-k8s -- rm -f /tmp/agent.tar
    ```
