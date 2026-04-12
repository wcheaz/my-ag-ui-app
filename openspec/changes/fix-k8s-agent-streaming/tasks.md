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

## Shell Scripts
- **Placement**: Diagnostic and verification shell scripts MUST be placed in the `test/` directory at project root
- **Naming conventions**: debug_*.sh, verify_*.sh, check_*.sh
- **Example**: Task "Create SSE diagnostic script" → Create: test/debug_k8s_sse_streaming.sh

---

## 1. Cluster State Baseline

- [x] 1.1 Collect current cluster state — create script `test/check_k8s_cluster_state.sh` that runs through `multipass exec my-ag-ui-app-k8s` and captures: (a) `microk8s kubectl get pods -o wide` for all pods, (b) `microk8s kubectl describe deployment agent` and `microk8s kubectl describe deployment my-ag-ui-app`, (c) `microk8s kubectl get ingress -o yaml` to verify SSE annotations are present, (d) `microk8s kubectl logs <agent-pod> --tail=50` for recent agent logs, (e) `microk8s kubectl logs -n ingress <ingress-controller-pod> --tail=50` for ingress controller logs, (f) `microk8s kubectl describe pod <agent-pod>` to check for OOMKilled or restart events. Output all results to a single report.
  - **Done when**: Script exists at `test/check_k8s_cluster_state.sh`, is executable, and running it produces a complete report with all 6 sections. Verify with: `test -x test/check_k8s_cluster_state.sh && bash test/check_k8s_cluster_state.sh | grep -cE 'NAME|deployment|ingress|log|OOM'` returning at least 6 matches.
  - **Stop and hand off if**: Multipass VM is not running or microk8s is not accessible.

## 2. SSE Hop-by-Hop Diagnosis

- [x] 2.1 Create diagnostic script `test/debug_k8s_sse_streaming.sh` that tests SSE connectivity at each hop. The script MUST: (a) Get agent pod IP and test `curl -s http://<agent-pod-ip>:8000/api/health` directly, (b) Test `curl -s -N --max-time 10 http://agent-service:8000/api/health` from within a frontend pod via `kubectl exec`, (c) Test SSE stream from agent by sending a minimal AG-UI protocol request to `agent-service:8000` from within a frontend pod, (d) Test the CopilotKit route by sending a POST to `http://localhost:3000/api/copilotkit` from within a frontend pod, (e) Test the full external path by sending a request through the ingress at `http://my-ag-ui-app.local/api/copilotkit` from the host. Each test MUST report PASS/FAIL with relevant details. All `kubectl` commands go through `multipass exec my-ag-ui-app-k8s -- microk8s kubectl`.
  - **Done when**: Script exists at `test/debug_k8s_sse_streaming.sh`, is executable, and produces a hop-by-hop report with PASS/FAIL for each of the 5 hops. Verify with: `test -x test/debug_k8s_sse_streaming.sh && bash test/debug_k8s_sse_streaming.sh 2>&1 | grep -cE 'PASS|FAIL'` returning at least 5 matches.
  - **Stop and hand off if**: No frontend pods are running (cannot exec into them for intra-cluster tests).

- [ ] 2.2 Run the diagnostic script, capture the output, and analyze results to identify the failing hop. Save the diagnostic output to `test/debug_k8s_sse_results.txt`. Based on the failing hop, document the root cause hypothesis in a file `test/debug_k8s_sse_analysis.md` covering: (a) which hop fails, (b) what error/behavior is observed, (c) likely root cause (NGINX buffering, CopilotKit SSE proxy, Next.js standalone streaming, agent timeout, or other), (d) recommended fix.
  - **Done when**: Both `test/debug_k8s_sse_results.txt` and `test/debug_k8s_sse_analysis.md` exist. The analysis file identifies exactly one failing hop and documents a specific root cause. Verify with: `test -f test/debug_k8s_sse_results.txt && test -f test/debug_k8s_sse_analysis.md && grep -cE 'failing hop|root cause|recommended fix' test/debug_k8s_sse_analysis.md` returning at least 3 matches.

## 3. Code-Level Investigation

- [ ] 3.1 Investigate the CopilotKit runtime SSE proxy behavior — examine `src/app/api/copilotkit/route.ts` and trace how the `handleRequest(req)` response flows through Next.js. Check the `@ag-ui/client` `HttpAgent` implementation for SSE handling. Check the `@copilotkit/runtime` `copilotRuntimeNextJSAppRouterEndpoint` for streaming configuration. Document findings in `test/debug_copilotkit_sse_analysis.md` including: (a) how SSE events flow from agent → HttpAgent → CopilotKit runtime → NextResponse, (b) whether any buffering occurs in this chain, (c) whether Next.js App Router streaming is correctly configured, (d) any configuration options that control streaming behavior.
  - **Done when**: File `test/debug_copilotkit_sse_analysis.md` exists and documents the complete SSE flow from agent to browser with specific code references. Verify with: `test -f test/debug_copilotkit_sse_analysis.md && grep -cE 'HttpAgent|copilotRuntime|NextResponse|streaming|buffering' test/debug_copilotkit_sse_analysis.md` returning at least 5 matches.

- [ ] 3.2 Investigate Next.js standalone server SSE behavior — research and document whether Next.js standalone server (`.next/standalone/server.js`) handles streaming responses differently than the dev server. Check if the `next.config.ts` needs streaming-related configuration. Check if the `Dockerfile`'s standalone build preserves streaming capability. Document findings in `test/debug_nextjs_standalone_sse.md`.
  - **Done when**: File `test/debug_nextjs_standalone_sse.md` exists and clearly states whether Next.js standalone supports SSE streaming natively, and if not, what configuration is needed. Verify with: `test -f test/debug_nextjs_standalone_sse.md && grep -cE 'standalone|streaming|SSE|configuration' test/debug_nextjs_standalone_sse.md` returning at least 4 matches.

- [ ] 3.3 Check agent pod logs and resource usage during a streaming request — from the cluster, tail the agent pod logs while submitting a procurement request from the browser. Also check `kubectl top pod` for the agent and `kubectl describe pod <agent-pod>` for any OOM or restart events. Document findings in `test/debug_agent_pod_streaming.md`.
  - **Done when**: File `test/debug_agent_pod_streaming.md` exists and documents: (a) whether the agent pod shows complete processing in logs, (b) whether the agent pod was OOMKilled or restarted, (c) memory usage during streaming. Verify with: `test -f test/debug_agent_pod_streaming.md && grep -cE 'agent pod|OOM|restart|memory|processing' test/debug_agent_pod_streaming.md` returning at least 4 matches.

## 4. Implement Fix

- [ ] 4.1 Based on the root cause identified in tasks 2.2 and 3.x, implement the fix. The fix target depends on the diagnosed root cause:
  - **If NGINX ingress**: Update `k8s/ingress.yaml` with corrected or additional annotations, then apply via `multipass transfer` + `microk8s kubectl apply`.
  - **If CopilotKit/Next.js streaming**: Update `src/app/api/copilotkit/route.ts` or `next.config.ts` with streaming configuration, then rebuild and redeploy the frontend image.
  - **If agent uvicorn**: Update `agent/Dockerfile` CMD or `k8s/agent-deployment.yaml` with uvicorn flags, then rebuild and redeploy the agent image.
  - **If Next.js standalone**: Update `Dockerfile` or `next.config.ts` to enable streaming in standalone mode.
  - **If K8s service/deployment timeout**: Update `k8s/deployment.yaml` or `k8s/agent-deployment.yaml` with appropriate timeout settings.
  Document the exact change made in `test/debug_k8s_sse_fix_applied.md` with: (a) root cause, (b) files changed, (c) diff of each change.
  - **Done when**: The fix is committed to the relevant file(s) and documented in `test/debug_k8s_sse_fix_applied.md`. Verify with: `test -f test/debug_k8s_sse_fix_applied.md && grep -cE 'root cause|files changed|diff' test/debug_k8s_sse_fix_applied.md` returning at least 3 matches.

## 5. Verification

- [ ] 5.1 Create verification script `test/verify_k8s_sse_fix.sh` that submits a real procurement request to the Kubernetes deployment and validates the complete response. The script MUST: (a) Send a POST request with a valid AG-UI/CopilotKit payload to `http://my-ag-ui-app.local/api/copilotkit`, (b) Use `curl -N --max-time 120` to receive the SSE stream, (c) Validate that multiple SSE events are received (not just the initial acknowledgment), (d) Validate the response is not truncated (contains a terminal SSE event or complete JSON payload), (e) Report PASS if complete response received, FAIL otherwise with details.
  - **Done when**: Script exists at `test/verify_k8s_sse_fix.sh`, is executable, and tests SSE completeness. Verify with: `test -x test/verify_k8s_sse_fix.sh && grep -cE 'curl.*max-time|SSE|PASS|FAIL|truncat' test/verify_k8s_sse_fix.sh` returning at least 5 matches.

- [ ] 5.2 Run the verification script after applying the fix. Capture output to `test/verify_k8s_sse_fix_results.txt`. If the test passes, document the successful fix in `ralph-docs/K8S_SSE_STREAMING_FIX.md` with: (a) problem description, (b) root cause, (c) fix applied, (d) verification results, (e) any K8s manifest changes that need to be applied on future deployments.
  - **Done when**: Both `test/verify_k8s_sse_fix_results.txt` and `ralph-docs/K8S_SSE_STREAMING_FIX.md` exist. The verification results show PASS. Verify with: `test -f test/verify_k8s_sse_fix_results.txt && test -f ralph-docs/K8S_SSE_STREAMING_FIX.md && grep -c 'PASS' test/verify_k8s_sse_fix_results.txt` returning at least 1 match.

---

## Human Handoff (NOT for autonomous execution)

After the fix is verified in code and diagnostics, the following manual steps are required to deploy:

1. **Rebuild affected images**: If source code changed (frontend and/or agent), rebuild Docker images on the host:
   ```bash
   # If frontend changed:
   docker build -t my-ag-ui-app:latest .
   # If agent changed:
   docker build -t agent:latest ./agent
   ```

2. **Transfer images to VM** (follow existing pattern in `deploy_scripts/build-docker-image.sh`):
   ```bash
   IMAGE_ID=$(docker images <image-name>:latest --format "{{.ID}}" | head -n1)
   docker save "$IMAGE_ID" -o ./<image-name>.tar
   multipass transfer ./<image-name>.tar my-ag-ui-app-k8s:/tmp/
   multipass exec my-ag-ui-app-k8s -- docker load -i /tmp/<image-name>.tar
   VM_IMAGE_ID=$(multipass exec my-ag-ui-app-k8s -- docker images --format "{{.ID}}" | head -n1)
   multipass exec my-ag-ui-app-k8s -- docker tag "$VM_IMAGE_ID" localhost:32000/<image-name>:latest
   multipass exec my-ag-ui-app-k8s -- docker push localhost:32000/<image-name>:latest
   ```

3. **Apply updated K8s manifests** (if any changed):
   ```bash
   multipass transfer k8s/<manifest>.yaml my-ag-ui-app-k8s:/home/ubuntu/<manifest>.yaml
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/<manifest>.yaml
   ```

4. **Restart affected deployments**:
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout restart deployment/<deployment-name>
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout status deployment/<deployment-name>
   ```

5. **Run end-to-end verification**:
   ```bash
   bash test/verify_k8s_sse_fix.sh
   ```

6. **Rollback** (if needed):
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout undo deployment/<deployment-name>
   ```

7. **Cleanup temporary files**:
   ```bash
   rm -f ./*.tar
   multipass exec my-ag-ui-app-k8s -- rm -f /tmp/*.tar
   ```
