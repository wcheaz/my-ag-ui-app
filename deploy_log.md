Log file created: /tmp/deploy-20260407-110443.log
[2026-04-07 11:04:43] INFO: Log file initialized: /tmp/deploy-20260407-110443.log
[2026-04-07 11:04:43] INFO: Starting log cleanup process
[2026-04-07 11:04:43] INFO: Found 3 deployment log files to check
[2026-04-07 11:04:43] INFO: Log cleanup process completed
[2026-04-07 11:04:43] INFO: 🚀 STARTING DEPLOYMENT PIPELINE
[2026-04-07 11:04:43] INFO: Environment: development
[2026-04-07 11:04:43] INFO: Verbose mode: false
[2026-04-07 11:04:43] INFO: 📋 Step 1: Setting up Kubernetes secrets...
Log file created: /tmp/deploy-20260407-110443.log
[2026-04-07 11:04:43] INFO: Log file initialized: /tmp/deploy-20260407-110443.log
[2026-04-07 11:04:43] INFO: Starting Kubernetes secrets setup...
[2026-04-07 11:04:43] INFO: k8s directory found: /home/ncheaz/git/my-ag-ui-app/k8s/
[2026-04-07 11:04:43] INFO: setup-secrets.sh script found: /home/ncheaz/git/my-ag-ui-app/k8s/setup-secrets.sh
[2026-04-07 11:04:43] INFO: Setting up environment variables for secrets creation...
[2026-04-07 11:04:43] INFO: Loading environment variables from .env file...
[2026-04-07 11:04:43] INFO: Set environment variable: OPENAI_API_KEY
[2026-04-07 11:04:43] INFO: Set environment variable: OPENAI_BASE_URL
[2026-04-07 11:04:43] INFO: Set environment variable: OPENAI_MODEL
[2026-04-07 11:04:43] INFO: Set environment variable: LLM_MAX_TOKENS
[2026-04-07 11:04:43] INFO: Set environment variable: LLM_CONTEXT_WINDOW
[2026-04-07 11:04:43] INFO: Set environment variable: EMBEDDING_MODEL
[2026-04-07 11:04:43] INFO: All required environment variables are set
[2026-04-07 11:04:43] INFO: Running secrets setup script to generate YAML file...
[2026-04-07 11:04:43] Setting up Kubernetes secrets...
[2026-04-07 11:04:43] Reading environment variables...
[2026-04-07 11:04:43] Encoding values to base64...
[2026-04-07 11:04:43] Generating Kubernetes secrets file...
[2026-04-07 11:04:43] Validating generated secrets file against Kubernetes API server...
secret/my-ag-ui-app-secrets unchanged (server dry run)
configmap/my-ag-ui-app-config unchanged (server dry run)
[2026-04-07 11:04:43] ✅ Kubernetes secrets file generated successfully: k8s/secrets.yaml
[2026-04-07 11:04:43] INFO: Kubernetes secrets YAML file generated successfully: k8s/secrets.yaml
[2026-04-07 11:04:43] INFO: Copying secrets file to VM for Kubernetes operations...
[2026-04-07 11:04:43] INFO: Secrets file copied to VM successfully
[2026-04-07 11:04:43] INFO: Validating secrets YAML against Kubernetes API server...
secret/my-ag-ui-app-secrets unchanged (server dry run)
configmap/my-ag-ui-app-config unchanged (server dry run)
[2026-04-07 11:04:44] INFO: Secrets YAML validation passed
[2026-04-07 11:04:44] INFO: Applying secrets to Kubernetes cluster...
secret/my-ag-ui-app-secrets unchanged
configmap/my-ag-ui-app-config unchanged
[2026-04-07 11:04:44] INFO: Kubernetes secrets setup completed successfully
[2026-04-07 11:04:44] INFO: ✅ Step 1: Kubernetes secrets setup completed
[2026-04-07 11:04:44] INFO: 📋 Step 2: Building Docker image...
[2026-04-07 11:04:44] INFO: Starting Docker build process
[2026-04-07 11:04:44] Starting dependency validation...
[2026-04-07 11:04:44] Checking if package.json and package-lock.json are in sync...
[2026-04-07 11:04:48] ✅ SUCCESS: package.json and package-lock.json are synchronized
[2026-04-07 11:04:48]    Dependencies are ready for reproducible Docker builds.
[2026-04-07 11:04:48] INFO: Starting Docker image build for 'my-ag-ui-app:latest'...
[2026-04-07 11:05:30] INFO: Docker build completed successfully
[2026-04-07 11:05:30] INFO: Build output:
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 4.85kB done
#1 DONE 0.0s

#2 [internal] load metadata for docker.io/library/node:20.12.0-alpine
#2 DONE 0.6s

#3 [internal] load .dockerignore
#3 transferring context: 128B done
#3 DONE 0.0s

#4 [builder 1/6] FROM docker.io/library/node:20.12.0-alpine@sha256:ef3f47741e161900ddd07addcaca7e76534a9205e4cd73b2ed091ba339004a75
#4 DONE 0.0s

#5 [internal] load build context
#5 transferring context: 4.77MB 0.1s done
#5 DONE 0.1s

#6 [builder 2/6] WORKDIR /app
#6 CACHED

#7 [builder 3/6] COPY package.json package-lock.json ./
#7 CACHED

#8 [builder 4/6] RUN echo "=== DEPENDENCY INSTALLATION ===" &&     echo "Starting npm ci (reproducible install)..." &&     if npm ci --ignore-scripts; then         echo "✅ SUCCESS: npm ci completed - using reproducible dependencies from lock file";     else         echo "⚠️  WARNING: npm ci failed - lock files are out of sync";         echo "🔄 FALLING BACK to npm install to continue build...";         echo "ℹ️  NOTE: This allows deployment but reduces build reproducibility";         echo "🔧 FIX: Run 'npm install' locally and commit updated package-lock.json";         npm install --ignore-scripts;         echo "✅ SUCCESS: npm install completed - build continuing with fallback dependencies";     fi &&     echo "=== DEPENDENCY INSTALLATION COMPLETED ===" &&     npm cache clean --force
#8 CACHED

#9 [builder 5/6] COPY . .
#9 DONE 1.0s

#10 [builder 6/6] RUN npm run build
#10 0.562 
#10 0.562 > pydantic-ai-starter@0.1.0 build
#10 0.562 > next build
#10 0.562 
#10 1.370 Attention: Next.js now collects completely anonymous telemetry regarding usage.
#10 1.371 This information is used to shape Next.js' roadmap and prioritize features.
#10 1.371 You can learn more, including how to opt-out if you'd not like to participate in this anonymous program, by visiting the following URL:
#10 1.371 https://nextjs.org/telemetry
#10 1.371 
#10 1.380 ▲ Next.js 16.1.0 (Turbopack)
#10 1.381 
#10 1.433   Creating an optimized production build ...
#10 31.29 ✓ Compiled successfully in 29.5s
#10 31.30   Running TypeScript ...
#10 33.93   Collecting page data using 11 workers ...
#10 34.90   Generating static pages using 11 workers (0/6) ...
#10 35.11   Generating static pages using 11 workers (1/6) 
#10 35.52   Generating static pages using 11 workers (2/6) 
#10 35.54   Generating static pages using 11 workers (4/6) 
#10 36.10 ✓ Generating static pages using 11 workers (6/6) in 1201.9ms
#10 36.11   Finalizing page optimization ...
#10 36.27 
#10 36.27 Route (app)
#10 36.27 ┌ ○ /
#10 36.27 ├ ○ /_not-found
#10 36.27 ├ ƒ /api/copilotkit
#10 36.27 └ ƒ /api/health
#10 36.27 
#10 36.27 
#10 36.27 ○  (Static)   prerendered as static content
#10 36.27 ƒ  (Dynamic)  server-rendered on demand
#10 36.27 
#10 36.44 npm notice 
#10 36.44 npm notice New major version of npm available! 10.5.0 -> 11.12.1
#10 36.44 npm notice Changelog: <https://github.com/npm/cli/releases/tag/v11.12.1>
#10 36.44 npm notice Run `npm install -g npm@11.12.1` to update!
#10 36.44 npm notice 
#10 DONE 36.8s

#11 [runner 3/6] RUN addgroup --system --gid 1001 nodejs &&     adduser --system --uid 1001 nextjs
#11 CACHED

#12 [runner 4/6] COPY --from=builder /app/public ./public
#12 CACHED

#13 [runner 5/6] COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
#13 DONE 0.5s

#14 [runner 6/6] COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
#14 DONE 0.1s

#15 exporting to image
#15 exporting layers
#15 exporting layers 0.9s done
#15 writing image sha256:851b0815f840d00e9918eeebb19390d2e2b8fb6d8fca7a9e8582f313b30fa4b3 done
#15 naming to docker.io/library/my-ag-ui-app:latest done
#15 DONE 0.9s

View build details: docker-desktop://dashboard/build/default/default/wnp7hjeen9x9z2h7dqh2ofthr
[2026-04-07 11:05:30] INFO: Build: Docker image built successfully (no detailed build summary available)
[2026-04-07 11:05:30] INFO: Docker image 'my-ag-ui-app:latest' built successfully
[2026-04-07 11:05:30] INFO: Docker image 'my-ag-ui-app:latest' verified successfully
[2026-04-07 11:05:30] INFO: Docker build process completed successfully
[2026-04-07 11:05:30] INFO: ✅ Step 2: Docker image build completed
[2026-04-07 11:05:30] INFO: 📋 Step 3: Tagging Docker image...
[2026-04-07 11:05:30] INFO: Starting Docker image tagging for local registry...
[2026-04-07 11:05:30] INFO: Using comprehensive tagging function with validation and error handling...
Untagged: localhost:32000/my-ag-ui-app:latest
[2026-04-07 11:05:31] Verifying tagged image exists after successful tagging...
[2026-04-07 11:05:32] ✅ Image tagging verification successful within VM
[2026-04-07 11:05:32]    Target tag localhost:32000/my-ag-ui-app:latest exists and is accessible within VM
[2026-04-07 11:05:32] ✅ Image ID verification successful - both images reference the same underlying image within VM
[2026-04-07 11:05:32] INFO: ✅ Docker image tagging for registry completed with comprehensive validation
[2026-04-07 11:05:32] INFO:    Image successfully tagged as: localhost:32000/my-ag-ui-app:latest
[2026-04-07 11:05:32] INFO: ✅ Step 3: Docker image tagging completed
[2026-04-07 11:05:32] INFO: 📋 Step 4: Setting up Microk8s registry...
Log file created: /tmp/deploy-20260407-110532.log
[2026-04-07 11:05:32] INFO: Log file initialized: /tmp/deploy-20260407-110532.log
[2026-04-07 11:05:32] INFO: 🔶 START: MICROK8S_REGISTRY_SETUP
[2026-04-07 11:05:32] INFO: Starting microk8s registry setup...
[2026-04-07 11:05:32] INFO: 🔶 REGISTRY SETUP: Starting microk8s registry setup process...
[2026-04-07 11:05:32] INFO: Checking microk8s availability...
[2026-04-07 11:05:32] INFO: ✅ microk8s is available in VM
[2026-04-07 11:05:32] INFO: Performing pre-enablement registry connectivity verification...
[2026-04-07 11:05:32] INFO: Performing pre-enablement registry connectivity check...
[2026-04-07 11:05:33] INFO: ✅ PRE-ENABLEMENT VERIFICATION: Registry already accessible
[2026-04-07 11:05:33] INFO:    JSON validation: Valid registry catalog format with repositories field
[2026-04-07 11:05:33] INFO: ✅ PRE-ENABLEMENT VERIFICATION: Registry response format is valid JSON
[2026-04-07 11:05:33] INFO: ✅ Pre-enablement registry connectivity verification completed
[2026-04-07 11:05:33] INFO: Enabling microk8s registry...
[2026-04-07 11:05:33] INFO:    Command: microk8s enable registry
[2026-04-07 11:05:33] INFO:    Executing: timeout 30 multipass exec 'my-ag-ui-app-k8s' -- microk8s enable registry
[2026-04-07 11:05:33] INFO: ✅ microk8s registry enable command completed successfully
[2026-04-07 11:05:33] INFO: Waiting 5 seconds for registry to fully start...
[2026-04-07 11:05:38] INFO: Verifying registry is running and accessible at localhost:32000...
[2026-04-07 11:05:39] INFO: ✅ REGISTRY CONNECTIVITY: SUCCESS
[2026-04-07 11:05:39] INFO:    Response time: .362280739 seconds
[2026-04-07 11:05:39] INFO:    JSON validation: Valid registry catalog format with repositories field
[2026-04-07 11:05:39] INFO: ✅ REGISTRY RESPONSE FORMAT: VALID JSON
[2026-04-07 11:05:39] INFO: ✅ Registry verification completed successfully
[2026-04-07 11:05:39] INFO:    Registry is accessible at: localhost:32000
[2026-04-07 11:05:39] INFO: ✅ REGISTRY SETUP: microk8s registry setup process completed successfully
[2026-04-07 11:05:39] INFO:    Registry status: ENABLED and VERIFIED
[2026-04-07 11:05:39] INFO:    Registry endpoint: localhost:32000
[2026-04-07 11:05:39] INFO:    Setup completed at: 2026-04-07 11:05:39
[2026-04-07 11:05:39] INFO: microk8s registry setup completed successfully
[2026-04-07 11:05:39] INFO: ✅ END: MICROK8S_REGISTRY_SETUP (duration: 6.383349830s)
[2026-04-07 11:05:39] INFO: 🎉 Microk8s registry setup completed successfully!
[2026-04-07 11:05:39] INFO:    Registry is ready for local image distribution
[2026-04-07 11:05:39] INFO:    Next step: Push Docker image to registry
[2026-04-07 11:05:39] INFO: ✅ Step 4: Microk8s registry setup completed
[2026-04-07 11:05:39] INFO: 📋 Step 5: Pushing Docker image...
Log file created: /tmp/deploy-20260407-110539.log
[2026-04-07 11:05:39] INFO: Log file initialized: /tmp/deploy-20260407-110539.log
[2026-04-07 11:05:39] INFO: Starting Docker image push to microk8s registry...
[2026-04-07 11:05:39] INFO: Starting Docker image push to microk8s registry (executing within VM)...
[2026-04-07 11:05:39] Target registry image: localhost:32000/my-ag-ui-app:latest
[2026-04-07 11:05:39] ✅ Registry verification completed successfully
[2026-04-07 11:05:39]    Registry is accessible at: localhost:32000
[2026-04-07 11:05:39] Pushing image to microk8s registry with enhanced retry logic (within VM)...
[2026-04-07 11:05:39]    Command: multipass exec my-ag-ui-app-k8s -- timeout 60 docker push localhost:32000/my-ag-ui-app:latest
[2026-04-07 11:05:40] ✅ Docker push command completed successfully within VM (attempt 1)
[2026-04-07 11:05:40] ✅ Image push completed successfully within VM
[2026-04-07 11:05:40]    Push command output summary:
The push refers to repository [localhost:32000/my-ag-ui-app]
413c136dedcf: Layer already exists
82fb5a2278a7: Layer already exists
abc5b1d00820: Layer already exists
52a51099bdef: Layer already exists
a2cffe5fe30b: Layer already exists
75136c45e7ab: Layer already exists
8e1fab8d9171: Layer already exists
f82bfb71098a: Layer already exists
d4fc045c9e3a: Layer already exists
[2026-04-07 11:05:40]    ... (output truncated, full output logged to file)
[2026-04-07 11:05:40] INFO: Starting image verification with exponential backoff retry logic (1s, 2s, 4s, 8s, 16s, 32s, 64s)...
[2026-04-07 11:05:40] INFO: Image verification attempt 1/7 (delay: 1s) at 2026-04-07 11:05:40
[2026-04-07 11:05:40] INFO: ✅ Image 'my-ag-ui-app:latest' found in registry tags list at 2026-04-07 11:05:40
[2026-04-07 11:05:40] INFO: ✅ Image verification successful - image is available in registry at 2026-04-07 11:05:40
[2026-04-07 11:05:40] INFO: ✅ Docker image push to microk8s registry completed successfully within VM at 2026-04-07 11:05:40
[2026-04-07 11:05:40] INFO:    Image: localhost:32000/my-ag-ui-app:latest
[2026-04-07 11:05:40] INFO:    Status: PUSHED and VERIFIED
[2026-04-07 11:05:40] INFO:    Registry: http://localhost:32000 (within VM)
[2026-04-07 11:05:40] INFO:    Ready for: Kubernetes deployment using registry image reference
[2026-04-07 11:05:40]    Status: PUSHED and VERIFIED (or verification pending)
[2026-04-07 11:05:40]    Registry: http://localhost:32000 (within VM)
[2026-04-07 11:05:40]    Ready for: Kubernetes deployment using registry image reference
[2026-04-07 11:05:40] INFO: ✅ Docker image push to microk8s registry completed successfully
[2026-04-07 11:05:40] INFO: ✅ Step 5: Docker image push completed
[2026-04-07 11:05:40] INFO: 📋 Step 6: Deploying to Kubernetes...
2026-04-07 11:05:40 - DEBUG: Running with full verbose output (critical failure phase)
2026-04-07 11:05:40 - DEBUG: Set DEBUG=all for explicit debugging if needed
2026-04-07 11:05:40 - Starting phase: KUBERNETES_DEPLOYMENT
[2026-04-07 11:05:40] INFO: 🚀 STARTING KUBERNETES DEPLOYMENT PHASE
[2026-04-07 11:05:40] INFO: ═══════════════════════════════════════════════════════════════════════════════
2026-04-07 11:05:40 - 📋 DEPLOYMENT DETAILS:
2026-04-07 11:05:40 -    • Manifest: k8s/deployment.yaml
2026-04-07 11:05:40 -    • Image: localhost:32000/my-ag-ui-app:latest (from local registry)
2026-04-07 11:05:40 -    • Strategy: Rolling update with pod restart
2026-04-07 11:05:40 -    • Registry: microk8s local registry
2026-04-07 11:05:40 - 
[2026-04-07 11:05:40] INFO: 🔄 STEP 1: Applying deployment manifest...
[2026-04-07 11:05:40] INFO:    • Manifest: k8s/deployment.yaml
[2026-04-07 11:05:40] INFO:    • Image: localhost:32000/my-ag-ui-app:latest (from local registry)
[2026-04-07 11:05:40] INFO:    • Strategy: Rolling update with pod restart
[2026-04-07 11:05:40] INFO:    • Registry: microk8s local registry
[2026-04-07 11:05:40] INFO: 
2026-04-07 11:05:40 - 📊 PRE-APPLOY VERIFICATION: Checking current deployment state...
2026-04-07 11:05:40 -    • Current deployment state: NOT FOUND
2026-04-07 11:05:40 -    • Action: CREATE new deployment
2026-04-07 11:05:40 - 📋 MANIFEST VALIDATION: Checking deployment.yaml file...
2026-04-07 11:05:40 - 🔍 REGISTRY PORT VALIDATION: Checking for registry port mismatches...
2026-04-07 11:05:40 -    • Registry port check: No localhost registry reference found in deployment.yaml
2026-04-07 11:05:40 -    • This might indicate image references Docker Hub instead of local registry
2026-04-07 11:05:40 -    • Expected: image: localhost:32000/my-ag-ui-app:latest
2026-04-07 11:05:40 -    • Manifest file size: 116 lines
2026-04-07 11:05:40 -    • Manifest validation: PASSED
2026-04-07 11:05:40 - 🔌 KUBERNETES CONNECTION: Verifying cluster access...
2026-04-07 11:05:41 -    • Kubernetes cluster: ACCESSIBLE
2026-04-07 11:05:41 - 🏷️  NAMESPACE VERIFICATION: Checking target namespace...
2026-04-07 11:05:41 -    • Target namespace: default
2026-04-07 11:05:41 -    • Namespace status: EXISTS and ACTIVE
2026-04-07 11:05:41 - 🚀 APPLYING DEPLOYMENT MANIFEST with detailed logging...
2026-04-07 11:05:41 -    • First validating deployment manifest with dry-run...
2026-04-07 11:05:41 -    • Command: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl apply --dry-run=server -f k8s/deployment.yaml
2026-04-07 11:05:41 -    • Expected: Validation against Kubernetes API server
[2026-04-07 11:05:41] INFO: Starting deployment manifest validation using kubectl apply --dry-run=server...
deployment.apps/my-ag-ui-app created (server dry run)
[2026-04-07 11:05:41] INFO: ✅ Deployment manifest validation successful
2026-04-07 11:05:41 -    • Validation passed, proceeding with actual deployment...
2026-04-07 11:05:41 -    • Command: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl apply -f k8s/deployment.yaml
2026-04-07 11:05:41 -    • Expected: Deployment resource creation/update
2026-04-07 11:05:41 -    • Output will be captured and analyzed below...
2026-04-07 11:05:41 - 📤 KUBECTL APPLY OUTPUT (first 1000 chars):
deployment.apps/my-ag-ui-app created
2026-04-07 11:05:41 - ✅ KUBECTL APPLY: Command completed successfully (exit code: 0)
2026-04-07 11:05:41 -    • Result: NEW deployment created
2026-04-07 11:05:41 -    • Action: Fresh deployment of my-ag-ui-app
2026-04-07 11:05:41 - 🔍 POST-APPLY VERIFICATION: Checking deployment status after apply...
2026-04-07 11:05:42 -    ✅ Deployment verification: PASSED
2026-04-07 11:05:42 -       • Deployment resource exists: my-ag-ui-app
2026-04-07 11:05:42 -       • Deployment spec: {"progressDeadlineSeconds":600,"replicas":1,"revisionHistoryLimit":10,"selector":{"matchLabels":{"app":"my-ag-ui-app"}},"strategy":{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"},"template":{"metadata":{"creationTimestamp":null,"labels":{"app":"my-ag-ui-app"}},"spec":{"containers":[{"env":[{"name":"OPENAI_API_KEY","valueFrom":{"secretKeyRef":{"key":"openai-api-key","name":"my-ag-ui-app-secrets"}}},{"name":"OPENAI_BASE_URL","valueFrom":{"secretKeyRef":{"key":"openai-base-url","name":"my-ag-ui-app-secrets"}}},{"name":"OPENAI_MODEL","valueFrom":{"secretKeyRef":{"key":"openai-model","name":"my-ag-ui-app-secrets"}}},{"name":"EMBEDDING_MODEL","valueFrom":{"secretKeyRef":{"key":"embedding-model","name":"my-ag-ui-app-secrets"}}},{"name":"LOGFIRE_TOKEN","valueFrom":{"secretKeyRef":{"key":"logfire-token","name":"my-ag-ui-app-secrets"}}},{"name":"LLM_MAX_TOKENS","valueFrom":{"configMapKeyRef":{"key":"llm-max-tokens","name":"my-ag-ui-app-config"}}},{"name":"LLM_CONTEXT_WINDOW","valueFrom":{"configMapKeyRef":{"key":"llm-context-window","name":"my-ag-ui-app-config"}}}],"image":"localhost:32000/my-ag-ui-app:latest","imagePullPolicy":"Always","livenessProbe":{"failureThreshold":3,"httpGet":{"path":"/api/health","port":3000,"scheme":"HTTP"},"initialDelaySeconds":30,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5},"name":"my-ag-ui-app","ports":[{"containerPort":3000,"name":"http","protocol":"TCP"}],"readinessProbe":{"failureThreshold":3,"httpGet":{"path":"/api/health","port":3000,"scheme":"HTTP"},"initialDelaySeconds":5,"periodSeconds":5,"successThreshold":1,"timeoutSeconds":3},"resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"terminationMessagePath":"/dev/termination-log","terminationMessagePolicy":"File"}],"dnsPolicy":"ClusterFirst","restartPolicy":"Always","schedulerName":"default-scheduler","securityContext":{},"terminationGracePeriodSeconds":30}}}
2026-04-07 11:05:42 -       • Deployment status: {"conditions":[{"lastTransitionTime":"2026-04-07T15:05:41Z","lastUpdateTime":"2026-04-07T15:05:41Z","message":"Deployment does not have minimum availability.","reason":"MinimumReplicasUnavailable","status":"False","type":"Available"},{"lastTransitionTime":"2026-04-07T15:05:41Z","lastUpdateTime":"2026-04-07T15:05:41Z","message":"ReplicaSet \"my-ag-ui-app-67469576cb\" is progressing.","reason":"ReplicaSetUpdated","status":"True","type":"Progressing"}],"observedGeneration":1,"replicas":1,"unavailableReplicas":1,"updatedReplicas":1}
2026-04-07 11:05:43 -       ✅ Image reference verification: PASSED
2026-04-07 11:05:43 -          • Expected: localhost:32000/my-ag-ui-app:latest
2026-04-07 11:05:43 -          • Actual: localhost:32000/my-ag-ui-app:latest
2026-04-07 11:05:43 - ✅ Deployment manifest application process completed
2026-04-07 11:05:43 -    • Kubernetes deployment resource processed
2026-04-07 11:05:43 -    • Next step: Deployment restart to trigger pod creation
2026-04-07 11:05:43 - 
2026-04-07 11:05:43 - 🔄 STEP 2: Restarting deployment to trigger pod recreation...
2026-04-07 11:05:43 -    • This will create new pods using the updated registry image
2026-04-07 11:05:43 -    • Pods will pull image from localhost:32000/my-ag-ui-app:latest
deployment.apps/my-ag-ui-app restarted
2026-04-07 11:05:43 - ✅ Deployment restarted successfully
2026-04-07 11:05:43 -    • Rolling update initiated
2026-04-07 11:05:43 -    • New pods will be created using registry image
2026-04-07 11:05:43 -    • Expected: Direct pod startup (no ImagePullBackOff with registry approach)
2026-04-07 11:05:43 - 
[2026-04-07 11:05:43] INFO: Starting pod status polling for Running state (5-second intervals, 5-minute timeout)...
2026-04-07 11:05:43 - Checking pod status for Running state... (attempt 1/60)
[2026-04-07 11:05:43] INFO: ✅ Pod reached Running state successfully
[2026-04-07 11:05:43] INFO: ✅ Pod status polling completed successfully - pod is Running
[2026-04-07 11:05:43] INFO: Capturing Kubernetes pod events for analysis...
[2026-04-07 11:05:44] INFO: Analyzing events for pod: my-ag-ui-app-67469576cb-gb4fw
2026-04-07 11:05:44 - === POD EVENTS ===
LAST SEEN   TYPE     REASON      OBJECT                              MESSAGE
2s          Normal   Scheduled   pod/my-ag-ui-app-67469576cb-gb4fw   Successfully assigned default/my-ag-ui-app-67469576cb-gb4fw to my-ag-ui-app-k8s
2s          Normal   Pulling     pod/my-ag-ui-app-67469576cb-gb4fw   Pulling image "localhost:32000/my-ag-ui-app:latest"
2s          Normal   Pulled      pod/my-ag-ui-app-67469576cb-gb4fw   Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 99ms (99ms including waiting). Image size: 263041608 bytes.
2s          Normal   Created     pod/my-ag-ui-app-67469576cb-gb4fw   Created container: my-ag-ui-app
2s          Normal   Started     pod/my-ag-ui-app-67469576cb-gb4fw   Started container my-ag-ui-app
2026-04-07 11:05:44 - === END POD EVENTS ===
[2026-04-07 11:05:44] INFO: Analyzing specific event types...
[2026-04-07 11:05:46] INFO: === POD EVENTS SUMMARY ===
[2026-04-07 11:05:46] INFO: Pull Errors: 0
[2026-04-07 11:05:46] INFO: Crash Loops: 0
[2026-04-07 11:05:46] INFO: Probe Failures: 0
[2026-04-07 11:05:46] INFO: === END POD EVENTS SUMMARY ===
[2026-04-07 11:05:46] INFO: Detailed pod description for comprehensive debugging:
Name:             my-ag-ui-app-67469576cb-gb4fw
Namespace:        default
Priority:         0
Service Account:  default
Node:             my-ag-ui-app-k8s/10.237.212.68
Start Time:       Tue, 07 Apr 2026 11:05:41 -0400
Labels:           app=my-ag-ui-app
                  pod-template-hash=67469576cb
Annotations:      cni.projectcalico.org/containerID: 698374ed9f43078105c5770b58bbb01811800291ce67ebf452e1d63d52f498c0
                  cni.projectcalico.org/podIP: 10.1.217.52/32
                  cni.projectcalico.org/podIPs: 10.1.217.52/32
Status:           Running
IP:               10.1.217.52
IPs:
  IP:           10.1.217.52
Controlled By:  ReplicaSet/my-ag-ui-app-67469576cb
Containers:
  my-ag-ui-app:
    Container ID:   containerd://cca2e81fa7ec0d8dc563703ce23eb792ebdff076da3168180d03bd21d6be60f3
    Image:          localhost:32000/my-ag-ui-app:latest
    Image ID:       localhost:32000/my-ag-ui-app@sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f
    Port:           3000/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Tue, 07 Apr 2026 11:05:42 -0400
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
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-4zhqt (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  kube-api-access-4zhqt:
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
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  5s    default-scheduler  Successfully assigned default/my-ag-ui-app-67469576cb-gb4fw to my-ag-ui-app-k8s
  Normal  Pulling    5s    kubelet            Pulling image "localhost:32000/my-ag-ui-app:latest"
  Normal  Pulled     5s    kubelet            Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 99ms (99ms including waiting). Image size: 263041608 bytes.
  Normal  Created    5s    kubelet            Created container: my-ag-ui-app
  Normal  Started    5s    kubelet            Started container my-ag-ui-app
[2026-04-07 11:05:47] INFO: Starting readiness probe verification...
[2026-04-07 11:05:47] INFO: Verifying readiness probe passes before marking deployment successful...
2026-04-07 11:05:47 - Checking readiness probe status... (attempt 1/60)
[2026-04-07 11:05:47] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:05:52 - Checking readiness probe status... (attempt 2/60)
[2026-04-07 11:05:52] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:05:57 - Checking readiness probe status... (attempt 3/60)
[2026-04-07 11:05:58] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:06:03 - Checking readiness probe status... (attempt 4/60)
[2026-04-07 11:06:03] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:06:08 - Checking readiness probe status... (attempt 5/60)
[2026-04-07 11:06:08] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:06:13 - Checking readiness probe status... (attempt 6/60)
[2026-04-07 11:06:14] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:06:19 - Checking readiness probe status... (attempt 7/60)
[2026-04-07 11:06:19] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:06:24 - Checking readiness probe status... (attempt 8/60)
[2026-04-07 11:06:24] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:06:29 - Checking readiness probe status... (attempt 9/60)
[2026-04-07 11:06:30] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:06:35 - Checking readiness probe status... (attempt 10/60)
[2026-04-07 11:06:35] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:06:40 - Checking readiness probe status... (attempt 11/60)
[2026-04-07 11:06:40] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:06:45 - Checking readiness probe status... (attempt 12/60)
[2026-04-07 11:06:46] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:06:51 - Checking readiness probe status... (attempt 13/60)
[2026-04-07 11:06:51] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:06:56 - Checking readiness probe status... (attempt 14/60)
[2026-04-07 11:06:56] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:07:01 - Checking readiness probe status... (attempt 15/60)
[2026-04-07 11:07:02] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:07:07 - Checking readiness probe status... (attempt 16/60)
[2026-04-07 11:07:07] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:07:12 - Checking readiness probe status... (attempt 17/60)
[2026-04-07 11:07:12] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:07:17 - Checking readiness probe status... (attempt 18/60)
[2026-04-07 11:07:18] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:07:23 - Checking readiness probe status... (attempt 19/60)
[2026-04-07 11:07:23] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:07:28 - Checking readiness probe status... (attempt 20/60)
[2026-04-07 11:07:28] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:07:33 - Checking readiness probe status... (attempt 21/60)
[2026-04-07 11:07:34] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:07:39 - Checking readiness probe status... (attempt 22/60)
[2026-04-07 11:07:39] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:07:44 - Checking readiness probe status... (attempt 23/60)
[2026-04-07 11:07:45] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:07:50 - Checking readiness probe status... (attempt 24/60)
[2026-04-07 11:07:50] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:07:55 - Checking readiness probe status... (attempt 25/60)
[2026-04-07 11:07:55] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:08:00 - Checking readiness probe status... (attempt 26/60)
[2026-04-07 11:08:00] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:08:05 - Checking readiness probe status... (attempt 27/60)
[2026-04-07 11:08:06] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:08:11 - Checking readiness probe status... (attempt 28/60)
[2026-04-07 11:08:11] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:08:16 - Checking readiness probe status... (attempt 29/60)
[2026-04-07 11:08:16] INFO: Readiness probe not yet ready. Container status: 
