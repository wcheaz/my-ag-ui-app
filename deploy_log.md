Log file created: /tmp/deploy-20260407-140749.log
Log file created: /tmp/deploy-20260407-140749.log
[2026-04-07 14:07:49] Setting up Kubernetes secrets...
[2026-04-07 14:07:49] Reading environment variables...
[2026-04-07 14:07:49] Encoding values to base64...
[2026-04-07 14:07:49] Generating Kubernetes secrets file...
[2026-04-07 14:07:49] Validating generated secrets file against Kubernetes API server...
secret/my-ag-ui-app-secrets unchanged (server dry run)
configmap/my-ag-ui-app-config unchanged (server dry run)
[2026-04-07 14:07:50] ✅ Kubernetes secrets file generated successfully: k8s/secrets.yaml
secret/my-ag-ui-app-secrets unchanged (server dry run)
configmap/my-ag-ui-app-config unchanged (server dry run)
secret/my-ag-ui-app-secrets unchanged
configmap/my-ag-ui-app-config unchanged
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 4.85kB done
#1 DONE 0.0s

#2 [internal] load metadata for docker.io/library/node:20.12.0-alpine
#2 DONE 0.7s

#3 [internal] load .dockerignore
#3 transferring context: 128B done
#3 DONE 0.0s

#4 [builder 1/6] FROM docker.io/library/node:20.12.0-alpine@sha256:ef3f47741e161900ddd07addcaca7e76534a9205e4cd73b2ed091ba339004a75
#4 DONE 0.0s

#5 [internal] load build context
#5 transferring context: 124.30kB 0.1s done
#5 DONE 0.1s

#6 [builder 2/6] WORKDIR /app
#6 CACHED

#7 [builder 3/6] COPY package.json package-lock.json ./
#7 CACHED

#8 [builder 4/6] RUN echo "=== DEPENDENCY INSTALLATION ===" &&     echo "Starting npm ci (reproducible install)..." &&     if npm ci --ignore-scripts; then         echo "✅ SUCCESS: npm ci completed - using reproducible dependencies from lock file";     else         echo "⚠️  WARNING: npm ci failed - lock files are out of sync";         echo "🔄 FALLING BACK to npm install to continue build...";         echo "ℹ️  NOTE: This allows deployment but reduces build reproducibility";         echo "🔧 FIX: Run 'npm install' locally and commit updated package-lock.json";         npm install --ignore-scripts;         echo "✅ SUCCESS: npm install completed - build continuing with fallback dependencies";     fi &&     echo "=== DEPENDENCY INSTALLATION COMPLETED ===" &&     npm cache clean --force
#8 CACHED

#9 [builder 5/6] COPY . .
#9 DONE 0.6s

#10 [builder 6/6] RUN npm run build
#10 0.399 
#10 0.399 > pydantic-ai-starter@0.1.0 build
#10 0.399 > next build
#10 0.399 
#10 1.004 ⚠ Invalid next.config.ts options detected: 
#10 1.005 ⚠     Unrecognized key(s) in object: 'serverComponentsExternalPackages' at "experimental"
#10 1.005 ⚠ See more info here: https://nextjs.org/docs/messages/invalid-next-config
#10 1.006 ⚠ `experimental.serverComponentsExternalPackages` has been moved to `serverExternalPackages`. Please update your next.config.ts file accordingly.
#10 1.016 Attention: Next.js now collects completely anonymous telemetry regarding usage.
#10 1.016 This information is used to shape Next.js' roadmap and prioritize features.
#10 1.016 You can learn more, including how to opt-out if you'd not like to participate in this anonymous program, by visiting the following URL:
#10 1.016 https://nextjs.org/telemetry
#10 1.016 
#10 1.025 ▲ Next.js 16.1.0 (Turbopack)
#10 1.025 - Experiments (use with caution):
#10 1.025   ? serverComponentsExternalPackages (invalid experimental key)
#10 1.025 
#10 1.079   Creating an optimized production build ...
#10 34.02 ✓ Compiled successfully in 32.6s
#10 34.03   Running TypeScript ...
#10 36.67   Collecting page data using 11 workers ...
#10 37.78   Generating static pages using 11 workers (0/6) ...
#10 38.01   Generating static pages using 11 workers (1/6) 
#10 38.48   Generating static pages using 11 workers (2/6) 
#10 38.50   Generating static pages using 11 workers (4/6) 
#10 39.12 ✓ Generating static pages using 11 workers (6/6) in 1340.8ms
#10 39.13   Finalizing page optimization ...
#10 39.29 
#10 39.29 Route (app)
#10 39.29 ┌ ○ /
#10 39.29 ├ ○ /_not-found
#10 39.29 ├ ƒ /api/copilotkit
#10 39.29 └ ƒ /api/health
#10 39.29 
#10 39.29 
#10 39.29 ○  (Static)   prerendered as static content
#10 39.29 ƒ  (Dynamic)  server-rendered on demand
#10 39.29 
#10 DONE 39.7s

#11 [runner 3/6] RUN addgroup --system --gid 1001 nodejs &&     adduser --system --uid 1001 nextjs
#11 CACHED

#12 [runner 4/6] COPY --from=builder /app/public ./public
#12 CACHED

#13 [runner 5/6] COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
#13 DONE 0.5s

#14 [runner 6/6] COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
#14 DONE 0.2s

#15 exporting to image
#15 exporting layers
#15 exporting layers 0.9s done
#15 writing image sha256:26f48915b6e0bfc28a1a0d11e94a04b76f766a9fdcd6230da0a38303b0150ef9 done
#15 naming to docker.io/library/my-ag-ui-app:latest done
#15 DONE 0.9s

View build details: docker-desktop://dashboard/build/default/default/zqn6kj4elpvbnlke5npa66fxd
Untagged: localhost:32000/my-ag-ui-app:latest
[2026-04-07 14:08:40] Verifying tagged image exists after successful tagging...
[2026-04-07 14:08:40] ✅ Image tagging verification successful within VM
[2026-04-07 14:08:40]    Target tag localhost:32000/my-ag-ui-app:latest exists and is accessible within VM
[2026-04-07 14:08:41] ✅ Image ID verification successful - both images reference the same underlying image within VM
Log file created: /tmp/deploy-20260407-140841.log
Log file created: /tmp/deploy-20260407-140847.log
The push refers to repository [localhost:32000/my-ag-ui-app]
d4fc045c9e3a: Layer already exists
8e1fab8d9171: Layer already exists
abc5b1d00820: Layer already exists
413c136dedcf: Layer already exists
52a51099bdef: Layer already exists
75136c45e7ab: Layer already exists
82fb5a2278a7: Layer already exists
a2cffe5fe30b: Layer already exists
f82bfb71098a: Layer already exists
2026-04-07 14:08:48 - DEBUG: Running with full verbose output (critical failure phase)
2026-04-07 14:08:48 - DEBUG: Set DEBUG=all for explicit debugging if needed
2026-04-07 14:08:48 - Starting phase: KUBERNETES_DEPLOYMENT
2026-04-07 14:08:48 - 📋 DEPLOYMENT DETAILS:
2026-04-07 14:08:48 -    • Manifest: k8s/deployment.yaml
2026-04-07 14:08:48 -    • Image: localhost:32000/my-ag-ui-app:latest (from local registry)
2026-04-07 14:08:48 -    • Strategy: Rolling update with pod restart
2026-04-07 14:08:48 -    • Registry: microk8s local registry
2026-04-07 14:08:48 - 
2026-04-07 14:08:49 -    ✓ Registry port validation: PASSED (using port 32000)
deployment.apps/my-ag-ui-app unchanged (server dry run)
deployment.apps/my-ag-ui-app unchanged
2026-04-07 14:08:51 - ✅ KUBECTL APPLY: Command completed successfully (exit code: 0)
2026-04-07 14:08:52 - ✅ Deployment manifest application process completed
2026-04-07 14:08:52 -    • Kubernetes deployment resource processed
2026-04-07 14:08:52 -    • Next step: Deployment restart to trigger pod creation
2026-04-07 14:08:52 - 
deployment.apps/my-ag-ui-app restarted
2026-04-07 14:08:52 - ✅ Deployment restarted successfully
2026-04-07 14:08:52 - 
2026-04-07 14:08:59 - === POD EVENTS ===
LAST SEEN   TYPE     REASON      OBJECT                              MESSAGE
6s          Normal   Scheduled   pod/my-ag-ui-app-766bbdbf65-vqvvg   Successfully assigned default/my-ag-ui-app-766bbdbf65-vqvvg to my-ag-ui-app-k8s
6s          Normal   Pulling     pod/my-ag-ui-app-766bbdbf65-vqvvg   Pulling image "localhost:32000/my-ag-ui-app:latest"
6s          Normal   Pulled      pod/my-ag-ui-app-766bbdbf65-vqvvg   Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 102ms (102ms including waiting). Image size: 263041608 bytes.
6s          Normal   Created     pod/my-ag-ui-app-766bbdbf65-vqvvg   Created container: my-ag-ui-app
6s          Normal   Started     pod/my-ag-ui-app-766bbdbf65-vqvvg   Started container my-ag-ui-app
2026-04-07 14:08:59 - === END POD EVENTS ===
[2026-04-07 14:09:01] ERROR: ❌ PROBE FAILURES DETECTED (2 events):
[2026-04-07 14:09:01] ERROR:    Unhealthy events indicate readiness or liveness probe failures
LAST SEEN   TYPE      REASON      OBJECT                              MESSAGE
1s          Warning   Unhealthy   pod/my-ag-ui-app-766bbdbf65-vqvvg   Readiness probe failed: HTTP probe failed with statuscode: 404
Name:             my-ag-ui-app-766bbdbf65-vqvvg
Namespace:        default
Priority:         0
Service Account:  default
Node:             my-ag-ui-app-k8s/10.237.212.68
Start Time:       Tue, 07 Apr 2026 14:08:53 -0400
Labels:           app=my-ag-ui-app
                  pod-template-hash=766bbdbf65
Annotations:      cni.projectcalico.org/containerID: bc5fcfbb5dd337044560ca2c007f54d102d4cde58270eed8896d591953d63232
                  cni.projectcalico.org/podIP: 10.1.217.1/32
                  cni.projectcalico.org/podIPs: 10.1.217.1/32
                  kubectl.kubernetes.io/restartedAt: 2026-04-07T14:08:52-04:00
Status:           Running
IP:               10.1.217.1
IPs:
  IP:           10.1.217.1
Controlled By:  ReplicaSet/my-ag-ui-app-766bbdbf65
Containers:
  my-ag-ui-app:
    Container ID:   containerd://aeecbcdb4b366a7b99be9b5b76844de98e8c6d237c4e2767ce71cd26c862a194
    Image:          localhost:32000/my-ag-ui-app:latest
    Image ID:       localhost:32000/my-ag-ui-app@sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f
    Port:           3000/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Tue, 07 Apr 2026 14:08:53 -0400
    Ready:          False
    Restart Count:  0
    Limits:
      cpu:     500m
      memory:  512Mi
    Requests:
      cpu:      100m
      memory:   256Mi
    Liveness:   http-get http://:3000/api/health delay=30s timeout=5s period=10s #success=1 #failure=3
    Readiness:  http-get http://:3000/api/health delay=5s timeout=3s period=5s #success=1 #failure=3
    Environment:
      OPENAI_API_KEY:      <set to the key 'openai-api-key' in secret 'my-ag-ui-app-secrets'>         Optional: false
      OPENAI_BASE_URL:     <set to the key 'openai-base-url' in secret 'my-ag-ui-app-secrets'>        Optional: false
      OPENAI_MODEL:        <set to the key 'openai-model' in secret 'my-ag-ui-app-secrets'>           Optional: false
      EMBEDDING_MODEL:     <set to the key 'embedding-model' in secret 'my-ag-ui-app-secrets'>        Optional: false
      LOGFIRE_TOKEN:       <set to the key 'logfire-token' in secret 'my-ag-ui-app-secrets'>          Optional: false
      LLM_MAX_TOKENS:      <set to the key 'llm-max-tokens' of config map 'my-ag-ui-app-config'>      Optional: false
      LLM_CONTEXT_WINDOW:  <set to the key 'llm-context-window' of config map 'my-ag-ui-app-config'>  Optional: false
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-hkpp7 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  kube-api-access-hkpp7:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason     Age   From               Message
  ----     ------     ----  ----               -------
  Normal   Scheduled  9s    default-scheduler  Successfully assigned default/my-ag-ui-app-766bbdbf65-vqvvg to my-ag-ui-app-k8s
  Normal   Pulling    9s    kubelet            Pulling image "localhost:32000/my-ag-ui-app:latest"
  Normal   Pulled     9s    kubelet            Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 102ms (102ms including waiting). Image size: 263041608 bytes.
  Normal   Created    9s    kubelet            Created container: my-ag-ui-app
  Normal   Started    9s    kubelet            Started container my-ag-ui-app
  Warning  Unhealthy  2s    kubelet            Readiness probe failed: HTTP probe failed with statuscode: 404
[2026-04-07 14:09:02] ERROR: === CONTAINER LOGS (for debugging) ===
▲ Next.js 16.1.0
- Local:         http://my-ag-ui-app-766bbdbf65-vqvvg:3000
- Network:       http://my-ag-ui-app-766bbdbf65-vqvvg:3000

✓ Starting...
✓ Ready in 116ms
[2026-04-07 14:09:02] ERROR: === END CONTAINER LOGS ===
[2026-04-07 14:09:02] ERROR: === PREVIOUS CONTAINER LOGS (if available) ===
Error from server (BadRequest): previous terminated container "my-ag-ui-app" in pod "my-ag-ui-app-766bbdbf65-vqvvg" not found
[2026-04-07 14:09:02] ERROR: === END PREVIOUS CONTAINER LOGS ===
[2026-04-07 14:09:51] ERROR: ❌ Readiness probe verification: FAILED - timeout after 10 attempts
2026-04-07 14:09:51 - Final pod status:
NAME                            READY   STATUS             RESTARTS        AGE
my-ag-ui-app-766bbdbf65-vqvvg   0/1     Running            1 (8s ago)      59s
my-ag-ui-app-f75cf74dc-gh82j    0/1     CrashLoopBackOff   19 (2m5s ago)   54m
2026-04-07 14:09:52 - === POD EVENTS ===
LAST SEEN   TYPE      REASON      OBJECT                              MESSAGE
59s         Normal    Scheduled   pod/my-ag-ui-app-766bbdbf65-vqvvg   Successfully assigned default/my-ag-ui-app-766bbdbf65-vqvvg to my-ag-ui-app-k8s
59s         Normal    Pulled      pod/my-ag-ui-app-766bbdbf65-vqvvg   Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 102ms (102ms including waiting). Image size: 263041608 bytes.
9s          Normal    Pulling     pod/my-ag-ui-app-766bbdbf65-vqvvg   Pulling image "localhost:32000/my-ag-ui-app:latest"
9s          Normal    Created     pod/my-ag-ui-app-766bbdbf65-vqvvg   Created container: my-ag-ui-app
9s          Normal    Started     pod/my-ag-ui-app-766bbdbf65-vqvvg   Started container my-ag-ui-app
9s          Warning   Unhealthy   pod/my-ag-ui-app-766bbdbf65-vqvvg   Liveness probe failed: HTTP probe failed with statuscode: 404
9s          Normal    Killing     pod/my-ag-ui-app-766bbdbf65-vqvvg   Container my-ag-ui-app failed liveness probe, will be restarted
9s          Normal    Pulled      pod/my-ag-ui-app-766bbdbf65-vqvvg   Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 90ms (90ms including waiting). Image size: 263041608 bytes.
2s          Warning   Unhealthy   pod/my-ag-ui-app-766bbdbf65-vqvvg   Readiness probe failed: HTTP probe failed with statuscode: 404
2026-04-07 14:09:52 - === END POD EVENTS ===
[2026-04-07 14:09:53] ERROR: ❌ PROBE FAILURES DETECTED (3 events):
[2026-04-07 14:09:53] ERROR:    Unhealthy events indicate readiness or liveness probe failures
LAST SEEN   TYPE      REASON      OBJECT                              MESSAGE
3s          Warning   Unhealthy   pod/my-ag-ui-app-766bbdbf65-vqvvg   Readiness probe failed: HTTP probe failed with statuscode: 404
10s         Warning   Unhealthy   pod/my-ag-ui-app-766bbdbf65-vqvvg   Liveness probe failed: HTTP probe failed with statuscode: 404
Name:             my-ag-ui-app-766bbdbf65-vqvvg
Namespace:        default
Priority:         0
Service Account:  default
Node:             my-ag-ui-app-k8s/10.237.212.68
Start Time:       Tue, 07 Apr 2026 14:08:53 -0400
Labels:           app=my-ag-ui-app
                  pod-template-hash=766bbdbf65
Annotations:      cni.projectcalico.org/containerID: bc5fcfbb5dd337044560ca2c007f54d102d4cde58270eed8896d591953d63232
                  cni.projectcalico.org/podIP: 10.1.217.1/32
                  cni.projectcalico.org/podIPs: 10.1.217.1/32
                  kubectl.kubernetes.io/restartedAt: 2026-04-07T14:08:52-04:00
Status:           Running
IP:               10.1.217.1
IPs:
  IP:           10.1.217.1
Controlled By:  ReplicaSet/my-ag-ui-app-766bbdbf65
Containers:
  my-ag-ui-app:
    Container ID:   containerd://52ac3f29566dcde17cdb554aa1b1adf397b3c559262abb66f1e403d98d9188d2
    Image:          localhost:32000/my-ag-ui-app:latest
    Image ID:       localhost:32000/my-ag-ui-app@sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f
    Port:           3000/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Tue, 07 Apr 2026 14:09:43 -0400
    Last State:     Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Tue, 07 Apr 2026 14:08:53 -0400
      Finished:     Tue, 07 Apr 2026 14:09:43 -0400
    Ready:          False
    Restart Count:  1
    Limits:
      cpu:     500m
      memory:  512Mi
    Requests:
      cpu:      100m
      memory:   256Mi
    Liveness:   http-get http://:3000/api/health delay=30s timeout=5s period=10s #success=1 #failure=3
    Readiness:  http-get http://:3000/api/health delay=5s timeout=3s period=5s #success=1 #failure=3
    Environment:
      OPENAI_API_KEY:      <set to the key 'openai-api-key' in secret 'my-ag-ui-app-secrets'>         Optional: false
      OPENAI_BASE_URL:     <set to the key 'openai-base-url' in secret 'my-ag-ui-app-secrets'>        Optional: false
      OPENAI_MODEL:        <set to the key 'openai-model' in secret 'my-ag-ui-app-secrets'>           Optional: false
      EMBEDDING_MODEL:     <set to the key 'embedding-model' in secret 'my-ag-ui-app-secrets'>        Optional: false
      LOGFIRE_TOKEN:       <set to the key 'logfire-token' in secret 'my-ag-ui-app-secrets'>          Optional: false
      LLM_MAX_TOKENS:      <set to the key 'llm-max-tokens' of config map 'my-ag-ui-app-config'>      Optional: false
      LLM_CONTEXT_WINDOW:  <set to the key 'llm-context-window' of config map 'my-ag-ui-app-config'>  Optional: false
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-hkpp7 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  kube-api-access-hkpp7:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  62s                default-scheduler  Successfully assigned default/my-ag-ui-app-766bbdbf65-vqvvg to my-ag-ui-app-k8s
  Normal   Pulled     62s                kubelet            Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 102ms (102ms including waiting). Image size: 263041608 bytes.
  Normal   Pulling    12s (x2 over 62s)  kubelet            Pulling image "localhost:32000/my-ag-ui-app:latest"
  Normal   Created    12s (x2 over 62s)  kubelet            Created container: my-ag-ui-app
  Normal   Started    12s (x2 over 62s)  kubelet            Started container my-ag-ui-app
  Warning  Unhealthy  12s (x3 over 32s)  kubelet            Liveness probe failed: HTTP probe failed with statuscode: 404
  Normal   Killing    12s                kubelet            Container my-ag-ui-app failed liveness probe, will be restarted
  Normal   Pulled     12s                kubelet            Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 90ms (90ms including waiting). Image size: 263041608 bytes.
  Warning  Unhealthy  5s (x11 over 55s)  kubelet            Readiness probe failed: HTTP probe failed with statuscode: 404
[2026-04-07 14:09:55] ERROR: === CONTAINER LOGS (for debugging) ===
▲ Next.js 16.1.0
- Local:         http://my-ag-ui-app-766bbdbf65-vqvvg:3000
- Network:       http://my-ag-ui-app-766bbdbf65-vqvvg:3000

✓ Starting...
✓ Ready in 168ms
[2026-04-07 14:09:55] ERROR: === END CONTAINER LOGS ===
[2026-04-07 14:09:55] ERROR: === PREVIOUS CONTAINER LOGS (if available) ===
▲ Next.js 16.1.0
- Local:         http://my-ag-ui-app-766bbdbf65-vqvvg:3000
- Network:       http://my-ag-ui-app-766bbdbf65-vqvvg:3000

✓ Starting...
✓ Ready in 116ms
[2026-04-07 14:09:55] ERROR: === END PREVIOUS CONTAINER LOGS ===
2026-04-07 14:09:55 - Container status details:
[{"allocatedResources":{"cpu":"100m","memory":"256Mi"},"containerID":"containerd://52ac3f29566dcde17cdb554aa1b1adf397b3c559262abb66f1e403d98d9188d2","image":"localhost:32000/my-ag-ui-app:latest","imageID":"localhost:32000/my-ag-ui-app@sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f","lastState":{"terminated":{"containerID":"containerd://aeecbcdb4b366a7b99be9b5b76844de98e8c6d237c4e2767ce71cd26c862a194","exitCode":0,"finishedAt":"2026-04-07T18:09:43Z","reason":"Completed","startedAt":"2026-04-07T18:08:53Z"}},"name":"my-ag-ui-app","ready":false,"resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"restartCount":1,"started":true,"state":{"running":{"startedAt":"2026-04-07T18:09:43Z"}},"volumeMounts":[{"mountPath":"/var/run/secrets/kubernetes.io/serviceaccount","name":"kube-api-access-hkpp7","readOnly":true,"recursiveReadOnly":"Disabled"}]}]2026-04-07 14:09:56 - Testing health check endpoint accessibility...
2026-04-07 14:09:56 - Testing HTTP health check endpoint from within cluster...
<!DOCTYPE html><!--Kmtd7qiqKK1KdAxFjFCI0--><html lang="en"><head><meta charSet="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/><link rel="stylesheet" href="/_next/static/chunks/580c672ba41ef531.css" data-precedence="next"/><link rel="preload" as="script" fetchPriority="low" href="/_next/static/chunks/9f7c91181cf10269.js"/><script src="/_next/static/chunks/81a5dd5ffbf2a323.js" async=""></script><script src="/_next/static/chunks/eb31826f842ed5cc.js" async=""></script><script src="/_next/static/chunks/turbopack-ae70d51303cf8417.js" async=""></script><script src="/_next/static/chunks/98445878ec3e077f.js" async=""></script><script src="/_next/static/chunks/64c2d675816eb5ba.js" async=""></script><script src="/_next/static/chunks/87a5e5464e54428a.js" async=""></script><script src="/_next/static/chunks/915db95d511f2aa4.js" async=""></script><script src="/_next/static/chunks/8d3945c9ea1274d1.js" async=""></script><script src="/_next/static/chunks/570806598ba172cc.js" async=""></script><meta name="robots" content="noindex"/><title>404: This page could not be found.</title><title>Create Next App</title><meta name="description" content="Generated by create next app"/><link rel="icon" href="/favicon.ico?favicon.0b3bf435.ico" sizes="256x256" type="image/x-icon"/><script src="/_next/static/chunks/a6dad97d9634a72d.js" noModule=""></script></head><body class="antialiased"><div hidden=""><!--$--><!--/$--></div><div style="font-family:system-ui,&quot;Segoe UI&quot;,Roboto,Helvetica,Arial,sans-serif,&quot;Apple Color Emoji&quot;,&quot;Segoe UI Emoji&quot;;height:100vh;text-align:center;display:flex;flex-direction:column;align-items:center;justify-content:center"><div><style>body{color:#000;background:#fff;margin:0}.next-error-h1{border-right:1px solid rgba(0,0,0,.3)}@media (prefers-color-scheme:dark){body{color:#fff;background:#000}.next-error-h1{border-right:1px solid rgba(255,255,255,.3)}}</style><h1 class="next-error-h1" style="display:inline-block;margin:0 20px 0 0;padding:0 23px 0 0;font-size:24px;font-weight:500;vertical-align:top;line-height:49px">404</h1><div style="display:inline-block"><h2 style="font-size:14px;font-weight:400;line-height:49px;margin:0">This page could not be found.</h2></div></div></div><!--$--><!--/$--><script src="/_next/static/chunks/9f7c91181cf10269.js" id="_R_" async=""></script><script>(self.__next_f=self.__next_f||[]).push([0])</script><script>self.__next_f.push([1,"1:\"$Sreact.fragment\"\n2:I[563542,[\"/_next/static/chunks/98445878ec3e077f.js\",\"/_next/static/chunks/64c2d675816eb5ba.js\",\"/_next/static/chunks/87a5e5464e54428a.js\",\"/_next/static/chunks/915db95d511f2aa4.js\",\"/_next/static/chunks/8d3945c9ea1274d1.js\"],\"CopilotKit\"]\n3:I[339756,[\"/_next/static/chunks/570806598ba172cc.js\"],\"default\"]\n4:I[837457,[\"/_next/static/chunks/570806598ba172cc.js\"],\"default\"]\n5:I[897367,[\"/_next/static/chunks/570806598ba172cc.js\"],\"OutletBoundary\"]\n6:\"$Sreact.suspense\"\n8:I[897367,[\"/_next/static/chunks/570806598ba172cc.js\"],\"ViewportBoundary\"]\na:I[897367,[\"/_next/static/chunks/570806598ba172cc.js\"],\"MetadataBoundary\"]\nc:I[168027,[\"/_next/static/chunks/570806598ba172cc.js\"],\"default\"]\n:HL[\"/_next/static/chunks/580c672ba41ef531.css\",\"style\"]\n"])</script><script>self.__next_f.push([1,"0:{\"P\":null,\"b\":\"Kmtd7qiqKK1KdAxFjFCI0\",\"c\":[\"\",\"_not-found\"],\"q\":\"\",\"i\":false,\"f\":[[[\"\",{\"children\":[\"/_not-found\",{\"children\":[\"__PAGE__\",{}]}]},\"$undefined\",\"$undefined\",true],[[\"$\",\"$1\",\"c\",{\"children\":[[[\"$\",\"link\",\"0\",{\"rel\":\"stylesheet\",\"href\":\"/_next/static/chunks/580c672ba41ef531.css\",\"precedence\":\"next\",\"crossOrigin\":\"$undefined\",\"nonce\":\"$undefined\"}],[\"$\",\"script\",\"script-0\",{\"src\":\"/_next/static/chunks/98445878ec3e077f.js\",\"async\":true,\"nonce\":\"$undefined\"}],[\"$\",\"script\",\"script-1\",{\"src\":\"/_next/static/chunks/64c2d675816eb5ba.js\",\"async\":true,\"nonce\":\"$undefined\"}],[\"$\",\"script\",\"script-2\",{\"src\":\"/_next/static/chunks/87a5e5464e54428a.js\",\"async\":true,\"nonce\":\"$undefined\"}],[\"$\",\"script\",\"script-3\",{\"src\":\"/_next/static/chunks/915db95d511f2aa4.js\",\"async\":true,\"nonce\":\"$undefined\"}],[\"$\",\"script\",\"script-4\",{\"src\":\"/_next/static/chunks/8d3945c9ea1274d1.js\",\"async\":true,\"nonce\":\"$undefined\"}]],[\"$\",\"html\",null,{\"lang\":\"en\",\"children\":[\"$\",\"body\",null,{\"className\":\"antialiased\",\"children\":[\"$\",\"$L2\",null,{\"runtimeUrl\":\"/api/copilotkit\",\"agent\":\"my_agent\",\"showDevConsole\":false,\"enableInspector\":false,\"children\":[\"$\",\"$L3\",null,{\"parallelRouterKey\":\"children\",\"error\":\"$undefined\",\"errorStyles\":\"$undefined\",\"errorScripts\":\"$undefined\",\"template\":[\"$\",\"$L4\",null,{}],\"templateStyles\":\"$undefined\",\"templateScripts\":\"$undefined\",\"notFound\":[[[\"$\",\"title\",null,{\"children\":\"404: This page could not be found.\"}],[\"$\",\"div\",null,{\"style\":{\"fontFamily\":\"system-ui,\\\"Segoe UI\\\",Roboto,Helvetica,Arial,sans-serif,\\\"Apple Color Emoji\\\",\\\"Segoe UI Emoji\\\"\",\"height\":\"100vh\",\"textAlign\":\"center\",\"display\":\"flex\",\"flexDirection\":\"column\",\"alignItems\":\"center\",\"justifyContent\":\"center\"},\"children\":[\"$\",\"div\",null,{\"children\":[[\"$\",\"style\",null,{\"dangerouslySetInnerHTML\":{\"__html\":\"body{color:#000;background:#fff;margin:0}.next-error-h1{border-right:1px solid rgba(0,0,0,.3)}@media (prefers-color-scheme:dark){body{color:#fff;background:#000}.next-error-h1{border-right:1px solid rgba(255,255,255,.3)}}\"}}],[\"$\",\"h1\",null,{\"className\":\"next-error-h1\",\"style\":{\"display\":\"inline-block\",\"margin\":\"0 20px 0 0\",\"padding\":\"0 23px 0 0\",\"fontSize\":24,\"fontWeight\":500,\"verticalAlign\":\"top\",\"lineHeight\":\"49px\"},\"children\":404}],[\"$\",\"div\",null,{\"style\":{\"display\":\"inline-block\"},\"children\":[\"$\",\"h2\",null,{\"style\":{\"fontSize\":14,\"fontWeight\":400,\"lineHeight\":\"49px\",\"margin\":0},\"children\":\"This page could not be found.\"}]}]]}]}]],[]],\"forbidden\":\"$undefined\",\"unauthorized\":\"$undefined\"}]}]}]}]]}],{\"children\":[[\"$\",\"$1\",\"c\",{\"children\":[null,[\"$\",\"$L3\",null,{\"parallelRouterKey\":\"children\",\"error\":\"$undefined\",\"errorStyles\":\"$undefined\",\"errorScripts\":\"$undefined\",\"template\":[\"$\",\"$L4\",null,{}],\"templateStyles\":\"$undefined\",\"templateScripts\":\"$undefined\",\"notFound\":\"$undefined\",\"forbidden\":\"$undefined\",\"unauthorized\":\"$undefined\"}]]}],{\"children\":[[\"$\",\"$1\",\"c\",{\"children\":[[[\"$\",\"title\",null,{\"children\":\"404: This page could not be found.\"}],[\"$\",\"div\",null,{\"style\":\"$0:f:0:1:0:props:children:1:props:children:props:children:props:children:props:notFound:0:1:props:style\",\"children\":[\"$\",\"div\",null,{\"children\":[[\"$\",\"style\",null,{\"dangerouslySetInnerHTML\":{\"__html\":\"body{color:#000;background:#fff;margin:0}.next-error-h1{border-right:1px solid rgba(0,0,0,.3)}@media (prefers-color-scheme:dark){body{color:#fff;background:#000}.next-error-h1{border-right:1px solid rgba(255,255,255,.3)}}\"}}],[\"$\",\"h1\",null,{\"className\":\"next-error-h1\",\"style\":\"$0:f:0:1:0:props:children:1:props:children:props:children:props:children:props:notFound:0:1:props:children:props:children:1:props:style\",\"children\":404}],[\"$\",\"div\",null,{\"style\":\"$0:f:0:1:0:props:children:1:props:children:props:children:props:children:props:notFound:0:1:props:children:props:children:2:props:style\",\"children\":[\"$\",\"h2\",null,{\"style\":\"$0:f:0:1:0:props:children:1:props:children:props:children:props:children:props:notFound:0:1:props:children:props:children:2:props:children:props:style\",\"children\":\"This page could not be found.\"}]}]]}]}]],null,[\"$\",\"$L5\",null,{\"children\":[\"$\",\"$6\",null,{\"name\":\"Next.MetadataOutlet\",\"children\":\"$@7\"}]}]]}],{},null,false,false]},null,false,false]},null,false,false],[\"$\",\"$1\",\"h\",{\"children\":[[\"$\",\"meta\",null,{\"name\":\"robots\",\"content\":\"noindex\"}],[\"$\",\"$L8\",null,{\"children\":\"$L9\"}],[\"$\",\"div\",null,{\"hidden\":true,\"children\":[\"$\",\"$La\",null,{\"children\":[\"$\",\"$6\",null,{\"name\":\"Next.Metadata\",\"children\":\"$Lb\"}]}]}],null]}],false]],\"m\":\"$undefined\",\"G\":[\"$c\",\"$undefined\"],\"S\":true}\n"])</script><script>self.__next_f.push([1,"9:[[\"$\",\"meta\",\"0\",{\"charSet\":\"utf-8\"}],[\"$\",\"meta\",\"1\",{\"name\":\"viewport\",\"content\":\"width=device-width, initial-scale=1\"}]]\n"])</script><script>self.__next_f.push([1,"d:I[27201,[\"/_next/static/chunks/570806598ba172cc.js\"],\"IconMark\"]\n7:null\nb:[[\"$\",\"title\",\"0\",{\"children\":\"Create Next App\"}],[\"$\",\"meta\",\"1\",{\"name\":\"description\",\"content\":\"Generated by create next app\"}],[\"$\",\"link\",\"2\",{\"rel\":\"icon\",\"href\":\"/favicon.ico?favicon.0b3bf435.ico\",\"sizes\":\"256x256\",\"type\":\"image/x-icon\"}],[\"$\",\"$Ld\",\"3\",{}]]\n"])</script></body></html>pod "temp-health-test" deleted
[2026-04-07 14:09:59] ══════════════════════════════════════════════════════════════════════════════
[2026-04-07 14:09:59]                          STRUCTURED ERROR
[2026-04-07 14:09:59] ══════════════════════════════════════════════════════════════════════════════
[2026-04-07 14:09:59] ERROR TYPE: READINESS_PROBE_TIMEOUT
[2026-04-07 14:09:59] DIAGNOSTIC: Readiness probe did not pass within 5-minute timeout
[2026-04-07 14:09:59] COMMON CAUSES: Application not ready to serve traffic, health check endpoint not responding, or application startup issues
[2026-04-07 14:09:59] RECOVERY: 1. Check application logs: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl logs -l app=my-ag-ui-app, 2. Verify health check endpoint: curl http://<pod-ip>:3000/api/health, 3. Check deployment manifest for correct probe configuration, 4. Verify application is properly starting and not crashing
[2026-04-07 14:09:59] ══════════════════════════════════════════════════════════════════════════════
[2026-04-07 14:09:59] ERROR: ❌ READINESS PROBE VERIFICATION FAILED: Application not ready to serve traffic
[2026-04-07 14:09:59] ══════════════════════════════════════════════════════════════════════════════
[2026-04-07 14:09:59]                          STRUCTURED ERROR
[2026-04-07 14:09:59] ══════════════════════════════════════════════════════════════════════════════
[2026-04-07 14:09:59] ERROR TYPE: READINESS_PROBE_FAILURE
[2026-04-07 14:09:59] DIAGNOSTIC: Readiness probe verification failed
[2026-04-07 14:09:59] COMMON CAUSES: Application failed readiness probe verification and is not ready to serve traffic
[2026-04-07 14:09:59] RECOVERY: 1. Check application logs: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl logs -l app=my-ag-ui-app, 2. Verify health check endpoint: curl http://<pod-ip>:3000/api/health, 3. Check deployment manifest probe configuration, 4. Verify application is properly starting and not crashing
[2026-04-07 14:09:59] ══════════════════════════════════════════════════════════════════════════════
2026-04-07 14:09:59 - === DETAILED POD INFORMATION FOR READINESS FAILURE ===
[2026-04-07 14:09:59] ERROR: ❌ STEP 6 FAILED: Failed to deploy to Kubernetes
[2026-04-07 14:09:59] ERROR: 🔄 INITIATING ROLLBACK PROCEDURE
[2026-04-07 14:09:59] ERROR: Deployment failed - attempting to restore previous state
[2026-04-07 14:09:59] ERROR: ❌ ROLLBACK FAILED: No backup deployment manifest found (k8s/deployment.yaml.backup)
[2026-04-07 14:09:59] ERROR:    Cannot perform automatic rollback - manual intervention required
