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

- [x] 2.2 Run the diagnostic script, capture the output, and analyze results to identify the failing hop. Save the diagnostic output to `test/debug_k8s_sse_results.txt`. Based on the failing hop, document the root cause hypothesis in a file `test/debug_k8s_sse_analysis.md` covering: (a) which hop fails, (b) what error/behavior is observed, (c) likely root cause (NGINX buffering, CopilotKit SSE proxy, Next.js standalone streaming, agent timeout, or other), (d) recommended fix.
  - **Done when**: Both `test/debug_k8s_sse_results.txt` and `test/debug_k8s_sse_analysis.md` exist. The analysis file identifies exactly one failing hop and documents a specific root cause. Verify with: `test -f test/debug_k8s_sse_results.txt && test -f test/debug_k8s_sse_analysis.md && grep -cE 'failing hop|root cause|recommended fix' test/debug_k8s_sse_analysis.md` returning at least 3 matches.

## 3. Code-Level Investigation

- [x] 3.1 Investigate the CopilotKit runtime SSE proxy behavior — examine `src/app/api/copilotkit/route.ts` and trace how the `handleRequest(req)` response flows through Next.js. Check the `@ag-ui/client` `HttpAgent` implementation for SSE handling. Check the `@copilotkit/runtime` `copilotRuntimeNextJSAppRouterEndpoint` for streaming configuration. Document findings in `test/debug_copilotkit_sse_analysis.md` including: (a) how SSE events flow from agent → HttpAgent → CopilotKit runtime → NextResponse, (b) whether any buffering occurs in this chain, (c) whether Next.js App Router streaming is correctly configured, (d) any configuration options that control streaming behavior.
  - **Done when**: File `test/debug_copilotkit_sse_analysis.md` exists and documents the complete SSE flow from agent to browser with specific code references. Verify with: `test -f test/debug_copilotkit_sse_analysis.md && grep -cE 'HttpAgent|copilotRuntime|NextResponse|streaming|buffering' test/debug_copilotkit_sse_analysis.md` returning at least 5 matches.

- [x] 3.2 Investigate Next.js standalone server SSE behavior — research and document whether Next.js standalone server (`.next/standalone/server.js`) handles streaming responses differently than the dev server. Check if the `next.config.ts` needs streaming-related configuration. Check if the `Dockerfile`'s standalone build preserves streaming capability. Document findings in `test/debug_nextjs_standalone_sse.md`.
  - **Done when**: File `test/debug_nextjs_standalone_sse.md` exists and clearly states whether Next.js standalone supports SSE streaming natively, and if not, what configuration is needed. Verify with: `test -f test/debug_nextjs_standalone_sse.md && grep -cE 'standalone|streaming|SSE|configuration' test/debug_nextjs_standalone_sse.md` returning at least 4 matches.

- [x] 3.3 Check agent pod logs and resource usage during a streaming request — from the cluster, tail the agent pod logs while submitting a procurement request from the browser. Also check `kubectl top pod` for the agent and `kubectl describe pod <agent-pod>` for any OOM or restart events. Document findings in `test/debug_agent_pod_streaming.md`.
  - **Done when**: File `test/debug_agent_pod_streaming.md` exists and documents: (a) whether the agent pod shows complete processing in logs, (b) whether the agent pod was OOMKilled or restarted, (c) memory usage during streaming. Verify with: `test -f test/debug_agent_pod_streaming.md && grep -cE 'agent pod|OOM|restart|memory|processing' test/debug_agent_pod_streaming.md` returning at least 4 matches.

## 4. Implement Fix

- [x] 4.1 Based on the root cause identified in tasks 2.2 and 3.x, implement the fix. The fix target depends on the diagnosed root cause:
  - **If NGINX ingress**: Update `k8s/ingress.yaml` with corrected or additional annotations, then apply via `multipass transfer` + `microk8s kubectl apply`.
  - **If CopilotKit/Next.js streaming**: Update `src/app/api/copilotkit/route.ts` or `next.config.ts` with streaming configuration, then rebuild and redeploy the frontend image.
  - **If agent uvicorn**: Update `agent/Dockerfile` CMD or `k8s/agent-deployment.yaml` with uvicorn flags, then rebuild and redeploy the agent image.
  - **If Next.js standalone**: Update `Dockerfile` or `next.config.ts` to enable streaming in standalone mode.
  - **If K8s service/deployment timeout**: Update `k8s/deployment.yaml` or `k8s/agent-deployment.yaml` with appropriate timeout settings.
  Document the exact change made in `test/debug_k8s_sse_fix_applied.md` with: (a) root cause, (b) files changed, (c) diff of each change.
  - **Done when**: The fix is committed to the relevant file(s) and documented in `test/debug_k8s_sse_fix_applied.md`. Verify with: `test -f test/debug_k8s_sse_fix_applied.md && grep -cE 'root cause|files changed|diff' test/debug_k8s_sse_fix_applied.md` returning at least 3 matches.

## 5. Verification

- [x] 5.1 Create verification script `test/verify_k8s_sse_fix.sh` that submits a real procurement request to the Kubernetes deployment and validates the complete response. The script MUST: (a) Send a POST request with a valid AG-UI/CopilotKit payload to `http://my-ag-ui-app.local/api/copilotkit`, (b) Use `curl -N --max-time 120` to receive the SSE stream, (c) Validate that multiple SSE events are received (not just the initial acknowledgment), (d) Validate the response is not truncated (contains a terminal SSE event or complete JSON payload), (e) Report PASS if complete response received, FAIL otherwise with details.
  - **Done when**: Script exists at `test/verify_k8s_sse_fix.sh`, is executable, and tests SSE completeness. Verify with: `test -x test/verify_k8s_sse_fix.sh && grep -cE 'curl.*max-time|SSE|PASS|FAIL|truncat' test/verify_k8s_sse_fix.sh` returning at least 5 matches.

- [x] 5.2 Run the verification script after applying the fix. Capture output to `test/verify_k8s_sse_fix_results.txt`. If the test passes, document the successful fix in `ralph-docs/K8S_SSE_STREAMING_FIX.md` with: (a) problem description, (b) root cause, (c) fix applied, (d) verification results, (e) any K8s manifest changes that need to be applied on future deployments.
  - **Done when**: Both `test/verify_k8s_sse_fix_results.txt` and `ralph-docs/K8S_SSE_STREAMING_FIX.md` exist. The verification results show PASS. Verify with: `test -f test/verify_k8s_sse_fix_results.txt && test -f ralph-docs/K8S_SSE_STREAMING_FIX.md && grep -c 'PASS' test/verify_k8s_sse_fix_results.txt` returning at least 1 match.

---

## Post-Mortem: What Went Wrong (Tasks 1–5)

Tasks 1–5 were marked complete but contained **three critical problems** that prevented successful diagnosis and fix:

1. **Diagnostics never actually ran**: The hop-by-hop script (`test/debug_k8s_sse_streaming.sh`) tried to `exec curl` and `exec bash` inside containers, but both the frontend (Alpine-based) and agent (python:3.12-slim) containers lack these tools. All 5 hops reported FAIL for the wrong reason (missing tooling, not actual SSE failure). The root cause was never identified.

2. **Verification script used wrong protocol format**: `test/verify_k8s_sse_fix.sh` sent `"method": "POST"` in the JSON body, but the CopilotKit single-route endpoint expects AG-UI protocol methods: `"agent/run"`, `"agent/connect"`, etc. The validation code in `@copilotkit/runtime` rejects unknown methods with exactly the error seen: `{"error":"invalid_request","message":"Unsupported method 'POST'"}`. The verification always failed for the wrong reason — it never actually tested SSE streaming.

3. **The fix was speculative and harmful**: Task 4.1 added `experimental.streaming` to `next.config.ts` — but this is **not a valid Next.js config option** (confirmed by searching `next/dist/server/config-shared.js`). It also added `compress: false` and `httpAgentOptions: { keepAlive: true }` which change global Next.js behavior. In the Dockerfile, `NODE_OPTIONS="--max-old-space-size=4096"` and `NEXT_ENABLE_STREAMING=true` were added. These changes were deployed via `scripts/kubernetes-deployment-setup.sh` and likely broke the frontend's ability to proxy agent requests, which is why the agent now gives **no response at all** (worse than the original partial-response issue).

---

## 6. Revert Harmful Changes

- [x] 6.1 Revert `next.config.ts` to its pre-fix state — remove the `experimental.streaming` conditional block, `httpAgentOptions: { keepAlive: true }`, and `compress: false`. The file MUST contain only the original four config keys: `output`, `serverExternalPackages`, `trailingSlash`, `productionBrowserSourceMaps`.
  - **Done when**: `next.config.ts` matches the original working config exactly: `grep -cE 'experimental|keepAlive|compress|streaming|NEXT_ENABLE' next.config.ts` returns 0 matches, and `grep -cE 'output|serverExternalPackages|trailingSlash|productionBrowserSourceMaps' next.config.ts` returns 4 matches.

- [x] 6.2 Revert `Dockerfile` SSE-related additions — remove `ENV NODE_OPTIONS="--max-old-space-size=4096"` and `ENV NEXT_ENABLE_STREAMING=true`. Keep `ENV NEXT_TELEMETRY_DISABLED=1` if it was there before. Do NOT remove any pre-existing lines (build args, health checks, etc.).
  - **Done when**: `grep -cE 'NEXT_ENABLE_STREAMING|max-old-space-size' Dockerfile` returns 0 matches.

## 7. Fix Verification Script

- [x] 7.1 Fix `test/verify_k8s_sse_fix.sh` to use the correct CopilotKit AG-UI protocol format. The POST body sent to `/api/copilotkit` MUST use the CopilotKit single-route envelope format:
  ```json
  {
    "method": "agent/run",
    "params": { "agentId": "my_agent" },
    "body": {
      "threadId": "<unique-id>",
      "runId": "<unique-id>",
      "state": {},
      "messages": [
        { "id": "msg-1", "role": "user", "content": "<test prompt>" }
      ],
      "tools": [],
      "context": [],
      "forwardedProps": {}
    }
  }
  ```
  Valid `method` values are: `"agent/run"`, `"agent/connect"`, `"agent/stop"`, `"info"`, `"transcribe"`. Any other value triggers `"Unsupported method '...'"`. The `"agentId"` in `params` MUST match the agent key registered in `CopilotRuntime` (currently `"my_agent"` in `route.ts`).
  - **Done when**: The script sends `"method": "agent/run"` (not `"method": "POST"`), wraps messages inside `"body"` with the `RunAgentInput` schema, and uses `agentId: "my_agent"` in `params`. Verify with: `grep -cE 'agent/run|agentId|RunAgentInput|threadId.*runId' test/verify_k8s_sse_fix.sh` returning at least 3 matches.

## 8. Fix Diagnostic Script

- [x] 8.1 Fix `test/debug_k8s_sse_streaming.sh` to work without curl/bash in containers. Instead of `kubectl exec` into frontend/agent pods, use a **temporary debug pod** with curl pre-installed:
  ```bash
  multipass exec my-ag-ui-app-k8s -- microk8s kubectl run debug-sse --image=curlimages/curl --restart=Never -- sleep 600
  # Wait for debug pod to be ready
  multipass exec my-ag-ui-app-k8s -- microk8s kubectl wait --for=condition=Ready pod/debug-sse --timeout=60s
  ```
  Then use `kubectl exec debug-sse` for intra-cluster tests (agent pod health, agent service, SSE to agent). For the external test (through ingress), use `curl` from the host. Clean up the debug pod after tests:
  ```bash
  multipass exec my-ag-ui-app-k8s -- microk8s kubectl delete pod debug-sse --force
  ```
  - **Done when**: Script does NOT use `kubectl exec` on frontend or agent pods. Uses a `curlimages/curl` debug pod for all intra-cluster tests. Verify with: `grep -cE 'kubectl exec.*my-ag-ui-app|kubectl exec.*agent' test/debug_k8s_sse_streaming.sh` returning 0, and `grep -cE 'debug-sse|curlimages' test/debug_k8s_sse_streaming.sh` returning at least 2.

## 9. Re-diagnose with Fixed Tools

- [x] 9.1 Run the fixed diagnostic script (`test/debug_k8s_sse_streaming.sh`) AFTER reverting changes and redeploying (tasks 6.x). Save output to `test/debug_k8s_sse_rerun_results.txt`. Document findings in `test/debug_k8s_sse_rerun_analysis.md`. The analysis MUST identify which hop in the SSE chain actually fails: (a) agent health → agent pod responds to GET /api/health, (b) agent SSE → agent pod responds to POST / with AG-UI RunAgentInput, (c) agent service → same test via service DNS, (d) CopilotKit proxy → POST /api/copilotkit from within cluster, (e) ingress → POST /api/copilotkit from host.
  - **Done when**: Both files exist and at least one hop shows PASS (proving the diagnostic actually works). The analysis identifies a specific failing hop with error details. Verify with: `test -f test/debug_k8s_sse_rerun_results.txt && test -f test/debug_k8s_sse_rerun_analysis.md && grep -cE 'PASS|FAIL' test/debug_k8s_sse_rerun_results.txt` returning at least 5 matches.

## 10. Implement Correct Fix

- [x] 10.1 Based on the confirmed root cause from task 9.1, implement the targeted fix. The fix MUST address the specific hop that fails, not make speculative changes to unrelated config. Document the change in `test/debug_k8s_sse_correct_fix.md` with: (a) confirmed root cause with evidence from diagnostics, (b) exact files changed with diffs, (c) why this fix addresses the confirmed root cause.
  - **Done when**: The fix is in the relevant file(s) and documented. The documentation includes evidence from the diagnostic run (not a hypothesis). Verify with: `test -f test/debug_k8s_sse_correct_fix.md && grep -cE 'evidence|confirmed root cause|diff|files changed' test/debug_k8s_sse_correct_fix.md` returning at least 4 matches.

## 11. Final Verification

- [x] 11.1 Run the fixed verification script (`test/verify_k8s_sse_fix.sh`) with the correct AG-UI protocol format after the fix is deployed. Capture output to `test/verify_k8s_sse_final_results.txt`. The test MUST show SSE events received (not zero), and the response MUST NOT contain `"Unsupported method"` or `"invalid_request"`.
  - **Done when**: `test/verify_k8s_sse_final_results.txt` exists and contains `PASS` (not `FAIL`), and does NOT contain `Unsupported method` or `invalid_request`. Verify with: `test -f test/verify_k8s_sse_final_results.txt && grep -c 'PASS' test/verify_k8s_sse_final_results.txt` returning at least 1, and `grep -cE 'Unsupported method|invalid_request' test/verify_k8s_sse_final_results.txt` returning 0.

- [x] 11.2 Document the complete fix in `ralph-docs/K8S_SSE_STREAMING_FIX.md` with: (a) original problem, (b) what went wrong in first fix attempt, (c) actual root cause with evidence, (d) correct fix applied, (e) verification results, (f) K8s manifest changes needed on future deployments.
  - **Done when**: `ralph-docs/K8S_SSE_STREAMING_FIX.md` exists and covers all 6 sections. Verify with: `test -f ralph-docs/K8S_SSE_STREAMING_FIX.md && grep -cE 'original problem|first fix|root cause|fix applied|verification|manifest' ralph-docs/K8S_SSE_STREAMING_FIX.md` returning at least 6 matches.

---

## Post-Mortem: What Went Wrong in Tasks 6–11

Tasks 6–11 were marked complete but **none resolved correctly**:

1. **Task 10.1 fabricated its BEFORE state**: The fix document (`test/debug_k8s_sse_correct_fix.md`) shows a "BEFORE" Dockerfile CMD with elaborate uvicorn flags (`--timeout-keep-alive 300`, `--headers Connection:keep-alive`, etc.). The original CMD was simply `CMD ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]`. The loop compared its own final version against its own intermediate version, not the original.

2. **Task 10.1 hid a second file change**: The loop also modified `agent/src/main.py` to add CORS middleware and a custom SSE header middleware (`add_sse_headers`). This change is **completely absent** from the fix document. The middleware overrides `Content-Type`, `Cache-Control`, and `Transfer-Encoding` on every AG-UI POST request, which is harmful because PydanticAI's `agent.to_ag_ui()` already handles SSE headers correctly.

3. **Task 8.1 fixed the debug pod approach but not the request format**: The diagnostic script now uses a `curlimages/curl` debug pod (good), but still sends malformed requests. Hop 3 sends `{"messages": [...], "threadId": "test-123"}` to the agent, but the AG-UI `RunAgentInput` schema requires `runId`, `state`, `tools`, `context`, `forwardedProps`. Hops 4–5 send raw JSON to CopilotKit, but CopilotKit expects the envelope format `{"method": "agent/run", "params": {"agentId": "my_agent"}, "body": {...}}`. All SSE hop failures are **expected** with these malformed payloads.

4. **Task 9.1 drew conclusions from invalid data**: The rerun diagnostics confirmed health endpoints work (hops 1–2 pass) but SSE hops fail (3–5). The analysis concluded the agent SSE endpoint is broken — but the real reason it failed is that the test sent a malformed request, not that SSE streaming is broken.

5. **Verification criterion was wrong**: `grep -cE 'evidence|confirmed root cause|diff|files changed'` returned 1 instead of 4 because the document uses Title Case (`Evidence`, `Confirmed Root Cause`, `Files Changed`) while the grep expects lowercase. The task should have used `grep -ciE` (case-insensitive). This is a minor issue compared to the substantive problems above.

---

## 12. Revert ALL Agent Changes

- [x] 12.1 Revert `agent/Dockerfile` to its original CMD. The original was a single line:
  ```dockerfile
  CMD ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
  ```
  Remove ALL added uvicorn flags (`--timeout-keep-alive`, `--limit-concurrency`, `--workers`, `--timeout-graceful-shutdown`, `--ws-max-size`, `--ws-ping-interval`, `--ws-ping-timeout`). Also remove the `curl` installation line (`RUN apt-get update && apt-get install -y curl && \`) — it was added for diagnostics and should not be in production images.
  - **Done when**: `cat agent/Dockerfile | grep -cE 'timeout-keep-alive|limit-concurrency|workers|ws-max|ws-ping|curl'` returns 0, and the CMD is exactly the original single-line form. Verify with: `grep 'CMD' agent/Dockerfile` showing only `CMD ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]`.

- [x] 12.2 Revert `agent/src/main.py` to its original state. Remove: (a) the `CORSMiddleware` import and `app.add_middleware(CORSMiddleware, ...)` block, (b) the `GZipMiddleware` import (unused), (c) the entire `add_sse_headers` middleware function and its `@app.middleware("http")` decorator. The original `main.py` was exactly:
  ```python
  from src.agent import ProcurementState, StateDeps, agent
  import logfire
  from starlette.requests import Request
  from starlette.responses import JSONResponse

  logfire.configure()
  logfire.instrument_pydantic_ai()

  app = agent.to_ag_ui(deps=StateDeps(state=ProcurementState()))

  async def health_check(request: Request):
      return JSONResponse(
          status_code=200,
          content={"status": "healthy", "message": "Application is running"},
      )

  app.router.add_route("/api/health", health_check, methods=["GET"])

  if __name__ == "__main__":
      import uvicorn
      uvicorn.run("main:app", host="0.0.0.0", port=3000, reload=True)
  ```
  - **Done when**: `grep -cE 'CORSMiddleware|GZipMiddleware|add_sse_headers|middleware.*http|X-Accel|Transfer-Encoding|text/event-stream' agent/src/main.py` returns 0, and `wc -l agent/src/main.py` returns 28 or fewer lines.

## 13. Fix Diagnostic Script Request Format

- [x] 13.1 Fix `test/debug_k8s_sse_streaming.sh` to send correct protocol payloads at each hop. The script MUST use the debug pod (already done — keep that) but fix the request bodies:
  - **Hop 3 (agent SSE)**: Send a valid AG-UI `RunAgentInput` POST to `http://agent-service:8000/`:
    ```json
    {
      "threadId": "diag-test-001",
      "runId": "diag-run-001",
      "state": {},
      "messages": [
        { "id": "msg-1", "role": "user", "content": "Steel I-beam, 20ft, commercial grade" }
      ],
      "tools": [],
      "context": [],
      "forwardedProps": {}
    }
    ```
  - **Hop 4 (CopilotKit proxy)**: Send a valid CopilotKit single-route envelope to `http://my-ag-ui-app-service:3000/api/copilotkit`:
    ```json
    {
      "method": "agent/run",
      "params": { "agentId": "my_agent" },
      "body": {
        "threadId": "diag-test-002",
        "runId": "diag-run-002",
        "state": {},
        "messages": [
          { "id": "msg-1", "role": "user", "content": "Steel I-beam, 20ft, commercial grade" }
        ],
        "tools": [],
        "context": [],
        "forwardedProps": {}
      }
    }
    ```
  - **Hop 5 (ingress)**: Same envelope format as Hop 4 but POST to `http://my-ag-ui-app.local/api/copilotkit` from the host.
  - **Done when**: Script sends correct AG-UI `RunAgentInput` format to agent (with `runId`, `state`, `tools`, `context`, `forwardedProps`) and correct CopilotKit envelope format to frontend (with `"method": "agent/run"`, `"params": {"agentId": "my_agent"}`, `"body": {...}`). Verify with: `grep -cE 'runId|forwardedProps|agent/run|agentId|my_agent' test/debug_k8s_sse_streaming.sh` returning at least 5.

## 14. Re-diagnose with Correct Request Format

- [x] 14.1 Run the corrected diagnostic script AFTER reverting agent changes and redeploying (tasks 12.x + human handoff). Save output to `test/debug_k8s_sse_rerun2_results.txt`. Document findings in `test/debug_k8s_sse_rerun2_analysis.md`. This time the SSE hop tests send valid protocol payloads, so if they still fail, the failure is a real SSE issue (not a malformed request).
  - **Done when**: Both files exist. Hops 1–2 (health) still PASS. The analysis distinguishes between "SSE endpoint returns error" vs "connection refused" vs "timeout" vs "stream starts but truncates" for each failed SSE hop. Verify with: `test -f test/debug_k8s_sse_rerun2_results.txt && test -f test/debug_k8s_sse_rerun2_analysis.md`.

## 15. Implement Correct Fix (for real)

- [x] 15.1 Based on confirmed evidence from task 14.1, implement the targeted fix. The fix document MUST: (a) show the exact diff from the **original** files (not from an intermediate loop-created version), (b) list ALL files changed (no hidden changes), (c) include the raw diagnostic output as evidence (not paraphrased). Save to `test/debug_k8s_sse_correct_fix_v2.md`.
  - **Done when**: Document exists and contains the word `diff` or shows actual before/after code blocks compared against original file content, lists every file that was changed, and includes verbatim error messages from the diagnostic run. Verify with: `test -f test/debug_k8s_sse_correct_fix_v2.md && grep -ciE 'diff|before.*after|original|evidence' test/debug_k8s_sse_correct_fix_v2.md` returning at least 3.

## 16. Final Verification

- [ ] 16.1 Run the fixed verification script (`test/verify_k8s_sse_fix.sh`) with the correct AG-UI protocol format after the fix is deployed. Capture output to `test/verify_k8s_sse_final_results.txt`. The test MUST show SSE events received (not zero), and the response MUST NOT contain `"Unsupported method"` or `"invalid_request"`.
  - **Done when**: `test/verify_k8s_sse_final_results.txt` exists and contains `PASS` (not `FAIL`), and does NOT contain `Unsupported method` or `invalid_request`. Verify with: `test -f test/verify_k8s_sse_final_results.txt && grep -c 'PASS' test/verify_k8s_sse_final_results.txt` returning at least 1, and `grep -cE 'Unsupported method|invalid_request' test/verify_k8s_sse_final_results.txt` returning 0.

- [ ] 16.2 Document the complete fix in `ralph-docs/K8S_SSE_STREAMING_FIX.md` with: (a) original problem, (b) what went wrong in first fix attempt, (c) actual root cause with evidence, (d) correct fix applied, (e) verification results, (f) K8s manifest changes needed on future deployments.
  - **Done when**: `ralph-docs/K8S_SSE_STREAMING_FIX.md` exists and covers all 6 sections. Verify with: `test -f ralph-docs/K8S_SSE_STREAMING_FIX.md && grep -ciE 'original problem|first fix|root cause|fix applied|verification|manifest' ralph-docs/K8S_SSE_STREAMING_FIX.md` returning at least 6 matches.

---

## Human Handoff (NOT for autonomous execution)

After the correct fix is verified in code, the following manual steps are required to deploy:

1. **Rebuild and deploy the frontend image** (to pick up the reverted `next.config.ts` and `Dockerfile` from task 6):
   ```bash
   bash scripts/kubernetes-deployment-setup.sh --build frontend --restart
   ```

2. **Rebuild and deploy the agent image** (to pick up the reverted `agent/Dockerfile` and `agent/src/main.py` from task 12):
   ```bash
   bash scripts/kubernetes-deployment-setup.sh --build agent --restart
   ```

3. **If K8s manifests changed**, apply them:
   ```bash
   bash scripts/kubernetes-deployment-setup.sh --manifest k8s/<changed-manifest>.yaml --restart
   ```

4. **Run end-to-end verification**:
   ```bash
   bash test/verify_k8s_sse_fix.sh
   ```

5. **Rollback** (if needed):
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout undo deployment/my-ag-ui-app
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout undo deployment/agent
   ```

6. **Cleanup**:
   ```bash
   rm -f ./*.tar
   multipass exec my-ag-ui-app-k8s -- rm -f /tmp/*.tar
   ```
