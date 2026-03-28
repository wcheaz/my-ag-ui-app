Log file created: /tmp/deploy-20260328-185140.log
[2026-03-28 18:51:40] INFO: Log file initialized: /tmp/deploy-20260328-185140.log
[2026-03-28 18:51:40] INFO: Starting log cleanup process
[2026-03-28 18:51:40] INFO: Found 13 deployment log files to check
[2026-03-28 18:51:40] INFO: Removing 3 old log files (keeping last 10)
[2026-03-28 18:51:40] INFO: Removed old log file: /tmp/deploy-20260328-161536.log
[2026-03-28 18:51:40] INFO: Removed old log file: /tmp/deploy-20260328-161535.log
[2026-03-28 18:51:40] INFO: Removed old log file: /tmp/deploy-20260328-161528.log
[2026-03-28 18:51:40] INFO: Log cleanup process completed
[2026-03-28 18:51:40] INFO: 🚀 STARTING DEPLOYMENT PIPELINE
[2026-03-28 18:51:40] INFO: Environment: development
[2026-03-28 18:51:40] INFO: Verbose mode: false
[2026-03-28 18:51:40] INFO: 📋 Step 1: Setting up Kubernetes secrets...
Log file created: /tmp/deploy-20260328-185140.log
[2026-03-28 18:51:40] INFO: Log file initialized: /tmp/deploy-20260328-185140.log
[2026-03-28 18:51:40] INFO: Starting Kubernetes secrets setup...
[2026-03-28 18:51:40] INFO: k8s directory found: /home/ncheaz/git/my-ag-ui-app/k8s/
[2026-03-28 18:51:40] INFO: setup-secrets.sh script found: /home/ncheaz/git/my-ag-ui-app/k8s/setup-secrets.sh
[2026-03-28 18:51:40] INFO: Setting up environment variables for secrets creation...
[2026-03-28 18:51:40] INFO: Loading environment variables from .env file...
[2026-03-28 18:51:40] INFO: Set environment variable: OPENAI_API_KEY
[2026-03-28 18:51:40] INFO: Set environment variable: OPENAI_BASE_URL
[2026-03-28 18:51:40] INFO: Set environment variable: OPENAI_MODEL
[2026-03-28 18:51:40] INFO: Set environment variable: LLM_MAX_TOKENS
[2026-03-28 18:51:40] INFO: Set environment variable: LLM_CONTEXT_WINDOW
[2026-03-28 18:51:40] INFO: Set environment variable: EMBEDDING_MODEL
[2026-03-28 18:51:40] INFO: All required environment variables are set
[2026-03-28 18:51:40] INFO: Running secrets setup script to generate YAML file...
[2026-03-28 18:51:40] Setting up Kubernetes secrets...
[2026-03-28 18:51:40] Reading environment variables...
[2026-03-28 18:51:40] Encoding values to base64...
[2026-03-28 18:51:40] Generating Kubernetes secrets file...
[2026-03-28 18:51:40] Validating generated secrets file against Kubernetes API server...
secret/my-ag-ui-app-secrets unchanged (server dry run)
configmap/my-ag-ui-app-config unchanged (server dry run)
[2026-03-28 18:51:41] ✅ Kubernetes secrets file generated successfully: k8s/secrets.yaml
[2026-03-28 18:51:41] INFO: Kubernetes secrets YAML file generated successfully: k8s/secrets.yaml
[2026-03-28 18:51:41] INFO: Copying secrets file to VM for Kubernetes operations...
[2026-03-28 18:51:41] INFO: Secrets file copied to VM successfully
[2026-03-28 18:51:41] INFO: Validating secrets YAML against Kubernetes API server...
secret/my-ag-ui-app-secrets unchanged (server dry run)
configmap/my-ag-ui-app-config unchanged (server dry run)
[2026-03-28 18:51:41] INFO: Secrets YAML validation passed
[2026-03-28 18:51:41] INFO: Applying secrets to Kubernetes cluster...
secret/my-ag-ui-app-secrets unchanged
configmap/my-ag-ui-app-config unchanged
[2026-03-28 18:51:42] INFO: Kubernetes secrets setup completed successfully
[2026-03-28 18:51:42] INFO: ✅ Step 1: Kubernetes secrets setup completed
[2026-03-28 18:51:42] INFO: 📋 Step 2: Building Docker image...
[2026-03-28 18:51:42] INFO: Starting Docker build process
[2026-03-28 18:51:42] Starting dependency validation...
[2026-03-28 18:51:42] Checking if package.json and package-lock.json are in sync...
[2026-03-28 18:51:43] ✅ SUCCESS: package.json and package-lock.json are synchronized
[2026-03-28 18:51:43]    Dependencies are ready for reproducible Docker builds.
[2026-03-28 18:51:43] INFO: Starting Docker image build for 'my-ag-ui-app:latest'...
[2026-03-28 18:52:25] INFO: Docker build completed successfully
[2026-03-28 18:52:25] INFO: Build output:
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 4.79kB done
#1 DONE 0.0s

#2 [internal] load metadata for docker.io/library/node:20.12.0-alpine
#2 DONE 0.2s

#3 [internal] load .dockerignore
#3 transferring context: 128B done
#3 DONE 0.0s

#4 [builder 1/6] FROM docker.io/library/node:20.12.0-alpine@sha256:ef3f47741e161900ddd07addcaca7e76534a9205e4cd73b2ed091ba339004a75
#4 DONE 0.0s

#5 [internal] load build context
#5 transferring context: 72.63kB 0.0s done
#5 DONE 0.0s

#6 [builder 2/6] WORKDIR /app
#6 CACHED

#7 [builder 3/6] COPY package.json package-lock.json ./
#7 CACHED

#8 [builder 4/6] RUN echo "=== DEPENDENCY INSTALLATION ===" &&     echo "Starting npm ci (reproducible install)..." &&     if npm ci --ignore-scripts; then         echo "✅ SUCCESS: npm ci completed - using reproducible dependencies from lock file";     else         echo "⚠️  WARNING: npm ci failed - lock files are out of sync";         echo "🔄 FALLING BACK to npm install to continue build...";         echo "ℹ️  NOTE: This allows deployment but reduces build reproducibility";         echo "🔧 FIX: Run 'npm install' locally and commit updated package-lock.json";         npm install --ignore-scripts;         echo "✅ SUCCESS: npm install completed - build continuing with fallback dependencies";     fi &&     echo "=== DEPENDENCY INSTALLATION COMPLETED ===" &&     npm cache clean --force
#8 CACHED

#9 [builder 5/6] COPY . .
#9 DONE 0.3s

#10 [builder 6/6] RUN npm run build
#10 0.357 
#10 0.357 > pydantic-ai-starter@0.1.0 build
#10 0.357 > next build
#10 0.357 
#10 0.910 Attention: Next.js now collects completely anonymous telemetry regarding usage.
#10 0.910 This information is used to shape Next.js' roadmap and prioritize features.
#10 0.910 You can learn more, including how to opt-out if you'd not like to participate in this anonymous program, by visiting the following URL:
#10 0.910 https://nextjs.org/telemetry
#10 0.910 
#10 0.920 ▲ Next.js 16.1.0 (Turbopack)
#10 0.920 
#10 0.975   Creating an optimized production build ...
#10 31.32 ✓ Compiled successfully in 30.0s
#10 31.33   Running TypeScript ...
#10 34.62   Collecting page data using 11 workers ...
#10 35.86   Generating static pages using 11 workers (0/6) ...
#10 36.07   Generating static pages using 11 workers (1/6) 
#10 36.50   Generating static pages using 11 workers (2/6) 
#10 36.52   Generating static pages using 11 workers (4/6) 
#10 37.07 ✓ Generating static pages using 11 workers (6/6) in 1205.6ms
#10 37.07   Finalizing page optimization ...
#10 37.24 
#10 37.24 Route (app)
#10 37.24 ┌ ○ /
#10 37.24 ├ ○ /_not-found
#10 37.24 ├ ƒ /api/copilotkit
#10 37.24 └ ƒ /api/health
#10 37.24 
#10 37.24 
#10 37.24 ○  (Static)   prerendered as static content
#10 37.24 ƒ  (Dynamic)  server-rendered on demand
#10 37.24 
#10 DONE 37.7s

#11 [runner 3/6] RUN addgroup --system --gid 1001 nodejs &&     adduser --system --uid 1001 nextjs
#11 CACHED

#12 [runner 4/6] COPY --from=builder /app/public ./public
#12 CACHED

#13 [runner 5/6] COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
#13 DONE 0.6s

#14 [runner 6/6] COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
#14 DONE 0.1s

#15 exporting to image
#15 exporting layers
#15 exporting layers 0.8s done
#15 writing image sha256:6b93723146bd69cd65eb1f946a1958b9aa485f682eb97e26117f1ee69520674d done
#15 naming to docker.io/library/my-ag-ui-app:latest done
#15 DONE 0.8s

View build details: docker-desktop://dashboard/build/default/default/mqanfgo4d2x76ze3qp754raf9
[2026-03-28 18:52:25] INFO: Build: Docker image built successfully (no detailed build summary available)
[2026-03-28 18:52:25] INFO: Docker image 'my-ag-ui-app:latest' built successfully
[2026-03-28 18:52:25] INFO: Docker image 'my-ag-ui-app:latest' verified successfully
[2026-03-28 18:52:25] INFO: Docker build process completed successfully
[2026-03-28 18:52:25] INFO: ✅ Step 2: Docker image build completed
[2026-03-28 18:52:25] INFO: 📋 Step 3: Tagging Docker image...
[2026-03-28 18:52:25] INFO: Starting Docker image tagging for local registry...
[2026-03-28 18:52:25] INFO: Using comprehensive tagging function with validation and error handling...
Untagged: localhost:32000/my-ag-ui-app:latest
[2026-03-28 18:52:26] Verifying tagged image exists after successful tagging...
[2026-03-28 18:52:26] ✅ Image tagging verification successful within VM
[2026-03-28 18:52:26]    Target tag localhost:32000/my-ag-ui-app:latest exists and is accessible within VM
[2026-03-28 18:52:27] ✅ Image ID verification successful - both images reference the same underlying image within VM
[2026-03-28 18:52:27] INFO: ✅ Docker image tagging for registry completed with comprehensive validation
[2026-03-28 18:52:27] INFO:    Image successfully tagged as: localhost:32000/my-ag-ui-app:latest
[2026-03-28 18:52:27] INFO: ✅ Step 3: Docker image tagging completed
[2026-03-28 18:52:27] INFO: 📋 Step 4: Setting up Microk8s registry...
Log file created: /tmp/deploy-20260328-185227.log
[2026-03-28 18:52:27] INFO: Log file initialized: /tmp/deploy-20260328-185227.log
[2026-03-28 18:52:27] INFO: 🔶 START: MICROK8S_REGISTRY_SETUP
[2026-03-28 18:52:27] INFO: Starting microk8s registry setup...
[2026-03-28 18:52:27] INFO: 🔶 REGISTRY SETUP: Starting microk8s registry setup process...
[2026-03-28 18:52:27] INFO: Checking microk8s availability...
[2026-03-28 18:52:27] INFO: ✅ microk8s is available in VM
[2026-03-28 18:52:27] INFO: Performing pre-enablement registry connectivity verification...
[2026-03-28 18:52:27] INFO: Performing pre-enablement registry connectivity check...
[2026-03-28 18:52:27] INFO: ✅ PRE-ENABLEMENT VERIFICATION: Registry already accessible
[2026-03-28 18:52:27] INFO:    JSON validation: Valid registry catalog format with repositories field
[2026-03-28 18:52:27] INFO: ✅ PRE-ENABLEMENT VERIFICATION: Registry response format is valid JSON
[2026-03-28 18:52:27] INFO: ✅ Pre-enablement registry connectivity verification completed
[2026-03-28 18:52:27] INFO: Enabling microk8s registry...
[2026-03-28 18:52:27] INFO:    Command: microk8s enable registry
[2026-03-28 18:52:27] INFO:    Executing: timeout 30 multipass exec 'my-ag-ui-app-k8s' -- microk8s enable registry
[2026-03-28 18:52:28] INFO: ✅ microk8s registry enable command completed successfully
[2026-03-28 18:52:28] INFO: Waiting 5 seconds for registry to fully start...
[2026-03-28 18:52:33] INFO: Verifying registry is running and accessible at localhost:32000...
[2026-03-28 18:52:33] INFO: ✅ REGISTRY CONNECTIVITY: SUCCESS
[2026-03-28 18:52:33] INFO:    Response time: .203514270 seconds
[2026-03-28 18:52:33] INFO:    JSON validation: Valid registry catalog format with repositories field
[2026-03-28 18:52:33] INFO: ✅ REGISTRY RESPONSE FORMAT: VALID JSON
[2026-03-28 18:52:33] INFO: ✅ Registry verification completed successfully
[2026-03-28 18:52:33] INFO:    Registry is accessible at: localhost:32000
[2026-03-28 18:52:33] INFO: ✅ REGISTRY SETUP: microk8s registry setup process completed successfully
[2026-03-28 18:52:33] INFO:    Registry status: ENABLED and VERIFIED
[2026-03-28 18:52:33] INFO:    Registry endpoint: localhost:32000
[2026-03-28 18:52:33] INFO:    Setup completed at: 2026-03-28 18:52:33
[2026-03-28 18:52:33] INFO: microk8s registry setup completed successfully
[2026-03-28 18:52:33] INFO: ✅ END: MICROK8S_REGISTRY_SETUP (duration: 6.222151486s)
[2026-03-28 18:52:33] INFO: 🎉 Microk8s registry setup completed successfully!
[2026-03-28 18:52:33] INFO:    Registry is ready for local image distribution
[2026-03-28 18:52:33] INFO:    Next step: Push Docker image to registry
[2026-03-28 18:52:33] INFO: ✅ Step 4: Microk8s registry setup completed
[2026-03-28 18:52:33] INFO: 📋 Step 5: Pushing Docker image...
Log file created: /tmp/deploy-20260328-185233.log
[2026-03-28 18:52:33] INFO: Log file initialized: /tmp/deploy-20260328-185233.log
[2026-03-28 18:52:33] INFO: Starting Docker image push to microk8s registry...
[2026-03-28 18:52:33] INFO: Starting Docker image push to microk8s registry (executing within VM)...
[2026-03-28 18:52:33] Target registry image: localhost:32000/my-ag-ui-app:latest
[2026-03-28 18:52:34] ✅ Registry verification completed successfully
[2026-03-28 18:52:34]    Registry is accessible at: localhost:32000
[2026-03-28 18:52:34] Pushing image to microk8s registry with enhanced retry logic (within VM)...
[2026-03-28 18:52:34]    Command: multipass exec my-ag-ui-app-k8s -- timeout 60 docker push localhost:32000/my-ag-ui-app:latest
[2026-03-28 18:52:34] ✅ Docker push command completed successfully within VM (attempt 1)
[2026-03-28 18:52:34] ✅ Image push completed successfully within VM
[2026-03-28 18:52:34]    Push command output summary:
The push refers to repository [localhost:32000/my-ag-ui-app]
75136c45e7ab: Layer already exists
52a51099bdef: Layer already exists
82fb5a2278a7: Layer already exists
a2cffe5fe30b: Layer already exists
f82bfb71098a: Layer already exists
413c136dedcf: Layer already exists
abc5b1d00820: Layer already exists
8e1fab8d9171: Layer already exists
d4fc045c9e3a: Layer already exists
[2026-03-28 18:52:34]    ... (output truncated, full output logged to file)
[2026-03-28 18:52:34] INFO: Starting image verification with exponential backoff retry logic (1s, 2s, 4s, 8s, 16s, 32s, 64s)...
[2026-03-28 18:52:34] INFO: Image verification attempt 1/7 (delay: 1s) at 2026-03-28 18:52:34
[2026-03-28 18:52:34] INFO: ✅ Image 'my-ag-ui-app:latest' found in registry tags list at 2026-03-28 18:52:34
[2026-03-28 18:52:35] INFO: ✅ Image verification successful - image is available in registry at 2026-03-28 18:52:35
[2026-03-28 18:52:35] INFO: ✅ Docker image push to microk8s registry completed successfully within VM at 2026-03-28 18:52:35
[2026-03-28 18:52:35] INFO:    Image: localhost:32000/my-ag-ui-app:latest
[2026-03-28 18:52:35] INFO:    Status: PUSHED and VERIFIED
[2026-03-28 18:52:35] INFO:    Registry: http://localhost:32000 (within VM)
[2026-03-28 18:52:35] INFO:    Ready for: Kubernetes deployment using registry image reference
[2026-03-28 18:52:35]    Status: PUSHED and VERIFIED (or verification pending)
[2026-03-28 18:52:35]    Registry: http://localhost:32000 (within VM)
[2026-03-28 18:52:35]    Ready for: Kubernetes deployment using registry image reference
[2026-03-28 18:52:35] INFO: ✅ Docker image push to microk8s registry completed successfully
[2026-03-28 18:52:35] INFO: ✅ Step 5: Docker image push completed
[2026-03-28 18:52:35] INFO: 📋 Step 6: Deploying to Kubernetes...
2026-03-28 18:52:35 - DEBUG: Running with full verbose output (critical failure phase)
2026-03-28 18:52:35 - DEBUG: Set DEBUG=all for explicit debugging if needed
2026-03-28 18:52:35 - Starting phase: KUBERNETES_DEPLOYMENT
[2026-03-28 18:52:35] INFO: 🚀 STARTING KUBERNETES DEPLOYMENT PHASE
[2026-03-28 18:52:35] INFO: ═══════════════════════════════════════════════════════════════════════════════
2026-03-28 18:52:35 - 📋 DEPLOYMENT DETAILS:
2026-03-28 18:52:35 -    • Manifest: k8s/deployment.yaml
2026-03-28 18:52:35 -    • Image: localhost:32000/my-ag-ui-app:latest (from local registry)
2026-03-28 18:52:35 -    • Strategy: Rolling update with pod restart
2026-03-28 18:52:35 -    • Registry: microk8s local registry
2026-03-28 18:52:35 - 
[2026-03-28 18:52:35] INFO: 🔄 STEP 1: Applying deployment manifest...
[2026-03-28 18:52:35] INFO:    • Manifest: k8s/deployment.yaml
[2026-03-28 18:52:35] INFO:    • Image: localhost:32000/my-ag-ui-app:latest (from local registry)
[2026-03-28 18:52:35] INFO:    • Strategy: Rolling update with pod restart
[2026-03-28 18:52:35] INFO:    • Registry: microk8s local registry
[2026-03-28 18:52:35] INFO: 
2026-03-28 18:52:35 - 📊 PRE-APPLOY VERIFICATION: Checking current deployment state...
2026-03-28 18:52:36 -    • Current deployment state: EXISTS
2026-03-28 18:52:36 -    • Current replicas: 1
2026-03-28 18:52:36 -    • Ready replicas: 
2026-03-28 18:52:36 -    • Updated replicas: 1
2026-03-28 18:52:36 -    • Action: UPDATE existing deployment
2026-03-28 18:52:36 - 📋 MANIFEST VALIDATION: Checking deployment.yaml file...
2026-03-28 18:52:36 - 🔍 REGISTRY PORT VALIDATION: Checking for registry port mismatches...
2026-03-28 18:52:36 -    ✓ Registry port validation: PASSED (using port 32000)
2026-03-28 18:52:36 -    • Manifest file size: 116 lines
2026-03-28 18:52:36 -    • Manifest validation: PASSED
2026-03-28 18:52:36 - 🔌 KUBERNETES CONNECTION: Verifying cluster access...
2026-03-28 18:52:36 -    • Kubernetes cluster: ACCESSIBLE
2026-03-28 18:52:36 - 🏷️  NAMESPACE VERIFICATION: Checking target namespace...
2026-03-28 18:52:36 -    • Target namespace: default
2026-03-28 18:52:36 -    • Namespace status: EXISTS and ACTIVE
2026-03-28 18:52:36 - 🚀 APPLYING DEPLOYMENT MANIFEST with detailed logging...
2026-03-28 18:52:36 -    • First validating deployment manifest with dry-run...
2026-03-28 18:52:36 -    • Command: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl apply --dry-run=server -f k8s/deployment.yaml
2026-03-28 18:52:36 -    • Expected: Validation against Kubernetes API server
[2026-03-28 18:52:36] INFO: Starting deployment manifest validation using kubectl apply --dry-run=server...
deployment.apps/my-ag-ui-app unchanged (server dry run)
[2026-03-28 18:52:37] INFO: ✅ Deployment manifest validation successful
2026-03-28 18:52:37 -    • Validation passed, proceeding with actual deployment...
2026-03-28 18:52:37 -    • Command: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl apply -f k8s/deployment.yaml
2026-03-28 18:52:37 -    • Expected: Deployment resource creation/update
2026-03-28 18:52:37 -    • Output will be captured and analyzed below...
2026-03-28 18:52:37 - 📤 KUBECTL APPLY OUTPUT (first 1000 chars):
deployment.apps/my-ag-ui-app unchanged
2026-03-28 18:52:37 - ✅ KUBECTL APPLY: Command completed successfully (exit code: 0)
2026-03-28 18:52:37 -    • Result: Deployment unchanged (no changes detected)
2026-03-28 18:52:37 -    • Action: No update needed - configuration identical
2026-03-28 18:52:37 - 🔍 POST-APPLY VERIFICATION: Checking deployment status after apply...
2026-03-28 18:52:37 -    ✅ Deployment verification: PASSED
2026-03-28 18:52:37 -       • Deployment resource exists: my-ag-ui-app
2026-03-28 18:52:38 -       • Deployment spec: {"progressDeadlineSeconds":600,"replicas":1,"revisionHistoryLimit":10,"selector":{"matchLabels":{"app":"my-ag-ui-app"}},"strategy":{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"},"template":{"metadata":{"annotations":{"kubectl.kubernetes.io/restartedAt":"2026-03-28T18:38:55-04:00"},"creationTimestamp":null,"labels":{"app":"my-ag-ui-app"}},"spec":{"containers":[{"env":[{"name":"OPENAI_API_KEY","valueFrom":{"secretKeyRef":{"key":"openai-api-key","name":"my-ag-ui-app-secrets"}}},{"name":"OPENAI_BASE_URL","valueFrom":{"secretKeyRef":{"key":"openai-base-url","name":"my-ag-ui-app-secrets"}}},{"name":"OPENAI_MODEL","valueFrom":{"secretKeyRef":{"key":"openai-model","name":"my-ag-ui-app-secrets"}}},{"name":"EMBEDDING_MODEL","valueFrom":{"secretKeyRef":{"key":"embedding-model","name":"my-ag-ui-app-secrets"}}},{"name":"LOGFIRE_TOKEN","valueFrom":{"secretKeyRef":{"key":"logfire-token","name":"my-ag-ui-app-secrets"}}},{"name":"LLM_MAX_TOKENS","valueFrom":{"configMapKeyRef":{"key":"llm-max-tokens","name":"my-ag-ui-app-config"}}},{"name":"LLM_CONTEXT_WINDOW","valueFrom":{"configMapKeyRef":{"key":"llm-context-window","name":"my-ag-ui-app-config"}}}],"image":"localhost:32000/my-ag-ui-app:latest","imagePullPolicy":"Always","livenessProbe":{"failureThreshold":3,"httpGet":{"path":"/api/health","port":3000,"scheme":"HTTP"},"initialDelaySeconds":30,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5},"name":"my-ag-ui-app","ports":[{"containerPort":3000,"name":"http","protocol":"TCP"}],"readinessProbe":{"failureThreshold":3,"httpGet":{"path":"/api/health","port":3000,"scheme":"HTTP"},"initialDelaySeconds":5,"periodSeconds":5,"successThreshold":1,"timeoutSeconds":3},"resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"terminationMessagePath":"/dev/termination-log","terminationMessagePolicy":"File"}],"dnsPolicy":"ClusterFirst","restartPolicy":"Always","schedulerName":"default-scheduler","securityContext":{},"terminationGracePeriodSeconds":30}}}
2026-03-28 18:52:38 -       • Deployment status: {"conditions":[{"lastTransitionTime":"2026-03-25T20:53:24Z","lastUpdateTime":"2026-03-25T20:53:24Z","message":"Deployment does not have minimum availability.","reason":"MinimumReplicasUnavailable","status":"False","type":"Available"},{"lastTransitionTime":"2026-03-28T22:48:56Z","lastUpdateTime":"2026-03-28T22:48:56Z","message":"ReplicaSet \"my-ag-ui-app-5fc4976ff7\" has timed out progressing.","reason":"ProgressDeadlineExceeded","status":"False","type":"Progressing"}],"observedGeneration":32,"replicas":2,"unavailableReplicas":2,"updatedReplicas":1}
2026-03-28 18:52:38 -       ✅ Image reference verification: PASSED
2026-03-28 18:52:38 -          • Expected: localhost:32000/my-ag-ui-app:latest
2026-03-28 18:52:38 -          • Actual: localhost:32000/my-ag-ui-app:latest
2026-03-28 18:52:38 - ✅ Deployment manifest application process completed
2026-03-28 18:52:38 -    • Kubernetes deployment resource processed
2026-03-28 18:52:38 -    • Next step: Deployment restart to trigger pod creation
2026-03-28 18:52:38 - 
2026-03-28 18:52:38 - 🔄 STEP 2: Restarting deployment to trigger pod recreation...
2026-03-28 18:52:38 -    • This will create new pods using the updated registry image
2026-03-28 18:52:38 -    • Pods will pull image from localhost:32000/my-ag-ui-app:latest
deployment.apps/my-ag-ui-app restarted
2026-03-28 18:52:39 - ✅ Deployment restarted successfully
2026-03-28 18:52:39 -    • Rolling update initiated
2026-03-28 18:52:39 -    • New pods will be created using registry image
2026-03-28 18:52:39 -    • Expected: Direct pod startup (no ImagePullBackOff with registry approach)
2026-03-28 18:52:39 - 
[2026-03-28 18:52:39] INFO: Starting pod status polling for Running state (5-second intervals, 5-minute timeout)...
2026-03-28 18:52:39 - Checking pod status for Running state... (attempt 1/60)
[2026-03-28 18:52:39] INFO: ✅ Pod reached Running state successfully
[2026-03-28 18:52:39] INFO: ✅ Pod status polling completed successfully - pod is Running
[2026-03-28 18:52:39] INFO: Capturing Kubernetes pod events for analysis...
[2026-03-28 18:52:40] INFO: Analyzing events for pod: my-ag-ui-app-5fc4976ff7-6nwtb
2026-03-28 18:52:40 - === POD EVENTS ===
LAST SEEN   TYPE      REASON      OBJECT                              MESSAGE
3m32s       Normal    Pulling     pod/my-ag-ui-app-5fc4976ff7-6nwtb   Pulling image "localhost:32000/my-ag-ui-app:latest"
3m26s       Warning   Unhealthy   pod/my-ag-ui-app-5fc4976ff7-6nwtb   Readiness probe failed: HTTP probe failed with statuscode: 404
2026-03-28 18:52:40 - === END POD EVENTS ===
[2026-03-28 18:52:40] INFO: Analyzing specific event types...
[2026-03-28 18:52:42] ERROR: ❌ PROBE FAILURES DETECTED (2 events):
[2026-03-28 18:52:42] ERROR:    Unhealthy events indicate readiness or liveness probe failures
LAST SEEN   TYPE      REASON      OBJECT                              MESSAGE
3m28s       Warning   Unhealthy   pod/my-ag-ui-app-5fc4976ff7-6nwtb   Readiness probe failed: HTTP probe failed with statuscode: 404
[2026-03-28 18:52:43] INFO: === POD EVENTS SUMMARY ===
[2026-03-28 18:52:43] INFO: Pull Errors: 0
[2026-03-28 18:52:43] INFO: Crash Loops: 0
[2026-03-28 18:52:43] INFO: Probe Failures: 2
[2026-03-28 18:52:43] INFO: === END POD EVENTS SUMMARY ===
[2026-03-28 18:52:43] INFO: Detailed pod description for comprehensive debugging:
Name:             my-ag-ui-app-5fc4976ff7-6nwtb
Namespace:        default
Priority:         0
Service Account:  default
Node:             my-ag-ui-app-k8s/10.237.212.68
Start Time:       Sat, 28 Mar 2026 18:38:55 -0400
Labels:           app=my-ag-ui-app
                  pod-template-hash=5fc4976ff7
Annotations:      cni.projectcalico.org/containerID: 336de68d4066302829fec00b076eff3cc21feedd8a1b27c53f7e48f889ecb527
                  cni.projectcalico.org/podIP: 10.1.217.39/32
                  cni.projectcalico.org/podIPs: 10.1.217.39/32
                  kubectl.kubernetes.io/restartedAt: 2026-03-28T18:38:55-04:00
Status:           Running
IP:               10.1.217.39
IPs:
  IP:           10.1.217.39
Controlled By:  ReplicaSet/my-ag-ui-app-5fc4976ff7
Containers:
  my-ag-ui-app:
    Container ID:   containerd://a754435cec1c4054a2c51bdcddc52e96f614db67ec0fc07b7e8a939accbd32a1
    Image:          localhost:32000/my-ag-ui-app:latest
    Image ID:       localhost:32000/my-ag-ui-app@sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f
    Port:           3000/TCP
    Host Port:      0/TCP
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Sat, 28 Mar 2026 18:49:08 -0400
      Finished:     Sat, 28 Mar 2026 18:50:06 -0400
    Ready:          False
    Restart Count:  7
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
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-hjcp9 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  kube-api-access-hjcp9:
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
  Type     Reason     Age                   From     Message
  ----     ------     ----                  ----     -------
  Normal   Pulling    3m35s (x8 over 13m)   kubelet  Pulling image "localhost:32000/my-ag-ui-app:latest"
  Warning  Unhealthy  3m29s (x74 over 13m)  kubelet  Readiness probe failed: HTTP probe failed with statuscode: 404
[2026-03-28 18:52:43] ERROR: === CONTAINER LOGS (for debugging) ===
▲ Next.js 16.1.0
- Local:         http://my-ag-ui-app-5fc4976ff7-6nwtb:3000
- Network:       http://my-ag-ui-app-5fc4976ff7-6nwtb:3000

✓ Starting...
✓ Ready in 116ms
[2026-03-28 18:52:43] ERROR: === END CONTAINER LOGS ===
[2026-03-28 18:52:43] ERROR: === PREVIOUS CONTAINER LOGS (if available) ===
▲ Next.js 16.1.0
- Local:         http://my-ag-ui-app-5fc4976ff7-6nwtb:3000
- Network:       http://my-ag-ui-app-5fc4976ff7-6nwtb:3000

✓ Starting...
✓ Ready in 116ms
[2026-03-28 18:52:44] ERROR: === END PREVIOUS CONTAINER LOGS ===
[2026-03-28 18:52:44] INFO: Starting readiness probe verification...
[2026-03-28 18:52:44] INFO: Verifying readiness probe passes before marking deployment successful...
2026-03-28 18:52:44 - Checking readiness probe status... (attempt 1/60)
[2026-03-28 18:52:44] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:52:49 - Checking readiness probe status... (attempt 2/60)
[2026-03-28 18:52:49] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:52:54 - Checking readiness probe status... (attempt 3/60)
[2026-03-28 18:52:55] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:53:00 - Checking readiness probe status... (attempt 4/60)
[2026-03-28 18:53:00] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:53:05 - Checking readiness probe status... (attempt 5/60)
[2026-03-28 18:53:05] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:53:10 - Checking readiness probe status... (attempt 6/60)
[2026-03-28 18:53:11] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:53:16 - Checking readiness probe status... (attempt 7/60)
[2026-03-28 18:53:16] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:53:21 - Checking readiness probe status... (attempt 8/60)
[2026-03-28 18:53:21] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:53:26 - Checking readiness probe status... (attempt 9/60)
[2026-03-28 18:53:27] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:53:32 - Checking readiness probe status... (attempt 10/60)
[2026-03-28 18:53:32] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:53:37 - Checking readiness probe status... (attempt 11/60)
[2026-03-28 18:53:37] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:53:42 - Checking readiness probe status... (attempt 12/60)
[2026-03-28 18:53:43] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:53:48 - Checking readiness probe status... (attempt 13/60)
[2026-03-28 18:53:48] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:53:53 - Checking readiness probe status... (attempt 14/60)
[2026-03-28 18:53:53] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:53:58 - Checking readiness probe status... (attempt 15/60)
[2026-03-28 18:53:59] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:54:04 - Checking readiness probe status... (attempt 16/60)
[2026-03-28 18:54:04] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:54:09 - Checking readiness probe status... (attempt 17/60)
[2026-03-28 18:54:09] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:54:15 - Checking readiness probe status... (attempt 18/60)
[2026-03-28 18:54:15] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:54:20 - Checking readiness probe status... (attempt 19/60)
[2026-03-28 18:54:20] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:54:25 - Checking readiness probe status... (attempt 20/60)
[2026-03-28 18:54:26] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:54:31 - Checking readiness probe status... (attempt 21/60)
[2026-03-28 18:54:31] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:54:36 - Checking readiness probe status... (attempt 22/60)
[2026-03-28 18:54:36] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:54:41 - Checking readiness probe status... (attempt 23/60)
[2026-03-28 18:54:42] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:54:47 - Checking readiness probe status... (attempt 24/60)
[2026-03-28 18:54:47] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:54:52 - Checking readiness probe status... (attempt 25/60)
[2026-03-28 18:54:52] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:54:57 - Checking readiness probe status... (attempt 26/60)
[2026-03-28 18:54:58] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:55:03 - Checking readiness probe status... (attempt 27/60)
[2026-03-28 18:55:03] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:55:08 - Checking readiness probe status... (attempt 28/60)
[2026-03-28 18:55:08] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:55:13 - Checking readiness probe status... (attempt 29/60)
[2026-03-28 18:55:14] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:55:19 - Checking readiness probe status... (attempt 30/60)
[2026-03-28 18:55:19] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:55:24 - Checking readiness probe status... (attempt 31/60)
[2026-03-28 18:55:24] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:55:29 - Checking readiness probe status... (attempt 32/60)
[2026-03-28 18:55:30] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:55:35 - Checking readiness probe status... (attempt 33/60)
[2026-03-28 18:55:35] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:55:40 - Checking readiness probe status... (attempt 34/60)
[2026-03-28 18:55:40] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:55:45 - Checking readiness probe status... (attempt 35/60)
[2026-03-28 18:55:46] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:55:51 - Checking readiness probe status... (attempt 36/60)
[2026-03-28 18:55:51] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:55:56 - Checking readiness probe status... (attempt 37/60)
[2026-03-28 18:55:57] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:56:02 - Checking readiness probe status... (attempt 38/60)
[2026-03-28 18:56:02] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:56:07 - Checking readiness probe status... (attempt 39/60)
[2026-03-28 18:56:07] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:56:12 - Checking readiness probe status... (attempt 40/60)
[2026-03-28 18:56:13] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:56:18 - Checking readiness probe status... (attempt 41/60)
[2026-03-28 18:56:18] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:56:23 - Checking readiness probe status... (attempt 42/60)
[2026-03-28 18:56:23] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:56:28 - Checking readiness probe status... (attempt 43/60)
[2026-03-28 18:56:29] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:56:34 - Checking readiness probe status... (attempt 44/60)
[2026-03-28 18:56:34] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:56:39 - Checking readiness probe status... (attempt 45/60)
[2026-03-28 18:56:39] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:56:44 - Checking readiness probe status... (attempt 46/60)
[2026-03-28 18:56:45] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:56:50 - Checking readiness probe status... (attempt 47/60)
[2026-03-28 18:56:50] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:56:55 - Checking readiness probe status... (attempt 48/60)
[2026-03-28 18:56:56] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:57:01 - Checking readiness probe status... (attempt 49/60)
[2026-03-28 18:57:01] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:57:06 - Checking readiness probe status... (attempt 50/60)
[2026-03-28 18:57:06] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:57:11 - Checking readiness probe status... (attempt 51/60)
[2026-03-28 18:57:12] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:57:17 - Checking readiness probe status... (attempt 52/60)
[2026-03-28 18:57:17] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:57:22 - Checking readiness probe status... (attempt 53/60)
[2026-03-28 18:57:22] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:57:27 - Checking readiness probe status... (attempt 54/60)
[2026-03-28 18:57:28] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:57:33 - Checking readiness probe status... (attempt 55/60)
[2026-03-28 18:57:33] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:57:38 - Checking readiness probe status... (attempt 56/60)
[2026-03-28 18:57:38] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:57:43 - Checking readiness probe status... (attempt 57/60)
[2026-03-28 18:57:44] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:57:49 - Checking readiness probe status... (attempt 58/60)
[2026-03-28 18:57:49] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:57:54 - Checking readiness probe status... (attempt 59/60)
[2026-03-28 18:57:54] INFO: Readiness probe not yet ready. Container status: 
2026-03-28 18:57:59 - Checking readiness probe status... (attempt 60/60)
[2026-03-28 18:58:00] INFO: Readiness probe not yet ready. Container status: 
[2026-03-28 18:58:00] ERROR: ❌ Readiness probe verification: FAILED - timeout after 60 attempts
2026-03-28 18:58:00 - Final pod status:
NAME                            READY   STATUS             RESTARTS      AGE
my-ag-ui-app-5fc4976ff7-6nwtb   0/1     CrashLoopBackOff   9 (64s ago)   19m
my-ag-ui-app-f868ffd99-dmnqn    0/1     CrashLoopBackOff   5 (10s ago)   5m21s
[2026-03-28 18:58:00] INFO: Capturing Kubernetes pod events for analysis...
[2026-03-28 18:58:00] INFO: Analyzing events for pod: my-ag-ui-app-5fc4976ff7-6nwtb
2026-03-28 18:58:01 - === POD EVENTS ===
LAST SEEN   TYPE      REASON    OBJECT                              MESSAGE
3m56s       Warning   BackOff   pod/my-ag-ui-app-5fc4976ff7-6nwtb   Back-off restarting failed container my-ag-ui-app in pod my-ag-ui-app-5fc4976ff7-6nwtb_default(81b588c8-46d5-474b-bcdd-0755a58f9295)
2m50s       Normal    Pulling   pod/my-ag-ui-app-5fc4976ff7-6nwtb   Pulling image "localhost:32000/my-ag-ui-app:latest"
2026-03-28 18:58:01 - === END POD EVENTS ===
[2026-03-28 18:58:01] INFO: Analyzing specific event types...
[2026-03-28 18:58:02] ERROR: ❌ PROBE FAILURES DETECTED (3 events):
[2026-03-28 18:58:02] ERROR:    Unhealthy events indicate readiness or liveness probe failures
LAST SEEN   TYPE      REASON      OBJECT                             MESSAGE
15s         Warning   Unhealthy   pod/my-ag-ui-app-f868ffd99-dmnqn   Readiness probe failed: HTTP probe failed with statuscode: 404
3m42s       Warning   Unhealthy   pod/my-ag-ui-app-f868ffd99-dmnqn   Liveness probe failed: HTTP probe failed with statuscode: 404
[2026-03-28 18:58:03] INFO: === POD EVENTS SUMMARY ===
[2026-03-28 18:58:03] INFO: Pull Errors: 0
[2026-03-28 18:58:03] INFO: Crash Loops: 0
[2026-03-28 18:58:03] INFO: Probe Failures: 3
[2026-03-28 18:58:03] INFO: === END POD EVENTS SUMMARY ===
[2026-03-28 18:58:03] INFO: Detailed pod description for comprehensive debugging:
Name:             my-ag-ui-app-5fc4976ff7-6nwtb
Namespace:        default
Priority:         0
Service Account:  default
Node:             my-ag-ui-app-k8s/10.237.212.68
Start Time:       Sat, 28 Mar 2026 18:38:55 -0400
Labels:           app=my-ag-ui-app
                  pod-template-hash=5fc4976ff7
Annotations:      cni.projectcalico.org/containerID: 336de68d4066302829fec00b076eff3cc21feedd8a1b27c53f7e48f889ecb527
                  cni.projectcalico.org/podIP: 10.1.217.39/32
                  cni.projectcalico.org/podIPs: 10.1.217.39/32
                  kubectl.kubernetes.io/restartedAt: 2026-03-28T18:38:55-04:00
Status:           Running
IP:               10.1.217.39
IPs:
  IP:           10.1.217.39
Controlled By:  ReplicaSet/my-ag-ui-app-5fc4976ff7
Containers:
  my-ag-ui-app:
    Container ID:   containerd://87ab73f7e2c79a5df9b57bc131f51bee559776baf9026c7f0d19901dfefeab13
    Image:          localhost:32000/my-ag-ui-app:latest
    Image ID:       localhost:32000/my-ag-ui-app@sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f
    Port:           3000/TCP
    Host Port:      0/TCP
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Sat, 28 Mar 2026 18:56:06 -0400
      Finished:     Sat, 28 Mar 2026 18:56:56 -0400
    Ready:          False
    Restart Count:  9
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
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-hjcp9 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  kube-api-access-hjcp9:
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
  Type     Reason   Age                   From     Message
  ----     ------   ----                  ----     -------
  Warning  BackOff  3m59s (x42 over 13m)  kubelet  Back-off restarting failed container my-ag-ui-app in pod my-ag-ui-app-5fc4976ff7-6nwtb_default(81b588c8-46d5-474b-bcdd-0755a58f9295)
  Normal   Pulling  2m53s (x9 over 19m)   kubelet  Pulling image "localhost:32000/my-ag-ui-app:latest"
[2026-03-28 18:58:04] ERROR: === CONTAINER LOGS (for debugging) ===
▲ Next.js 16.1.0
- Local:         http://my-ag-ui-app-5fc4976ff7-6nwtb:3000
- Network:       http://my-ag-ui-app-5fc4976ff7-6nwtb:3000

✓ Starting...
✓ Ready in 114ms
[2026-03-28 18:58:04] ERROR: === END CONTAINER LOGS ===
[2026-03-28 18:58:04] ERROR: === PREVIOUS CONTAINER LOGS (if available) ===
▲ Next.js 16.1.0
- Local:         http://my-ag-ui-app-5fc4976ff7-6nwtb:3000
- Network:       http://my-ag-ui-app-5fc4976ff7-6nwtb:3000

✓ Starting...
✓ Ready in 114ms
[2026-03-28 18:58:04] ERROR: === END PREVIOUS CONTAINER LOGS ===
2026-03-28 18:58:04 - Container status details:
[{"allocatedResources":{"cpu":"100m","memory":"256Mi"},"containerID":"containerd://87ab73f7e2c79a5df9b57bc131f51bee559776baf9026c7f0d19901dfefeab13","image":"localhost:32000/my-ag-ui-app:latest","imageID":"localhost:32000/my-ag-ui-app@sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f","lastState":{"terminated":{"containerID":"containerd://87ab73f7e2c79a5df9b57bc131f51bee559776baf9026c7f0d19901dfefeab13","exitCode":0,"finishedAt":"2026-03-28T22:56:56Z","reason":"Completed","startedAt":"2026-03-28T22:56:06Z"}},"name":"my-ag-ui-app","ready":false,"resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"restartCount":9,"started":false,"state":{"waiting":{"message":"back-off 5m0s restarting failed container=my-ag-ui-app pod=my-ag-ui-app-5fc4976ff7-6nwtb_default(81b588c8-46d5-474b-bcdd-0755a58f9295)","reason":"CrashLoopBackOff"}},"volumeMounts":[{"mountPath":"/var/run/secrets/kubernetes.io/serviceaccount","name":"kube-api-access-hjcp9","readOnly":true,"recursiveReadOnly":"Disabled"}]}]2026-03-28 18:58:05 - Testing health check endpoint accessibility...
2026-03-28 18:58:05 - Testing HTTP health check endpoint from within cluster...
pod "temp-health-test" deleted
pod default/temp-health-test terminated (Error)
[2026-03-28 18:58:08] ══════════════════════════════════════════════════════════════════════════════
[2026-03-28 18:58:08]                          STRUCTURED ERROR
[2026-03-28 18:58:08] ══════════════════════════════════════════════════════════════════════════════
[2026-03-28 18:58:08] ERROR TYPE: READINESS_PROBE_TIMEOUT
[2026-03-28 18:58:08] DIAGNOSTIC: Readiness probe did not pass within 5-minute timeout
[2026-03-28 18:58:08] COMMON CAUSES: Application not ready to serve traffic, health check endpoint not responding, or application startup issues
[2026-03-28 18:58:08] RECOVERY: 1. Check application logs: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl logs -l app=my-ag-ui-app, 2. Verify health check endpoint: curl http://<pod-ip>:3000/api/health, 3. Check deployment manifest for correct probe configuration, 4. Verify application is properly starting and not crashing
[2026-03-28 18:58:08] ══════════════════════════════════════════════════════════════════════════════
[2026-03-28 18:58:08] ERROR: ❌ READINESS PROBE VERIFICATION FAILED: Application not ready to serve traffic
[2026-03-28 18:58:08] ══════════════════════════════════════════════════════════════════════════════
[2026-03-28 18:58:08]                          STRUCTURED ERROR
[2026-03-28 18:58:08] ══════════════════════════════════════════════════════════════════════════════
[2026-03-28 18:58:08] ERROR TYPE: READINESS_PROBE_FAILURE
[2026-03-28 18:58:08] DIAGNOSTIC: Readiness probe verification failed
[2026-03-28 18:58:08] COMMON CAUSES: Application failed readiness probe verification and is not ready to serve traffic
[2026-03-28 18:58:08] RECOVERY: 1. Check application logs: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl logs -l app=my-ag-ui-app, 2. Verify health check endpoint: curl http://<pod-ip>:3000/api/health, 3. Check deployment manifest probe configuration, 4. Verify application is properly starting and not crashing
[2026-03-28 18:58:08] ══════════════════════════════════════════════════════════════════════════════
2026-03-28 18:58:08 - === DETAILED POD INFORMATION FOR READINESS FAILURE ===
[2026-03-28 18:58:09] ERROR: ❌ STEP 6 FAILED: Failed to deploy to Kubernetes
[2026-03-28 18:58:09] ERROR: 🔄 INITIATING ROLLBACK PROCEDURE
[2026-03-28 18:58:09] ERROR: Deployment failed - attempting to restore previous state
[2026-03-28 18:58:09] INFO: 🔄 Rolling back using backup deployment manifest...
[2026-03-28 18:58:09] INFO: 🔄 Transferring backup deployment manifest to VM...
Error from server (Conflict): error when applying patch:
{"metadata":{"annotations":{"deployment.kubernetes.io/revision":"29","kubectl.kubernetes.io/last-applied-configuration":"{\"apiVersion\":\"apps/v1\",\"kind\":\"Deployment\",\"metadata\":{\"annotations\":{\"deployment.kubernetes.io/revision\":\"29\"},\"creationTimestamp\":\"2026-03-25T20:53:24Z\",\"generation\":29,\"labels\":{\"app\":\"my-ag-ui-app\"},\"name\":\"my-ag-ui-app\",\"namespace\":\"default\",\"resourceVersion\":\"627253\",\"uid\":\"d8042d23-7478-45ce-bce8-131cbb2cfc0c\"},\"spec\":{\"progressDeadlineSeconds\":600,\"replicas\":1,\"revisionHistoryLimit\":10,\"selector\":{\"matchLabels\":{\"app\":\"my-ag-ui-app\"}},\"strategy\":{\"rollingUpdate\":{\"maxSurge\":\"25%\",\"maxUnavailable\":\"25%\"},\"type\":\"RollingUpdate\"},\"template\":{\"metadata\":{\"annotations\":{\"kubectl.kubernetes.io/restartedAt\":\"2026-03-27T13:23:13-04:00\"},\"creationTimestamp\":null,\"labels\":{\"app\":\"my-ag-ui-app\"}},\"spec\":{\"containers\":[{\"env\":[{\"name\":\"OPENAI_API_KEY\",\"valueFrom\":{\"secretKeyRef\":{\"key\":\"openai-api-key\",\"name\":\"my-ag-ui-app-secrets\"}}},{\"name\":\"OPENAI_BASE_URL\",\"valueFrom\":{\"secretKeyRef\":{\"key\":\"openai-base-url\",\"name\":\"my-ag-ui-app-secrets\"}}},{\"name\":\"OPENAI_MODEL\",\"valueFrom\":{\"secretKeyRef\":{\"key\":\"openai-model\",\"name\":\"my-ag-ui-app-secrets\"}}},{\"name\":\"EMBEDDING_MODEL\",\"valueFrom\":{\"secretKeyRef\":{\"key\":\"embedding-model\",\"name\":\"my-ag-ui-app-secrets\"}}},{\"name\":\"LOGFIRE_TOKEN\",\"valueFrom\":{\"secretKeyRef\":{\"key\":\"logfire-token\",\"name\":\"my-ag-ui-app-secrets\"}}},{\"name\":\"LLM_MAX_TOKENS\",\"valueFrom\":{\"configMapKeyRef\":{\"key\":\"llm-max-tokens\",\"name\":\"my-ag-ui-app-config\"}}},{\"name\":\"LLM_CONTEXT_WINDOW\",\"valueFrom\":{\"configMapKeyRef\":{\"key\":\"llm-context-window\",\"name\":\"my-ag-ui-app-config\"}}}],\"image\":\"localhost:32000/my-ag-ui-app:latest\",\"imagePullPolicy\":\"Always\",\"livenessProbe\":{\"failureThreshold\":3,\"httpGet\":{\"path\":\"/api/health\",\"port\":3000,\"scheme\":\"HTTP\"},\"initialDelaySeconds\":30,\"periodSeconds\":10,\"successThreshold\":1,\"timeoutSeconds\":5},\"name\":\"my-ag-ui-app\",\"ports\":[{\"containerPort\":3000,\"name\":\"http\",\"protocol\":\"TCP\"}],\"readinessProbe\":{\"failureThreshold\":3,\"httpGet\":{\"path\":\"/api/health\",\"port\":3000,\"scheme\":\"HTTP\"},\"initialDelaySeconds\":5,\"periodSeconds\":5,\"successThreshold\":1,\"timeoutSeconds\":3},\"resources\":{\"limits\":{\"cpu\":\"500m\",\"memory\":\"512Mi\"},\"requests\":{\"cpu\":\"100m\",\"memory\":\"256Mi\"}},\"terminationMessagePath\":\"/dev/termination-log\",\"terminationMessagePolicy\":\"File\"}],\"dnsPolicy\":\"ClusterFirst\",\"restartPolicy\":\"Always\",\"schedulerName\":\"default-scheduler\",\"securityContext\":{},\"terminationGracePeriodSeconds\":30}}},\"status\":{\"conditions\":[{\"lastTransitionTime\":\"2026-03-25T20:53:24Z\",\"lastUpdateTime\":\"2026-03-25T20:53:24Z\",\"message\":\"Deployment does not have minimum availability.\",\"reason\":\"MinimumReplicasUnavailable\",\"status\":\"False\",\"type\":\"Available\"},{\"lastTransitionTime\":\"2026-03-27T17:33:14Z\",\"lastUpdateTime\":\"2026-03-27T17:33:14Z\",\"message\":\"ReplicaSet \\\"my-ag-ui-app-7df4574569\\\" has timed out progressing.\",\"reason\":\"ProgressDeadlineExceeded\",\"status\":\"False\",\"type\":\"Progressing\"}],\"observedGeneration\":29,\"replicas\":2,\"unavailableReplicas\":2,\"updatedReplicas\":1}}\n"},"generation":29,"resourceVersion":"627253"},"spec":{"template":{"metadata":{"annotations":{"kubectl.kubernetes.io/restartedAt":"2026-03-27T13:23:13-04:00"}}}},"status":{"$setElementOrder/conditions":[{"type":"Available"},{"type":"Progressing"}],"conditions":[{"lastTransitionTime":"2026-03-27T17:33:14Z","lastUpdateTime":"2026-03-27T17:33:14Z","message":"ReplicaSet \"my-ag-ui-app-7df4574569\" has timed out progressing.","reason":"ProgressDeadlineExceeded","status":"False","type":"Progressing"}],"observedGeneration":29}}
to:
Resource: "apps/v1, Resource=deployments", GroupVersionKind: "apps/v1, Kind=Deployment"
Name: "my-ag-ui-app", Namespace: "default"
for: "/home/ubuntu/deployment.yaml.backup": error when patching "/home/ubuntu/deployment.yaml.backup": Operation cannot be fulfilled on deployments.apps "my-ag-ui-app": the object has been modified; please apply your changes to the latest version and try again
[2026-03-28 18:58:13] ERROR: ❌ ROLLBACK FAILED: Could not apply backup deployment manifest
[2026-03-28 18:58:13] ERROR:    Manual intervention required to restore deployment state
