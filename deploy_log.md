Log file created: /tmp/deploy-20260407-111327.log
[2026-04-07 11:13:27] INFO: Log file initialized: /tmp/deploy-20260407-111327.log
[2026-04-07 11:13:27] INFO: Starting log cleanup process
[2026-04-07 11:13:27] INFO: Found 9 deployment log files to check
[2026-04-07 11:13:27] INFO: Log cleanup process completed
[2026-04-07 11:13:27] INFO: 🚀 STARTING DEPLOYMENT PIPELINE
[2026-04-07 11:13:27] INFO: Environment: development
[2026-04-07 11:13:27] INFO: Verbose mode: false
[2026-04-07 11:13:27] INFO: 📋 Step 1: Setting up Kubernetes secrets...
Log file created: /tmp/deploy-20260407-111327.log
[2026-04-07 11:13:27] INFO: Log file initialized: /tmp/deploy-20260407-111327.log
[2026-04-07 11:13:27] INFO: Starting Kubernetes secrets setup...
[2026-04-07 11:13:27] INFO: k8s directory found: /home/ncheaz/git/my-ag-ui-app/k8s/
[2026-04-07 11:13:27] INFO: setup-secrets.sh script found: /home/ncheaz/git/my-ag-ui-app/k8s/setup-secrets.sh
[2026-04-07 11:13:27] INFO: Setting up environment variables for secrets creation...
[2026-04-07 11:13:27] INFO: Loading environment variables from .env file...
[2026-04-07 11:13:27] INFO: Set environment variable: OPENAI_API_KEY
[2026-04-07 11:13:27] INFO: Set environment variable: OPENAI_BASE_URL
[2026-04-07 11:13:27] INFO: Set environment variable: OPENAI_MODEL
[2026-04-07 11:13:27] INFO: Set environment variable: LLM_MAX_TOKENS
[2026-04-07 11:13:27] INFO: Set environment variable: LLM_CONTEXT_WINDOW
[2026-04-07 11:13:27] INFO: Set environment variable: EMBEDDING_MODEL
[2026-04-07 11:13:27] INFO: All required environment variables are set
[2026-04-07 11:13:27] INFO: Running secrets setup script to generate YAML file...
[2026-04-07 11:13:27] Setting up Kubernetes secrets...
[2026-04-07 11:13:27] Reading environment variables...
[2026-04-07 11:13:27] Encoding values to base64...
[2026-04-07 11:13:27] Generating Kubernetes secrets file...
[2026-04-07 11:13:27] Validating generated secrets file against Kubernetes API server...
secret/my-ag-ui-app-secrets unchanged (server dry run)
configmap/my-ag-ui-app-config unchanged (server dry run)
[2026-04-07 11:13:28] ✅ Kubernetes secrets file generated successfully: k8s/secrets.yaml
[2026-04-07 11:13:28] INFO: Kubernetes secrets YAML file generated successfully: k8s/secrets.yaml
[2026-04-07 11:13:28] INFO: Copying secrets file to VM for Kubernetes operations...
[2026-04-07 11:13:28] INFO: Secrets file copied to VM successfully
[2026-04-07 11:13:28] INFO: Validating secrets YAML against Kubernetes API server...
secret/my-ag-ui-app-secrets unchanged (server dry run)
configmap/my-ag-ui-app-config unchanged (server dry run)
[2026-04-07 11:13:29] INFO: Secrets YAML validation passed
[2026-04-07 11:13:29] INFO: Applying secrets to Kubernetes cluster...
secret/my-ag-ui-app-secrets unchanged
configmap/my-ag-ui-app-config unchanged
[2026-04-07 11:13:29] INFO: Kubernetes secrets setup completed successfully
[2026-04-07 11:13:29] INFO: ✅ Step 1: Kubernetes secrets setup completed
[2026-04-07 11:13:29] INFO: 📋 Step 2: Building Docker image...
[2026-04-07 11:13:29] INFO: Starting Docker build process
[2026-04-07 11:13:29] Starting dependency validation...
[2026-04-07 11:13:29] Checking if package.json and package-lock.json are in sync...
[2026-04-07 11:13:31] ✅ SUCCESS: package.json and package-lock.json are synchronized
[2026-04-07 11:13:31]    Dependencies are ready for reproducible Docker builds.
[2026-04-07 11:13:31] INFO: Starting Docker image build for 'my-ag-ui-app:latest'...
[2026-04-07 11:14:14] INFO: Docker build completed successfully
[2026-04-07 11:14:14] INFO: Build output:
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 4.85kB done
#1 DONE 0.0s

#2 [internal] load metadata for docker.io/library/node:20.12.0-alpine
#2 DONE 0.3s

#3 [internal] load .dockerignore
#3 transferring context: 128B done
#3 DONE 0.0s

#4 [builder 1/6] FROM docker.io/library/node:20.12.0-alpine@sha256:ef3f47741e161900ddd07addcaca7e76534a9205e4cd73b2ed091ba339004a75
#4 DONE 0.0s

#5 [internal] load build context
#5 transferring context: 279.65kB 0.0s done
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
#10 0.474 
#10 0.474 > pydantic-ai-starter@0.1.0 build
#10 0.474 > next build
#10 0.474 
#10 1.157 Attention: Next.js now collects completely anonymous telemetry regarding usage.
#10 1.157 This information is used to shape Next.js' roadmap and prioritize features.
#10 1.157 You can learn more, including how to opt-out if you'd not like to participate in this anonymous program, by visiting the following URL:
#10 1.157 https://nextjs.org/telemetry
#10 1.157 
#10 1.168 ▲ Next.js 16.1.0 (Turbopack)
#10 1.168 
#10 1.227   Creating an optimized production build ...
#10 32.61 ✓ Compiled successfully in 31.0s
#10 32.61   Running TypeScript ...
#10 36.06   Collecting page data using 11 workers ...
#10 37.21   Generating static pages using 11 workers (0/6) ...
#10 37.41   Generating static pages using 11 workers (1/6) 
#10 37.86   Generating static pages using 11 workers (2/6) 
#10 37.88   Generating static pages using 11 workers (4/6) 
#10 38.47 ✓ Generating static pages using 11 workers (6/6) in 1259.7ms
#10 38.47   Finalizing page optimization ...
#10 38.66 
#10 38.66 Route (app)
#10 38.66 ┌ ○ /
#10 38.66 ├ ○ /_not-found
#10 38.66 ├ ƒ /api/copilotkit
#10 38.66 └ ƒ /api/health
#10 38.66 
#10 38.66 
#10 38.66 ○  (Static)   prerendered as static content
#10 38.66 ƒ  (Dynamic)  server-rendered on demand
#10 38.66 
#10 38.69 npm notice 
#10 38.69 npm notice New major version of npm available! 10.5.0 -> 11.12.1
#10 38.69 npm notice Changelog: <https://github.com/npm/cli/releases/tag/v11.12.1>
#10 38.69 npm notice Run `npm install -g npm@11.12.1` to update!
#10 38.69 npm notice 
#10 DONE 39.1s

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
#15 exporting layers 0.8s done
#15 writing image sha256:bbd6698e172af366444d299a710c6b2beac4f5f82ae235a9801dfa787195a7e9 done
#15 naming to docker.io/library/my-ag-ui-app:latest done
#15 DONE 0.8s

View build details: docker-desktop://dashboard/build/default/default/ie2ogwotb9roe79ce15usr5nq
[2026-04-07 11:14:14] INFO: Build: Docker image built successfully (no detailed build summary available)
[2026-04-07 11:14:14] INFO: Docker image 'my-ag-ui-app:latest' built successfully
[2026-04-07 11:14:14] INFO: Docker image 'my-ag-ui-app:latest' verified successfully
[2026-04-07 11:14:14] INFO: Docker build process completed successfully
[2026-04-07 11:14:14] INFO: ✅ Step 2: Docker image build completed
[2026-04-07 11:14:14] INFO: 📋 Step 3: Tagging Docker image...
[2026-04-07 11:14:14] INFO: Starting Docker image tagging for local registry...
[2026-04-07 11:14:14] INFO: Using comprehensive tagging function with validation and error handling...
Untagged: localhost:32000/my-ag-ui-app:latest
[2026-04-07 11:14:15] Verifying tagged image exists after successful tagging...
[2026-04-07 11:14:15] ✅ Image tagging verification successful within VM
[2026-04-07 11:14:15]    Target tag localhost:32000/my-ag-ui-app:latest exists and is accessible within VM
[2026-04-07 11:14:16] ✅ Image ID verification successful - both images reference the same underlying image within VM
[2026-04-07 11:14:16] INFO: ✅ Docker image tagging for registry completed with comprehensive validation
[2026-04-07 11:14:16] INFO:    Image successfully tagged as: localhost:32000/my-ag-ui-app:latest
[2026-04-07 11:14:16] INFO: ✅ Step 3: Docker image tagging completed
[2026-04-07 11:14:16] INFO: 📋 Step 4: Setting up Microk8s registry...
Log file created: /tmp/deploy-20260407-111416.log
[2026-04-07 11:14:16] INFO: Log file initialized: /tmp/deploy-20260407-111416.log
[2026-04-07 11:14:16] INFO: 🔶 START: MICROK8S_REGISTRY_SETUP
[2026-04-07 11:14:16] INFO: Starting microk8s registry setup...
[2026-04-07 11:14:16] INFO: 🔶 REGISTRY SETUP: Starting microk8s registry setup process...
[2026-04-07 11:14:16] INFO: Checking microk8s availability...
[2026-04-07 11:14:16] INFO: ✅ microk8s is available in VM
[2026-04-07 11:14:16] INFO: Performing pre-enablement registry connectivity verification...
[2026-04-07 11:14:16] INFO: Performing pre-enablement registry connectivity check...
[2026-04-07 11:14:16] INFO: ✅ PRE-ENABLEMENT VERIFICATION: Registry already accessible
[2026-04-07 11:14:16] INFO:    JSON validation: Valid registry catalog format with repositories field
[2026-04-07 11:14:16] INFO: ✅ PRE-ENABLEMENT VERIFICATION: Registry response format is valid JSON
[2026-04-07 11:14:16] INFO: ✅ Pre-enablement registry connectivity verification completed
[2026-04-07 11:14:16] INFO: Enabling microk8s registry...
[2026-04-07 11:14:16] INFO:    Command: microk8s enable registry
[2026-04-07 11:14:16] INFO:    Executing: timeout 30 multipass exec 'my-ag-ui-app-k8s' -- microk8s enable registry
[2026-04-07 11:14:17] INFO: ✅ microk8s registry enable command completed successfully
[2026-04-07 11:14:17] INFO: Waiting 5 seconds for registry to fully start...
[2026-04-07 11:14:22] INFO: Verifying registry is running and accessible at localhost:32000...
[2026-04-07 11:14:22] INFO: ✅ REGISTRY CONNECTIVITY: SUCCESS
[2026-04-07 11:14:22] INFO:    Response time: .200882983 seconds
[2026-04-07 11:14:22] INFO:    JSON validation: Valid registry catalog format with repositories field
[2026-04-07 11:14:22] INFO: ✅ REGISTRY RESPONSE FORMAT: VALID JSON
[2026-04-07 11:14:22] INFO: ✅ Registry verification completed successfully
[2026-04-07 11:14:22] INFO:    Registry is accessible at: localhost:32000
[2026-04-07 11:14:22] INFO: ✅ REGISTRY SETUP: microk8s registry setup process completed successfully
[2026-04-07 11:14:22] INFO:    Registry status: ENABLED and VERIFIED
[2026-04-07 11:14:22] INFO:    Registry endpoint: localhost:32000
[2026-04-07 11:14:22] INFO:    Setup completed at: 2026-04-07 11:14:22
[2026-04-07 11:14:22] INFO: microk8s registry setup completed successfully
[2026-04-07 11:14:22] INFO: ✅ END: MICROK8S_REGISTRY_SETUP (duration: 6.154154371s)
[2026-04-07 11:14:22] INFO: 🎉 Microk8s registry setup completed successfully!
[2026-04-07 11:14:22] INFO:    Registry is ready for local image distribution
[2026-04-07 11:14:22] INFO:    Next step: Push Docker image to registry
[2026-04-07 11:14:22] INFO: ✅ Step 4: Microk8s registry setup completed
[2026-04-07 11:14:22] INFO: 📋 Step 5: Pushing Docker image...
Log file created: /tmp/deploy-20260407-111422.log
[2026-04-07 11:14:22] INFO: Log file initialized: /tmp/deploy-20260407-111422.log
[2026-04-07 11:14:22] INFO: Starting Docker image push to microk8s registry...
[2026-04-07 11:14:22] INFO: Starting Docker image push to microk8s registry (executing within VM)...
[2026-04-07 11:14:22] Target registry image: localhost:32000/my-ag-ui-app:latest
[2026-04-07 11:14:23] ✅ Registry verification completed successfully
[2026-04-07 11:14:23]    Registry is accessible at: localhost:32000
[2026-04-07 11:14:23] Pushing image to microk8s registry with enhanced retry logic (within VM)...
[2026-04-07 11:14:23]    Command: multipass exec my-ag-ui-app-k8s -- timeout 60 docker push localhost:32000/my-ag-ui-app:latest
[2026-04-07 11:14:23] ✅ Docker push command completed successfully within VM (attempt 1)
[2026-04-07 11:14:23] ✅ Image push completed successfully within VM
[2026-04-07 11:14:23]    Push command output summary:
The push refers to repository [localhost:32000/my-ag-ui-app]
413c136dedcf: Layer already exists
82fb5a2278a7: Layer already exists
d4fc045c9e3a: Layer already exists
a2cffe5fe30b: Layer already exists
8e1fab8d9171: Layer already exists
52a51099bdef: Layer already exists
75136c45e7ab: Layer already exists
f82bfb71098a: Layer already exists
abc5b1d00820: Layer already exists
[2026-04-07 11:14:23]    ... (output truncated, full output logged to file)
[2026-04-07 11:14:23] INFO: Starting image verification with exponential backoff retry logic (1s, 2s, 4s, 8s, 16s, 32s, 64s)...
[2026-04-07 11:14:23] INFO: Image verification attempt 1/7 (delay: 1s) at 2026-04-07 11:14:23
[2026-04-07 11:14:23] INFO: ✅ Image 'my-ag-ui-app:latest' found in registry tags list at 2026-04-07 11:14:23
[2026-04-07 11:14:23] INFO: ✅ Image verification successful - image is available in registry at 2026-04-07 11:14:23
[2026-04-07 11:14:23] INFO: ✅ Docker image push to microk8s registry completed successfully within VM at 2026-04-07 11:14:23
[2026-04-07 11:14:23] INFO:    Image: localhost:32000/my-ag-ui-app:latest
[2026-04-07 11:14:23] INFO:    Status: PUSHED and VERIFIED
[2026-04-07 11:14:23] INFO:    Registry: http://localhost:32000 (within VM)
[2026-04-07 11:14:23] INFO:    Ready for: Kubernetes deployment using registry image reference
[2026-04-07 11:14:23]    Status: PUSHED and VERIFIED (or verification pending)
[2026-04-07 11:14:23]    Registry: http://localhost:32000 (within VM)
[2026-04-07 11:14:23]    Ready for: Kubernetes deployment using registry image reference
[2026-04-07 11:14:23] INFO: ✅ Docker image push to microk8s registry completed successfully
[2026-04-07 11:14:23] INFO: ✅ Step 5: Docker image push completed
[2026-04-07 11:14:23] INFO: 📋 Step 6: Deploying to Kubernetes...
2026-04-07 11:14:23 - DEBUG: Running with full verbose output (critical failure phase)
2026-04-07 11:14:23 - DEBUG: Set DEBUG=all for explicit debugging if needed
2026-04-07 11:14:23 - Starting phase: KUBERNETES_DEPLOYMENT
[2026-04-07 11:14:23] INFO: 🚀 STARTING KUBERNETES DEPLOYMENT PHASE
[2026-04-07 11:14:23] INFO: ═══════════════════════════════════════════════════════════════════════════════
2026-04-07 11:14:23 - 📋 DEPLOYMENT DETAILS:
2026-04-07 11:14:23 -    • Manifest: k8s/deployment.yaml
2026-04-07 11:14:23 -    • Image: localhost:32000/my-ag-ui-app:latest (from local registry)
2026-04-07 11:14:23 -    • Strategy: Rolling update with pod restart
2026-04-07 11:14:23 -    • Registry: microk8s local registry
2026-04-07 11:14:23 - 
[2026-04-07 11:14:23] INFO: 🔄 STEP 1: Applying deployment manifest...
[2026-04-07 11:14:23] INFO:    • Manifest: k8s/deployment.yaml
[2026-04-07 11:14:23] INFO:    • Image: localhost:32000/my-ag-ui-app:latest (from local registry)
[2026-04-07 11:14:23] INFO:    • Strategy: Rolling update with pod restart
[2026-04-07 11:14:24] INFO:    • Registry: microk8s local registry
[2026-04-07 11:14:24] INFO: 
2026-04-07 11:14:24 - 📊 PRE-APPLOY VERIFICATION: Checking current deployment state...
2026-04-07 11:14:25 -    • Current deployment state: EXISTS
2026-04-07 11:14:25 -    • Current replicas: 1
2026-04-07 11:14:25 -    • Ready replicas: 
2026-04-07 11:14:25 -    • Updated replicas: 1
2026-04-07 11:14:25 -    • Action: UPDATE existing deployment
2026-04-07 11:14:25 - 📋 MANIFEST VALIDATION: Checking deployment.yaml file...
2026-04-07 11:14:25 - 🔍 REGISTRY PORT VALIDATION: Checking for registry port mismatches...
2026-04-07 11:14:25 -    • Registry port check: No localhost registry reference found in deployment.yaml
2026-04-07 11:14:25 -    • This might indicate image references Docker Hub instead of local registry
2026-04-07 11:14:25 -    • Expected: image: localhost:32000/my-ag-ui-app:latest
2026-04-07 11:14:25 -    • Manifest file size: 116 lines
2026-04-07 11:14:25 -    • Manifest validation: PASSED
2026-04-07 11:14:25 - 🔌 KUBERNETES CONNECTION: Verifying cluster access...
2026-04-07 11:14:25 -    • Kubernetes cluster: ACCESSIBLE
2026-04-07 11:14:25 - 🏷️  NAMESPACE VERIFICATION: Checking target namespace...
2026-04-07 11:14:25 -    • Target namespace: default
2026-04-07 11:14:25 -    • Namespace status: EXISTS and ACTIVE
2026-04-07 11:14:25 - 🚀 APPLYING DEPLOYMENT MANIFEST with detailed logging...
2026-04-07 11:14:25 -    • First validating deployment manifest with dry-run...
2026-04-07 11:14:25 -    • Command: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl apply --dry-run=server -f k8s/deployment.yaml
2026-04-07 11:14:25 -    • Expected: Validation against Kubernetes API server
[2026-04-07 11:14:25] INFO: Starting deployment manifest validation using kubectl apply --dry-run=server...
deployment.apps/my-ag-ui-app unchanged (server dry run)
[2026-04-07 11:14:26] INFO: ✅ Deployment manifest validation successful
2026-04-07 11:14:26 -    • Validation passed, proceeding with actual deployment...
2026-04-07 11:14:26 -    • Command: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl apply -f k8s/deployment.yaml
2026-04-07 11:14:26 -    • Expected: Deployment resource creation/update
2026-04-07 11:14:26 -    • Output will be captured and analyzed below...
2026-04-07 11:14:26 - 📤 KUBECTL APPLY OUTPUT (first 1000 chars):
deployment.apps/my-ag-ui-app unchanged
2026-04-07 11:14:26 - ✅ KUBECTL APPLY: Command completed successfully (exit code: 0)
2026-04-07 11:14:26 -    • Result: Deployment unchanged (no changes detected)
2026-04-07 11:14:26 -    • Action: No update needed - configuration identical
2026-04-07 11:14:26 - 🔍 POST-APPLY VERIFICATION: Checking deployment status after apply...
2026-04-07 11:14:26 -    ✅ Deployment verification: PASSED
2026-04-07 11:14:26 -       • Deployment resource exists: my-ag-ui-app
2026-04-07 11:14:27 -       • Deployment spec: {"progressDeadlineSeconds":600,"replicas":1,"revisionHistoryLimit":10,"selector":{"matchLabels":{"app":"my-ag-ui-app"}},"strategy":{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"},"template":{"metadata":{"annotations":{"kubectl.kubernetes.io/restartedAt":"2026-04-07T11:05:43-04:00"},"creationTimestamp":null,"labels":{"app":"my-ag-ui-app"}},"spec":{"containers":[{"env":[{"name":"OPENAI_API_KEY","valueFrom":{"secretKeyRef":{"key":"openai-api-key","name":"my-ag-ui-app-secrets"}}},{"name":"OPENAI_BASE_URL","valueFrom":{"secretKeyRef":{"key":"openai-base-url","name":"my-ag-ui-app-secrets"}}},{"name":"OPENAI_MODEL","valueFrom":{"secretKeyRef":{"key":"openai-model","name":"my-ag-ui-app-secrets"}}},{"name":"EMBEDDING_MODEL","valueFrom":{"secretKeyRef":{"key":"embedding-model","name":"my-ag-ui-app-secrets"}}},{"name":"LOGFIRE_TOKEN","valueFrom":{"secretKeyRef":{"key":"logfire-token","name":"my-ag-ui-app-secrets"}}},{"name":"LLM_MAX_TOKENS","valueFrom":{"configMapKeyRef":{"key":"llm-max-tokens","name":"my-ag-ui-app-config"}}},{"name":"LLM_CONTEXT_WINDOW","valueFrom":{"configMapKeyRef":{"key":"llm-context-window","name":"my-ag-ui-app-config"}}}],"image":"localhost:32000/my-ag-ui-app:latest","imagePullPolicy":"Always","livenessProbe":{"failureThreshold":3,"httpGet":{"path":"/api/health","port":3000,"scheme":"HTTP"},"initialDelaySeconds":30,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5},"name":"my-ag-ui-app","ports":[{"containerPort":3000,"name":"http","protocol":"TCP"}],"readinessProbe":{"failureThreshold":3,"httpGet":{"path":"/api/health","port":3000,"scheme":"HTTP"},"initialDelaySeconds":5,"periodSeconds":5,"successThreshold":1,"timeoutSeconds":3},"resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"terminationMessagePath":"/dev/termination-log","terminationMessagePolicy":"File"}],"dnsPolicy":"ClusterFirst","restartPolicy":"Always","schedulerName":"default-scheduler","securityContext":{},"terminationGracePeriodSeconds":30}}}
2026-04-07 11:14:27 -       • Deployment status: {"conditions":[{"lastTransitionTime":"2026-04-07T15:05:41Z","lastUpdateTime":"2026-04-07T15:05:41Z","message":"Deployment does not have minimum availability.","reason":"MinimumReplicasUnavailable","status":"False","type":"Available"},{"lastTransitionTime":"2026-04-07T15:05:41Z","lastUpdateTime":"2026-04-07T15:05:43Z","message":"ReplicaSet \"my-ag-ui-app-fff549f5c\" is progressing.","reason":"ReplicaSetUpdated","status":"True","type":"Progressing"}],"observedGeneration":2,"replicas":2,"unavailableReplicas":2,"updatedReplicas":1}
2026-04-07 11:14:27 -       ✅ Image reference verification: PASSED
2026-04-07 11:14:27 -          • Expected: localhost:32000/my-ag-ui-app:latest
2026-04-07 11:14:27 -          • Actual: localhost:32000/my-ag-ui-app:latest
2026-04-07 11:14:27 - ✅ Deployment manifest application process completed
2026-04-07 11:14:27 -    • Kubernetes deployment resource processed
2026-04-07 11:14:27 -    • Next step: Deployment restart to trigger pod creation
2026-04-07 11:14:27 - 
2026-04-07 11:14:27 - 🔄 STEP 2: Restarting deployment to trigger pod recreation...
2026-04-07 11:14:27 -    • This will create new pods using the updated registry image
2026-04-07 11:14:27 -    • Pods will pull image from localhost:32000/my-ag-ui-app:latest
deployment.apps/my-ag-ui-app restarted
2026-04-07 11:14:28 - ✅ Deployment restarted successfully
2026-04-07 11:14:28 -    • Rolling update initiated
2026-04-07 11:14:28 -    • New pods will be created using registry image
2026-04-07 11:14:28 -    • Expected: Direct pod startup (no ImagePullBackOff with registry approach)
2026-04-07 11:14:28 - 
[2026-04-07 11:14:28] INFO: Starting pod status polling for Running state (5-second intervals, 5-minute timeout)...
2026-04-07 11:14:28 - Checking pod status for Running state... (attempt 1/60)
[2026-04-07 11:14:28] INFO: Pod status: Succeeded (waiting for Running state)
2026-04-07 11:14:29 - Pod details: NAME                            READY   STATUS              RESTARTS      AGE
my-ag-ui-app-75f5d49cd6-74lt9   0/1     ContainerCreating   0             0s
my-ag-ui-app-fff549f5c-db6nm    0/1     CrashLoopBackOff    6 (25s ago)   8m45s
2026-04-07 11:14:34 - Checking pod status for Running state... (attempt 2/60)
[2026-04-07 11:14:34] INFO: ✅ Pod reached Running state successfully
[2026-04-07 11:14:34] INFO: ✅ Pod status polling completed successfully - pod is Running
[2026-04-07 11:14:34] INFO: Capturing Kubernetes pod events for analysis...
[2026-04-07 11:14:34] INFO: Analyzing events for pod: my-ag-ui-app-75f5d49cd6-74lt9
2026-04-07 11:14:34 - === POD EVENTS ===
LAST SEEN   TYPE     REASON      OBJECT                              MESSAGE
7s          Normal   Scheduled   pod/my-ag-ui-app-75f5d49cd6-74lt9   Successfully assigned default/my-ag-ui-app-75f5d49cd6-74lt9 to my-ag-ui-app-k8s
7s          Normal   Pulling     pod/my-ag-ui-app-75f5d49cd6-74lt9   Pulling image "localhost:32000/my-ag-ui-app:latest"
7s          Normal   Pulled      pod/my-ag-ui-app-75f5d49cd6-74lt9   Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 90ms (90ms including waiting). Image size: 263041608 bytes.
7s          Normal   Created     pod/my-ag-ui-app-75f5d49cd6-74lt9   Created container: my-ag-ui-app
7s          Normal   Started     pod/my-ag-ui-app-75f5d49cd6-74lt9   Started container my-ag-ui-app
2026-04-07 11:14:35 - === END POD EVENTS ===
[2026-04-07 11:14:35] INFO: Analyzing specific event types...
[2026-04-07 11:14:36] ERROR: ❌ PROBE FAILURES DETECTED (3 events):
[2026-04-07 11:14:36] ERROR:    Unhealthy events indicate readiness or liveness probe failures
LAST SEEN   TYPE      REASON      OBJECT                              MESSAGE
1s          Warning   Unhealthy   pod/my-ag-ui-app-75f5d49cd6-74lt9   Readiness probe failed: HTTP probe failed with statuscode: 404
3m41s       Warning   Unhealthy   pod/my-ag-ui-app-fff549f5c-db6nm    Readiness probe failed: HTTP probe failed with statuscode: 404
[2026-04-07 11:14:37] INFO: === POD EVENTS SUMMARY ===
[2026-04-07 11:14:37] INFO: Pull Errors: 0
[2026-04-07 11:14:37] INFO: Crash Loops: 0
[2026-04-07 11:14:37] INFO: Probe Failures: 3
[2026-04-07 11:14:37] INFO: === END POD EVENTS SUMMARY ===
[2026-04-07 11:14:37] INFO: Detailed pod description for comprehensive debugging:
Name:             my-ag-ui-app-75f5d49cd6-74lt9
Namespace:        default
Priority:         0
Service Account:  default
Node:             my-ag-ui-app-k8s/10.237.212.68
Start Time:       Tue, 07 Apr 2026 11:14:28 -0400
Labels:           app=my-ag-ui-app
                  pod-template-hash=75f5d49cd6
Annotations:      cni.projectcalico.org/containerID: 2deede794c36e732a6d76fe35badc6cccb93eb0443426ea76af083ac83835070
                  cni.projectcalico.org/podIP: 10.1.217.53/32
                  cni.projectcalico.org/podIPs: 10.1.217.53/32
                  kubectl.kubernetes.io/restartedAt: 2026-04-07T11:14:28-04:00
Status:           Running
IP:               10.1.217.53
IPs:
  IP:           10.1.217.53
Controlled By:  ReplicaSet/my-ag-ui-app-75f5d49cd6
Containers:
  my-ag-ui-app:
    Container ID:   containerd://6c191cc141a4eacf793ce2cdaad9534c80905a9a8fba61af5ab535b09a5d030d
    Image:          localhost:32000/my-ag-ui-app:latest
    Image ID:       localhost:32000/my-ag-ui-app@sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f
    Port:           3000/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Tue, 07 Apr 2026 11:14:28 -0400
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
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-4sbjc (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  kube-api-access-4sbjc:
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
  Normal   Scheduled  9s    default-scheduler  Successfully assigned default/my-ag-ui-app-75f5d49cd6-74lt9 to my-ag-ui-app-k8s
  Normal   Pulling    9s    kubelet            Pulling image "localhost:32000/my-ag-ui-app:latest"
  Normal   Pulled     9s    kubelet            Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 90ms (90ms including waiting). Image size: 263041608 bytes.
  Normal   Created    9s    kubelet            Created container: my-ag-ui-app
  Normal   Started    9s    kubelet            Started container my-ag-ui-app
  Warning  Unhealthy  2s    kubelet            Readiness probe failed: HTTP probe failed with statuscode: 404
[2026-04-07 11:14:37] ERROR: === CONTAINER LOGS (for debugging) ===
▲ Next.js 16.1.0
- Local:         http://my-ag-ui-app-75f5d49cd6-74lt9:3000
- Network:       http://my-ag-ui-app-75f5d49cd6-74lt9:3000

✓ Starting...
✓ Ready in 115ms
[2026-04-07 11:14:38] ERROR: === END CONTAINER LOGS ===
[2026-04-07 11:14:38] ERROR: === PREVIOUS CONTAINER LOGS (if available) ===
Error from server (BadRequest): previous terminated container "my-ag-ui-app" in pod "my-ag-ui-app-75f5d49cd6-74lt9" not found
[2026-04-07 11:14:38] ERROR: === END PREVIOUS CONTAINER LOGS ===
[2026-04-07 11:14:38] INFO: Starting readiness probe verification...
[2026-04-07 11:14:38] INFO: Verifying readiness probe passes before marking deployment successful...
2026-04-07 11:14:38 - Checking readiness probe status... (attempt 1/10)
[2026-04-07 11:14:38] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:14:43 - Checking readiness probe status... (attempt 2/10)
[2026-04-07 11:14:44] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:14:49 - Checking readiness probe status... (attempt 3/10)
[2026-04-07 11:14:49] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:14:54 - Checking readiness probe status... (attempt 4/10)
[2026-04-07 11:14:54] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:14:59 - Checking readiness probe status... (attempt 5/10)
[2026-04-07 11:15:00] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:15:05 - Checking readiness probe status... (attempt 6/10)
[2026-04-07 11:15:05] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:15:10 - Checking readiness probe status... (attempt 7/10)
[2026-04-07 11:15:10] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:15:15 - Checking readiness probe status... (attempt 8/10)
[2026-04-07 11:15:15] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:15:20 - Checking readiness probe status... (attempt 9/10)
[2026-04-07 11:15:21] INFO: Readiness probe not yet ready. Container status: 
2026-04-07 11:15:26 - Checking readiness probe status... (attempt 10/10)
[2026-04-07 11:15:26] INFO: Readiness probe not yet ready. Container status: 
[2026-04-07 11:15:26] ERROR: ❌ Readiness probe verification: FAILED - timeout after 10 attempts
2026-04-07 11:15:26 - Final pod status:
NAME                            READY   STATUS             RESTARTS      AGE
my-ag-ui-app-75f5d49cd6-74lt9   0/1     Running            1 (8s ago)    58s
my-ag-ui-app-fff549f5c-db6nm    0/1     CrashLoopBackOff   6 (83s ago)   9m43s
[2026-04-07 11:15:26] INFO: Capturing Kubernetes pod events for analysis...
[2026-04-07 11:15:27] INFO: Analyzing events for pod: my-ag-ui-app-75f5d49cd6-74lt9
2026-04-07 11:15:27 - === POD EVENTS ===
LAST SEEN   TYPE      REASON      OBJECT                              MESSAGE
59s         Normal    Scheduled   pod/my-ag-ui-app-75f5d49cd6-74lt9   Successfully assigned default/my-ag-ui-app-75f5d49cd6-74lt9 to my-ag-ui-app-k8s
59s         Normal    Pulled      pod/my-ag-ui-app-75f5d49cd6-74lt9   Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 90ms (90ms including waiting). Image size: 263041608 bytes.
9s          Normal    Pulling     pod/my-ag-ui-app-75f5d49cd6-74lt9   Pulling image "localhost:32000/my-ag-ui-app:latest"
9s          Normal    Created     pod/my-ag-ui-app-75f5d49cd6-74lt9   Created container: my-ag-ui-app
9s          Normal    Started     pod/my-ag-ui-app-75f5d49cd6-74lt9   Started container my-ag-ui-app
9s          Warning   Unhealthy   pod/my-ag-ui-app-75f5d49cd6-74lt9   Liveness probe failed: HTTP probe failed with statuscode: 404
9s          Normal    Killing     pod/my-ag-ui-app-75f5d49cd6-74lt9   Container my-ag-ui-app failed liveness probe, will be restarted
9s          Normal    Pulled      pod/my-ag-ui-app-75f5d49cd6-74lt9   Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 89ms (89ms including waiting). Image size: 263041608 bytes.
2s          Warning   Unhealthy   pod/my-ag-ui-app-75f5d49cd6-74lt9   Readiness probe failed: HTTP probe failed with statuscode: 404
2026-04-07 11:15:27 - === END POD EVENTS ===
[2026-04-07 11:15:27] INFO: Analyzing specific event types...
[2026-04-07 11:15:29] ERROR: ❌ PROBE FAILURES DETECTED (4 events):
[2026-04-07 11:15:29] ERROR:    Unhealthy events indicate readiness or liveness probe failures
LAST SEEN   TYPE      REASON      OBJECT                              MESSAGE
4s          Warning   Unhealthy   pod/my-ag-ui-app-75f5d49cd6-74lt9   Readiness probe failed: HTTP probe failed with statuscode: 404
11s         Warning   Unhealthy   pod/my-ag-ui-app-75f5d49cd6-74lt9   Liveness probe failed: HTTP probe failed with statuscode: 404
4m34s       Warning   Unhealthy   pod/my-ag-ui-app-fff549f5c-db6nm    Readiness probe failed: HTTP probe failed with statuscode: 404
[2026-04-07 11:15:30] INFO: === POD EVENTS SUMMARY ===
[2026-04-07 11:15:30] INFO: Pull Errors: 0
[2026-04-07 11:15:30] INFO: Crash Loops: 0
[2026-04-07 11:15:30] INFO: Probe Failures: 4
[2026-04-07 11:15:30] INFO: === END POD EVENTS SUMMARY ===
[2026-04-07 11:15:30] INFO: Detailed pod description for comprehensive debugging:
Name:             my-ag-ui-app-75f5d49cd6-74lt9
Namespace:        default
Priority:         0
Service Account:  default
Node:             my-ag-ui-app-k8s/10.237.212.68
Start Time:       Tue, 07 Apr 2026 11:14:28 -0400
Labels:           app=my-ag-ui-app
                  pod-template-hash=75f5d49cd6
Annotations:      cni.projectcalico.org/containerID: 2deede794c36e732a6d76fe35badc6cccb93eb0443426ea76af083ac83835070
                  cni.projectcalico.org/podIP: 10.1.217.53/32
                  cni.projectcalico.org/podIPs: 10.1.217.53/32
                  kubectl.kubernetes.io/restartedAt: 2026-04-07T11:14:28-04:00
Status:           Running
IP:               10.1.217.53
IPs:
  IP:           10.1.217.53
Controlled By:  ReplicaSet/my-ag-ui-app-75f5d49cd6
Containers:
  my-ag-ui-app:
    Container ID:   containerd://68b4a71ad5a8db1789f7fe8099921d65d4ad1bbd437057af232056a39187fe08
    Image:          localhost:32000/my-ag-ui-app:latest
    Image ID:       localhost:32000/my-ag-ui-app@sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f
    Port:           3000/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Tue, 07 Apr 2026 11:15:18 -0400
    Last State:     Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Tue, 07 Apr 2026 11:14:28 -0400
      Finished:     Tue, 07 Apr 2026 11:15:18 -0400
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
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-4sbjc (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  kube-api-access-4sbjc:
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
  Normal   Scheduled  62s                default-scheduler  Successfully assigned default/my-ag-ui-app-75f5d49cd6-74lt9 to my-ag-ui-app-k8s
  Normal   Pulled     62s                kubelet            Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 90ms (90ms including waiting). Image size: 263041608 bytes.
  Normal   Pulling    12s (x2 over 62s)  kubelet            Pulling image "localhost:32000/my-ag-ui-app:latest"
  Normal   Created    12s (x2 over 62s)  kubelet            Created container: my-ag-ui-app
  Normal   Started    12s (x2 over 62s)  kubelet            Started container my-ag-ui-app
  Warning  Unhealthy  12s (x3 over 32s)  kubelet            Liveness probe failed: HTTP probe failed with statuscode: 404
  Normal   Killing    12s                kubelet            Container my-ag-ui-app failed liveness probe, will be restarted
  Normal   Pulled     12s                kubelet            Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 89ms (89ms including waiting). Image size: 263041608 bytes.
  Warning  Unhealthy  5s (x11 over 55s)  kubelet            Readiness probe failed: HTTP probe failed with statuscode: 404
[2026-04-07 11:15:30] ERROR: === CONTAINER LOGS (for debugging) ===
▲ Next.js 16.1.0
- Local:         http://my-ag-ui-app-75f5d49cd6-74lt9:3000
- Network:       http://my-ag-ui-app-75f5d49cd6-74lt9:3000

✓ Starting...
✓ Ready in 119ms
[2026-04-07 11:15:30] ERROR: === END CONTAINER LOGS ===
[2026-04-07 11:15:30] ERROR: === PREVIOUS CONTAINER LOGS (if available) ===
▲ Next.js 16.1.0
- Local:         http://my-ag-ui-app-75f5d49cd6-74lt9:3000
- Network:       http://my-ag-ui-app-75f5d49cd6-74lt9:3000

✓ Starting...
✓ Ready in 115ms
[2026-04-07 11:15:31] ERROR: === END PREVIOUS CONTAINER LOGS ===
2026-04-07 11:15:31 - Container status details:
[{"allocatedResources":{"cpu":"100m","memory":"256Mi"},"containerID":"containerd://68b4a71ad5a8db1789f7fe8099921d65d4ad1bbd437057af232056a39187fe08","image":"localhost:32000/my-ag-ui-app:latest","imageID":"localhost:32000/my-ag-ui-app@sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f","lastState":{"terminated":{"containerID":"containerd://6c191cc141a4eacf793ce2cdaad9534c80905a9a8fba61af5ab535b09a5d030d","exitCode":0,"finishedAt":"2026-04-07T15:15:18Z","reason":"Completed","startedAt":"2026-04-07T15:14:28Z"}},"name":"my-ag-ui-app","ready":false,"resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"restartCount":1,"started":true,"state":{"running":{"startedAt":"2026-04-07T15:15:18Z"}},"volumeMounts":[{"mountPath":"/var/run/secrets/kubernetes.io/serviceaccount","name":"kube-api-access-4sbjc","readOnly":true,"recursiveReadOnly":"Disabled"}]}]2026-04-07 11:15:31 - Testing health check endpoint accessibility...
2026-04-07 11:15:31 - Testing HTTP health check endpoint from within cluster...
<!DOCTYPE html><!--Kmtd7qiqKK1KdAxFjFCI0--><html lang="en"><head><meta charSet="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/><link rel="stylesheet" href="/_next/static/chunks/580c672ba41ef531.css" data-precedence="next"/><link rel="preload" as="script" fetchPriority="low" href="/_next/static/chunks/9f7c91181cf10269.js"/><script src="/_next/static/chunks/81a5dd5ffbf2a323.js" async=""></script><script src="/_next/static/chunks/eb31826f842ed5cc.js" async=""></script><script src="/_next/static/chunks/turbopack-ae70d51303cf8417.js" async=""></script><script src="/_next/static/chunks/98445878ec3e077f.js" async=""></script><script src="/_next/static/chunks/64c2d675816eb5ba.js" async=""></script><script src="/_next/static/chunks/87a5e5464e54428a.js" async=""></script><script src="/_next/static/chunks/915db95d511f2aa4.js" async=""></script><script src="/_next/static/chunks/8d3945c9ea1274d1.js" async=""></script><script src="/_next/static/chunks/570806598ba172cc.js" async=""></script><meta name="robots" content="noindex"/><title>404: This page could not be found.</title><title>Create Next App</title><meta name="description" content="Generated by create next app"/><link rel="icon" href="/favicon.ico?favicon.0b3bf435.ico" sizes="256x256" type="image/x-icon"/><script src="/_next/static/chunks/a6dad97d9634a72d.js" noModule=""></script></head><body class="antialiased"><div hidden=""><!--$--><!--/$--></div><div style="font-family:system-ui,&quot;Segoe UI&quot;,Roboto,Helvetica,Arial,sans-serif,&quot;Apple Color Emoji&quot;,&quot;Segoe UI Emoji&quot;;height:100vh;text-align:center;display:flex;flex-direction:column;align-items:center;justify-content:center"><div><style>body{color:#000;background:#fff;margin:0}.next-error-h1{border-right:1px solid rgba(0,0,0,.3)}@media (prefers-color-scheme:dark){body{color:#fff;background:#000}.next-error-h1{border-right:1px solid rgba(255,255,255,.3)}}</style><h1 class="next-error-h1" style="display:inline-block;margin:0 20px 0 0;padding:0 23px 0 0;font-size:24px;font-weight:500;vertical-align:top;line-height:49px">404</h1><div style="display:inline-block"><h2 style="font-size:14px;font-weight:400;line-height:49px;margin:0">This page could not be found.</h2></div></div></div><!--$--><!--/$--><script src="/_next/static/chunks/9f7c91181cf10269.js" id="_R_" async=""></script><script>(self.__next_f=self.__next_f||[]).push([0])</script><script>self.__next_f.push([1,"1:\"$Sreact.fragment\"\n2:I[563542,[\"/_next/static/chunks/98445878ec3e077f.js\",\"/_next/static/chunks/64c2d675816eb5ba.js\",\"/_next/static/chunks/87a5e5464e54428a.js\",\"/_next/static/chunks/915db95d511f2aa4.js\",\"/_next/static/chunks/8d3945c9ea1274d1.js\"],\"CopilotKit\"]\n3:I[339756,[\"/_next/static/chunks/570806598ba172cc.js\"],\"default\"]\n4:I[837457,[\"/_next/static/chunks/570806598ba172cc.js\"],\"default\"]\n5:I[897367,[\"/_next/static/chunks/570806598ba172cc.js\"],\"OutletBoundary\"]\n6:\"$Sreact.suspense\"\n8:I[897367,[\"/_next/static/chunks/570806598ba172cc.js\"],\"ViewportBoundary\"]\na:I[897367,[\"/_next/static/chunks/570806598ba172cc.js\"],\"MetadataBoundary\"]\nc:I[168027,[\"/_next/static/chunks/570806598ba172cc.js\"],\"default\"]\n:HL[\"/_next/static/chunks/580c672ba41ef531.css\",\"style\"]\n"])</script><script>self.__next_f.push([1,"0:{\"P\":null,\"b\":\"Kmtd7qiqKK1KdAxFjFCI0\",\"c\":[\"\",\"_not-found\"],\"q\":\"\",\"i\":false,\"f\":[[[\"\",{\"children\":[\"/_not-found\",{\"children\":[\"__PAGE__\",{}]}]},\"$undefined\",\"$undefined\",true],[[\"$\",\"$1\",\"c\",{\"children\":[[[\"$\",\"link\",\"0\",{\"rel\":\"stylesheet\",\"href\":\"/_next/static/chunks/580c672ba41ef531.css\",\"precedence\":\"next\",\"crossOrigin\":\"$undefined\",\"nonce\":\"$undefined\"}],[\"$\",\"script\",\"script-0\",{\"src\":\"/_next/static/chunks/98445878ec3e077f.js\",\"async\":true,\"nonce\":\"$undefined\"}],[\"$\",\"script\",\"script-1\",{\"src\":\"/_next/static/chunks/64c2d675816eb5ba.js\",\"async\":true,\"nonce\":\"$undefined\"}],[\"$\",\"script\",\"script-2\",{\"src\":\"/_next/static/chunks/87a5e5464e54428a.js\",\"async\":true,\"nonce\":\"$undefined\"}],[\"$\",\"script\",\"script-3\",{\"src\":\"/_next/static/chunks/915db95d511f2aa4.js\",\"async\":true,\"nonce\":\"$undefined\"}],[\"$\",\"script\",\"script-4\",{\"src\":\"/_next/static/chunks/8d3945c9ea1274d1.js\",\"async\":true,\"nonce\":\"$undefined\"}]],[\"$\",\"html\",null,{\"lang\":\"en\",\"children\":[\"$\",\"body\",null,{\"className\":\"antialiased\",\"children\":[\"$\",\"$L2\",null,{\"runtimeUrl\":\"/api/copilotkit\",\"agent\":\"my_agent\",\"showDevConsole\":false,\"enableInspector\":false,\"children\":[\"$\",\"$L3\",null,{\"parallelRouterKey\":\"children\",\"error\":\"$undefined\",\"errorStyles\":\"$undefined\",\"errorScripts\":\"$undefined\",\"template\":[\"$\",\"$L4\",null,{}],\"templateStyles\":\"$undefined\",\"templateScripts\":\"$undefined\",\"notFound\":[[[\"$\",\"title\",null,{\"children\":\"404: This page could not be found.\"}],[\"$\",\"div\",null,{\"style\":{\"fontFamily\":\"system-ui,\\\"Segoe UI\\\",Roboto,Helvetica,Arial,sans-serif,\\\"Apple Color Emoji\\\",\\\"Segoe UI Emoji\\\"\",\"height\":\"100vh\",\"textAlign\":\"center\",\"display\":\"flex\",\"flexDirection\":\"column\",\"alignItems\":\"center\",\"justifyContent\":\"center\"},\"children\":[\"$\",\"div\",null,{\"children\":[[\"$\",\"style\",null,{\"dangerouslySetInnerHTML\":{\"__html\":\"body{color:#000;background:#fff;margin:0}.next-error-h1{border-right:1px solid rgba(0,0,0,.3)}@media (prefers-color-scheme:dark){body{color:#fff;background:#000}.next-error-h1{border-right:1px solid rgba(255,255,255,.3)}}\"}}],[\"$\",\"h1\",null,{\"className\":\"next-error-h1\",\"style\":{\"display\":\"inline-block\",\"margin\":\"0 20px 0 0\",\"padding\":\"0 23px 0 0\",\"fontSize\":24,\"fontWeight\":500,\"verticalAlign\":\"top\",\"lineHeight\":\"49px\"},\"children\":404}],[\"$\",\"div\",null,{\"style\":{\"display\":\"inline-block\"},\"children\":[\"$\",\"h2\",null,{\"style\":{\"fontSize\":14,\"fontWeight\":400,\"lineHeight\":\"49px\",\"margin\":0},\"children\":\"This page could not be found.\"}]}]]}]}]],[]],\"forbidden\":\"$undefined\",\"unauthorized\":\"$undefined\"}]}]}]}]]}],{\"children\":[[\"$\",\"$1\",\"c\",{\"children\":[null,[\"$\",\"$L3\",null,{\"parallelRouterKey\":\"children\",\"error\":\"$undefined\",\"errorStyles\":\"$undefined\",\"errorScripts\":\"$undefined\",\"template\":[\"$\",\"$L4\",null,{}],\"templateStyles\":\"$undefined\",\"templateScripts\":\"$undefined\",\"notFound\":\"$undefined\",\"forbidden\":\"$undefined\",\"unauthorized\":\"$undefined\"}]]}],{\"children\":[[\"$\",\"$1\",\"c\",{\"children\":[[[\"$\",\"title\",null,{\"children\":\"404: This page could not be found.\"}],[\"$\",\"div\",null,{\"style\":\"$0:f:0:1:0:props:children:1:props:children:props:children:props:children:props:notFound:0:1:props:style\",\"children\":[\"$\",\"div\",null,{\"children\":[[\"$\",\"style\",null,{\"dangerouslySetInnerHTML\":{\"__html\":\"body{color:#000;background:#fff;margin:0}.next-error-h1{border-right:1px solid rgba(0,0,0,.3)}@media (prefers-color-scheme:dark){body{color:#fff;background:#000}.next-error-h1{border-right:1px solid rgba(255,255,255,.3)}}\"}}],[\"$\",\"h1\",null,{\"className\":\"next-error-h1\",\"style\":\"$0:f:0:1:0:props:children:1:props:children:props:children:props:children:props:notFound:0:1:props:children:props:children:1:props:style\",\"children\":404}],[\"$\",\"div\",null,{\"style\":\"$0:f:0:1:0:props:children:1:props:children:props:children:props:children:props:notFound:0:1:props:children:props:children:2:props:style\",\"children\":[\"$\",\"h2\",null,{\"style\":\"$0:f:0:1:0:props:children:1:props:children:props:children:props:children:props:notFound:0:1:props:children:props:children:2:props:children:props:style\",\"children\":\"This page could not be found.\"}]}]]}]}]],null,[\"$\",\"$L5\",null,{\"children\":[\"$\",\"$6\",null,{\"name\":\"Next.MetadataOutlet\",\"children\":\"$@7\"}]}]]}],{},null,false,false]},null,false,false]},null,false,false],[\"$\",\"$1\",\"h\",{\"children\":[[\"$\",\"meta\",null,{\"name\":\"robots\",\"content\":\"noindex\"}],[\"$\",\"$L8\",null,{\"children\":\"$L9\"}],[\"$\",\"div\",null,{\"hidden\":true,\"children\":[\"$\",\"$La\",null,{\"children\":[\"$\",\"$6\",null,{\"name\":\"Next.Metadata\",\"children\":\"$Lb\"}]}]}],null]}],false]],\"m\":\"$undefined\",\"G\":[\"$c\",\"$undefined\"],\"S\":true}\n"])</script><script>self.__next_f.push([1,"9:[[\"$\",\"meta\",\"0\",{\"charSet\":\"utf-8\"}],[\"$\",\"meta\",\"1\",{\"name\":\"viewport\",\"content\":\"width=device-width, initial-scale=1\"}]]\n"])</script><script>self.__next_f.push([1,"d:I[27201,[\"/_next/static/chunks/570806598ba172cc.js\"],\"IconMark\"]\n7:null\nb:[[\"$\",\"title\",\"0\",{\"children\":\"Create Next App\"}],[\"$\",\"meta\",\"1\",{\"name\":\"description\",\"content\":\"Generated by create next app\"}],[\"$\",\"link\",\"2\",{\"rel\":\"icon\",\"href\":\"/favicon.ico?favicon.0b3bf435.ico\",\"sizes\":\"256x256\",\"type\":\"image/x-icon\"}],[\"$\",\"$Ld\",\"3\",{}]]\n"])</script></body></html>pod "temp-health-test" deleted
[2026-04-07 11:15:35] ══════════════════════════════════════════════════════════════════════════════
[2026-04-07 11:15:35]                          STRUCTURED ERROR
[2026-04-07 11:15:35] ══════════════════════════════════════════════════════════════════════════════
[2026-04-07 11:15:35] ERROR TYPE: READINESS_PROBE_TIMEOUT
[2026-04-07 11:15:35] DIAGNOSTIC: Readiness probe did not pass within 5-minute timeout
[2026-04-07 11:15:35] COMMON CAUSES: Application not ready to serve traffic, health check endpoint not responding, or application startup issues
[2026-04-07 11:15:35] RECOVERY: 1. Check application logs: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl logs -l app=my-ag-ui-app, 2. Verify health check endpoint: curl http://<pod-ip>:3000/api/health, 3. Check deployment manifest for correct probe configuration, 4. Verify application is properly starting and not crashing
[2026-04-07 11:15:35] ══════════════════════════════════════════════════════════════════════════════
[2026-04-07 11:15:35] ERROR: ❌ READINESS PROBE VERIFICATION FAILED: Application not ready to serve traffic
[2026-04-07 11:15:35] ══════════════════════════════════════════════════════════════════════════════
[2026-04-07 11:15:35]                          STRUCTURED ERROR
[2026-04-07 11:15:35] ══════════════════════════════════════════════════════════════════════════════
[2026-04-07 11:15:35] ERROR TYPE: READINESS_PROBE_FAILURE
[2026-04-07 11:15:35] DIAGNOSTIC: Readiness probe verification failed
[2026-04-07 11:15:35] COMMON CAUSES: Application failed readiness probe verification and is not ready to serve traffic
[2026-04-07 11:15:35] RECOVERY: 1. Check application logs: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl logs -l app=my-ag-ui-app, 2. Verify health check endpoint: curl http://<pod-ip>:3000/api/health, 3. Check deployment manifest probe configuration, 4. Verify application is properly starting and not crashing
[2026-04-07 11:15:35] ══════════════════════════════════════════════════════════════════════════════
2026-04-07 11:15:35 - === DETAILED POD INFORMATION FOR READINESS FAILURE ===
[2026-04-07 11:15:35] ERROR: ❌ STEP 6 FAILED: Failed to deploy to Kubernetes
[2026-04-07 11:15:35] ERROR: 🔄 INITIATING ROLLBACK PROCEDURE
[2026-04-07 11:15:35] ERROR: Deployment failed - attempting to restore previous state
[2026-04-07 11:15:35] ERROR: ❌ ROLLBACK FAILED: No backup deployment manifest found (k8s/deployment.yaml.backup)
[2026-04-07 11:15:35] ERROR:    Cannot perform automatic rollback - manual intervention required
