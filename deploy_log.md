Log file created: /tmp/deploy-20260327-222349.log
[2026-03-27 22:23:49] INFO: Log file initialized: /tmp/deploy-20260327-222349.log
[2026-03-27 22:23:49] INFO: Starting log cleanup process
[2026-03-27 22:23:49] INFO: Found 42 deployment log files to check
[2026-03-27 22:23:49] INFO: Removing 32 old log files (keeping last 10)
[2026-03-27 22:23:49] INFO: Removed old log file: /tmp/deploy-20260327-180613.log
[2026-03-27 22:23:49] INFO: Removed old log file: /tmp/deploy-20260327-180612.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-180553.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-180522.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-180210.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-180112.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175940.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175906.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175900.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175858.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175856.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175854.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175754.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175726.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175625.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175518.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175454.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175435.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175424.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175308.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175306.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175259.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175202.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175149.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-175024.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-132820.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-132309.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-132255.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-131932.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-131446.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-131156.log
[2026-03-27 22:23:50] INFO: Removed old log file: /tmp/deploy-20260327-130836.log
[2026-03-27 22:23:50] INFO: Log cleanup process completed
[2026-03-27 22:23:50] INFO: 🚀 STARTING DEPLOYMENT PIPELINE
[2026-03-27 22:23:50] INFO: Environment: development
[2026-03-27 22:23:50] INFO: Verbose mode: false
[2026-03-27 22:23:50] INFO: 📋 Step 1: Setting up Kubernetes secrets...
Log file created: /tmp/deploy-20260327-222350.log
[2026-03-27 22:23:50] INFO: Log file initialized: /tmp/deploy-20260327-222350.log
[2026-03-27 22:23:50] INFO: Starting Kubernetes secrets setup...
[2026-03-27 22:23:50] INFO: k8s directory found: /home/ncheaz/git/my-ag-ui-app/k8s/
[2026-03-27 22:23:50] INFO: setup-secrets.sh script found: /home/ncheaz/git/my-ag-ui-app/k8s/setup-secrets.sh
[2026-03-27 22:23:50] INFO: Setting up environment variables for secrets creation...
[2026-03-27 22:23:50] INFO: Loading environment variables from .env file...
[2026-03-27 22:23:50] INFO: Set environment variable: OPENAI_API_KEY
[2026-03-27 22:23:50] INFO: Set environment variable: OPENAI_BASE_URL
[2026-03-27 22:23:50] INFO: Set environment variable: OPENAI_MODEL
[2026-03-27 22:23:50] INFO: Set environment variable: LLM_MAX_TOKENS
[2026-03-27 22:23:50] INFO: Set environment variable: LLM_CONTEXT_WINDOW
[2026-03-27 22:23:50] INFO: Set environment variable: EMBEDDING_MODEL
[2026-03-27 22:23:50] INFO: All required environment variables are set
[2026-03-27 22:23:50] INFO: Running secrets setup script to generate YAML file...
[2026-03-27 22:23:50] Setting up Kubernetes secrets...
[2026-03-27 22:23:50] Reading environment variables...
[2026-03-27 22:23:50] Encoding values to base64...
[2026-03-27 22:23:50] Generating Kubernetes secrets file...
[2026-03-27 22:23:50] Validating generated secrets file against Kubernetes API server...
secret/my-ag-ui-app-secrets unchanged (server dry run)
configmap/my-ag-ui-app-config unchanged (server dry run)
[2026-03-27 22:23:52] ✅ Kubernetes secrets file generated successfully: k8s/secrets.yaml
[2026-03-27 22:23:52] INFO: Kubernetes secrets YAML file generated successfully: k8s/secrets.yaml
[2026-03-27 22:23:52] INFO: Copying secrets file to VM for Kubernetes operations...
[2026-03-27 22:23:52] INFO: Secrets file copied to VM successfully
[2026-03-27 22:23:52] INFO: Validating secrets YAML against Kubernetes API server...
secret/my-ag-ui-app-secrets unchanged (server dry run)
configmap/my-ag-ui-app-config unchanged (server dry run)
[2026-03-27 22:23:53] INFO: Secrets YAML validation passed
[2026-03-27 22:23:53] INFO: Applying secrets to Kubernetes cluster...
secret/my-ag-ui-app-secrets unchanged
configmap/my-ag-ui-app-config unchanged
[2026-03-27 22:23:53] INFO: Kubernetes secrets setup completed successfully
[2026-03-27 22:23:53] INFO: ✅ Step 1: Kubernetes secrets setup completed
[2026-03-27 22:23:53] INFO: 📋 Step 2: Building Docker image...
[2026-03-27 22:23:53] INFO: Starting Docker build process
[2026-03-27 22:23:53] Starting dependency validation...
[2026-03-27 22:23:53] Checking if package.json and package-lock.json are in sync...
[2026-03-27 22:23:56] ✅ SUCCESS: package.json and package-lock.json are synchronized
[2026-03-27 22:23:56]    Dependencies are ready for reproducible Docker builds.
[2026-03-27 22:23:56] INFO: Starting Docker image build for 'my-ag-ui-app:latest'...
[2026-03-27 22:24:47] INFO: Docker build completed successfully
[2026-03-27 22:24:47] INFO: Build output:
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 4.79kB done
#1 DONE 0.0s

#2 [internal] load metadata for docker.io/library/node:20.12.0-alpine
#2 DONE 0.4s

#3 [internal] load .dockerignore
#3 transferring context: 128B done
#3 DONE 0.0s

#4 [builder 1/6] FROM docker.io/library/node:20.12.0-alpine@sha256:ef3f47741e161900ddd07addcaca7e76534a9205e4cd73b2ed091ba339004a75
#4 DONE 0.0s

#5 [internal] load build context
#5 transferring context: 185.20kB 0.1s done
#5 DONE 0.1s

#6 [builder 2/6] WORKDIR /app
#6 CACHED

#7 [builder 3/6] COPY package.json package-lock.json ./
#7 CACHED

#8 [builder 4/6] RUN echo "=== DEPENDENCY INSTALLATION ===" &&     echo "Starting npm ci (reproducible install)..." &&     if npm ci --ignore-scripts; then         echo "✅ SUCCESS: npm ci completed - using reproducible dependencies from lock file";     else         echo "⚠️  WARNING: npm ci failed - lock files are out of sync";         echo "🔄 FALLING BACK to npm install to continue build...";         echo "ℹ️  NOTE: This allows deployment but reduces build reproducibility";         echo "🔧 FIX: Run 'npm install' locally and commit updated package-lock.json";         npm install --ignore-scripts;         echo "✅ SUCCESS: npm install completed - build continuing with fallback dependencies";     fi &&     echo "=== DEPENDENCY INSTALLATION COMPLETED ===" &&     npm cache clean --force
#8 CACHED

#9 [builder 5/6] COPY . .
#9 DONE 1.8s

#10 [builder 6/6] RUN npm run build
#10 0.483 
#10 0.483 > pydantic-ai-starter@0.1.0 build
#10 0.483 > next build
#10 0.483 
#10 1.417 Attention: Next.js now collects completely anonymous telemetry regarding usage.
#10 1.418 This information is used to shape Next.js' roadmap and prioritize features.
#10 1.418 You can learn more, including how to opt-out if you'd not like to participate in this anonymous program, by visiting the following URL:
#10 1.418 https://nextjs.org/telemetry
#10 1.418 
#10 1.428 ▲ Next.js 16.1.0 (Turbopack)
#10 1.428 
#10 1.483   Creating an optimized production build ...
#10 34.82 ✓ Compiled successfully in 32.8s
#10 34.98   Running TypeScript ...
#10 38.41   Collecting page data using 11 workers ...
#10 39.49   Generating static pages using 11 workers (0/6) ...
#10 39.69   Generating static pages using 11 workers (1/6) 
#10 40.16   Generating static pages using 11 workers (2/6) 
#10 40.18   Generating static pages using 11 workers (4/6) 
#10 40.77 ✓ Generating static pages using 11 workers (6/6) in 1274.1ms
#10 40.77   Finalizing page optimization ...
#10 40.99 
#10 40.99 Route (app)
#10 40.99 ┌ ○ /
#10 40.99 ├ ○ /_not-found
#10 40.99 ├ ƒ /api/copilotkit
#10 40.99 └ ƒ /api/health
#10 40.99 
#10 40.99 
#10 40.99 ○  (Static)   prerendered as static content
#10 40.99 ƒ  (Dynamic)  server-rendered on demand
#10 40.99 
#10 DONE 41.8s

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
#15 writing image sha256:0a9b2c9296c9afc037efdb1abce7ba8feae80294760bbb433b6f2cef851c6976 done
#15 naming to docker.io/library/my-ag-ui-app:latest done
#15 DONE 0.8s

View build details: docker-desktop://dashboard/build/default/default/1x03t2w8wwf0983e9v8xl8o64

 [33m4 warnings found (use docker --debug to expand):
[0m - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "OPENAI_API_KEY") (line 78)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "OPENAI_API_KEY") (line 81)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "LOGFIRE_TOKEN") (line 94)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "LOGFIRE_TOKEN") (line 95)
[2026-03-27 22:24:47] INFO: Build: Docker image built successfully (no detailed build summary available)
[2026-03-27 22:24:47] INFO: Docker image 'my-ag-ui-app:latest' built successfully
[2026-03-27 22:24:47] INFO: Docker image 'my-ag-ui-app:latest' verified successfully
[2026-03-27 22:24:47] INFO: Docker build process completed successfully
[2026-03-27 22:24:47] INFO: ✅ Step 2: Docker image build completed
[2026-03-27 22:24:47] INFO: 📋 Step 3: Tagging Docker image...
[2026-03-27 22:24:47] INFO: Starting Docker image tagging for local registry...
[2026-03-27 22:24:47] INFO: Using comprehensive tagging function with validation and error handling...
Untagged: localhost:32000/my-ag-ui-app:latest
[2026-03-27 22:24:49] Verifying tagged image exists after successful tagging...
[2026-03-27 22:24:49] ✅ Image tagging verification successful within VM
[2026-03-27 22:24:49]    Target tag localhost:32000/my-ag-ui-app:latest exists and is accessible within VM
[2026-03-27 22:24:50] ✅ Image ID verification successful - both images reference the same underlying image within VM
[2026-03-27 22:24:50] INFO: ✅ Docker image tagging for registry completed with comprehensive validation
[2026-03-27 22:24:50] INFO:    Image successfully tagged as: localhost:32000/my-ag-ui-app:latest
[2026-03-27 22:24:50] INFO: ✅ Step 3: Docker image tagging completed
[2026-03-27 22:24:50] INFO: 📋 Step 4: Setting up Microk8s registry...
Log file created: /tmp/deploy-20260327-222450.log
[2026-03-27 22:24:50] INFO: Log file initialized: /tmp/deploy-20260327-222450.log
[2026-03-27 22:24:50] INFO: 🔶 START: MICROK8S_REGISTRY_SETUP
[2026-03-27 22:24:50] INFO: Starting microk8s registry setup...
[2026-03-27 22:24:50] INFO: 🔶 REGISTRY SETUP: Starting microk8s registry setup process...
[2026-03-27 22:24:50] INFO: Checking microk8s availability...
[2026-03-27 22:24:50] INFO: ✅ microk8s is available in VM
[2026-03-27 22:24:50] INFO: Performing pre-enablement registry connectivity verification...
[2026-03-27 22:24:50] INFO: Performing pre-enablement registry connectivity check...
[2026-03-27 22:24:51] INFO: ✅ PRE-ENABLEMENT VERIFICATION: Registry already accessible
[2026-03-27 22:24:51] INFO:    JSON validation: Valid registry catalog format with repositories field
[2026-03-27 22:24:51] INFO: ✅ PRE-ENABLEMENT VERIFICATION: Registry response format is valid JSON
[2026-03-27 22:24:51] INFO: ✅ Pre-enablement registry connectivity verification completed
[2026-03-27 22:24:51] INFO: Enabling microk8s registry...
[2026-03-27 22:24:51] INFO:    Command: microk8s enable registry
[2026-03-27 22:24:51] INFO:    Executing: timeout 30 multipass exec 'my-ag-ui-app-k8s' -- microk8s enable registry
[2026-03-27 22:24:51] INFO: ✅ microk8s registry enable command completed successfully
[2026-03-27 22:24:51] INFO: Waiting 5 seconds for registry to fully start...
[2026-03-27 22:24:56] INFO: Verifying registry is running and accessible at localhost:32000...
[2026-03-27 22:24:57] INFO: ✅ REGISTRY CONNECTIVITY: SUCCESS
[2026-03-27 22:24:57] INFO:    Response time: .369128492 seconds
[2026-03-27 22:24:57] INFO:    JSON validation: Valid registry catalog format with repositories field
[2026-03-27 22:24:57] INFO: ✅ REGISTRY RESPONSE FORMAT: VALID JSON
[2026-03-27 22:24:57] INFO: ✅ Registry verification completed successfully
[2026-03-27 22:24:57] INFO:    Registry is accessible at: localhost:32000
[2026-03-27 22:24:57] INFO: ✅ REGISTRY SETUP: microk8s registry setup process completed successfully
[2026-03-27 22:24:57] INFO:    Registry status: ENABLED and VERIFIED
[2026-03-27 22:24:57] INFO:    Registry endpoint: localhost:32000
[2026-03-27 22:24:57] INFO:    Setup completed at: 2026-03-27 22:24:57
[2026-03-27 22:24:57] INFO: microk8s registry setup completed successfully
[2026-03-27 22:24:57] INFO: ✅ END: MICROK8S_REGISTRY_SETUP (duration: 6.418113596s)
[2026-03-27 22:24:57] INFO: 🎉 Microk8s registry setup completed successfully!
[2026-03-27 22:24:57] INFO:    Registry is ready for local image distribution
[2026-03-27 22:24:57] INFO:    Next step: Push Docker image to registry
[2026-03-27 22:24:57] INFO: ✅ Step 4: Microk8s registry setup completed
[2026-03-27 22:24:57] INFO: 📋 Step 5: Pushing Docker image...
Log file created: /tmp/deploy-20260327-222457.log
[2026-03-27 22:24:57] INFO: Log file initialized: /tmp/deploy-20260327-222457.log
[2026-03-27 22:24:57] INFO: Starting Docker image push to microk8s registry...
[2026-03-27 22:24:57] INFO: Starting Docker image push to microk8s registry (executing within VM)...
[2026-03-27 22:24:57] Target registry image: localhost:32000/my-ag-ui-app:latest
[2026-03-27 22:24:57] ✅ Registry verification completed successfully
[2026-03-27 22:24:57]    Registry is accessible at: localhost:32000
[2026-03-27 22:24:57] Pushing image to microk8s registry with enhanced retry logic (within VM)...
[2026-03-27 22:24:57]    Command: multipass exec my-ag-ui-app-k8s -- timeout 60 docker push localhost:32000/my-ag-ui-app:latest
[2026-03-27 22:24:58] ✅ Docker push command completed successfully within VM (attempt 1)
[2026-03-27 22:24:58] ✅ Image push completed successfully within VM
[2026-03-27 22:24:58]    Push command output summary:
The push refers to repository [localhost:32000/my-ag-ui-app]
f82bfb71098a: Layer already exists
abc5b1d00820: Layer already exists
52a51099bdef: Layer already exists
82fb5a2278a7: Layer already exists
a2cffe5fe30b: Layer already exists
75136c45e7ab: Layer already exists
d4fc045c9e3a: Layer already exists
8e1fab8d9171: Layer already exists
413c136dedcf: Layer already exists
[2026-03-27 22:24:58]    ... (output truncated, full output logged to file)
[2026-03-27 22:24:58] INFO: Starting image verification with exponential backoff retry logic (1s, 2s, 4s, 8s, 16s, 32s, 64s)...
[2026-03-27 22:24:58] INFO: Image verification attempt 1/7 (delay: 1s) at 2026-03-27 22:24:58
[2026-03-27 22:24:58] WARNING: Image not found in registry catalog on attempt 1 at 2026-03-27 22:24:58
[2026-03-27 22:24:58] INFO: Waiting 1s before next verification attempt (exponential backoff) at 2026-03-27 22:24:58
[2026-03-27 22:24:59] INFO: Image verification attempt 2/7 (delay: 2s) at 2026-03-27 22:24:59
[2026-03-27 22:24:59] WARNING: Image not found in registry catalog on attempt 2 at 2026-03-27 22:24:59
[2026-03-27 22:24:59] INFO: Waiting 2s before next verification attempt (exponential backoff) at 2026-03-27 22:24:59
[2026-03-27 22:25:01] INFO: Image verification attempt 3/7 (delay: 4s) at 2026-03-27 22:25:01
[2026-03-27 22:25:01] WARNING: Image not found in registry catalog on attempt 3 at 2026-03-27 22:25:01
[2026-03-27 22:25:01] INFO: Waiting 4s before next verification attempt (exponential backoff) at 2026-03-27 22:25:01
[2026-03-27 22:25:05] INFO: Image verification attempt 4/7 (delay: 8s) at 2026-03-27 22:25:05
[2026-03-27 22:25:05] WARNING: Image not found in registry catalog on attempt 4 at 2026-03-27 22:25:05
[2026-03-27 22:25:05] INFO: Waiting 8s before next verification attempt (exponential backoff) at 2026-03-27 22:25:05
[2026-03-27 22:25:13] INFO: Image verification attempt 5/7 (delay: 16s) at 2026-03-27 22:25:13
[2026-03-27 22:25:13] WARNING: Image not found in registry catalog on attempt 5 at 2026-03-27 22:25:13
[2026-03-27 22:25:13] INFO: Waiting 16s before next verification attempt (exponential backoff) at 2026-03-27 22:25:13
[2026-03-27 22:25:29] INFO: Image verification attempt 6/7 (delay: 32s) at 2026-03-27 22:25:29
[2026-03-27 22:25:29] WARNING: Image not found in registry catalog on attempt 6 at 2026-03-27 22:25:29
[2026-03-27 22:25:29] INFO: Waiting 32s before next verification attempt (exponential backoff) at 2026-03-27 22:25:29
[2026-03-27 22:26:01] INFO: Image verification attempt 7/7 (delay: 64s) at 2026-03-27 22:26:01
[2026-03-27 22:26:01] WARNING: Image not found in registry catalog on attempt 7 at 2026-03-27 22:26:01
[2026-03-27 22:26:01] ERROR: ❌ ERROR: Image verification failed - image not found in registry catalog after 7 attempts at 2026-03-27 22:26:01
[2026-03-27 22:26:01] ERROR:    The push operation completed successfully, but verification could not confirm registry availability
[2026-03-27 22:26:01] ERROR:    This may be due to registry catalog update delays or registry issues
[2026-03-27 22:26:01] ERROR: 
[2026-03-27 22:26:01] ERROR: MANUAL VERIFICATION STEPS:
[2026-03-27 22:26:01] ERROR: 1. Check registry catalog: curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list
[2026-03-27 22:26:01] ERROR: 2. Check registry status: verify_microk8s_registry
[2026-03-27 22:26:01] ERROR: 3. List images in registry: curl -s http://localhost:32000/v2/_catalog
[2026-03-27 22:26:01] ERROR: 4. The image should be available despite verification failure - registry catalog may be delayed
[2026-03-27 22:26:01] ERROR: 
[2026-03-27 22:26:01] ERROR: If the image is actually in the registry but verification failed, you can:
[2026-03-27 22:26:01] ERROR: 1. Proceed with deployment (the image is likely there)
[2026-03-27 22:26:01] ERROR: 2. Or wait a few minutes and retry the verification
[2026-03-27 22:26:01] ══════════════════════════════════════════════════════════════════════════════
[2026-03-27 22:26:01]                          STRUCTURED ERROR
[2026-03-27 22:26:01] ══════════════════════════════════════════════════════════════════════════════
[2026-03-27 22:26:01] ERROR TYPE: IMAGE_VERIFICATION_TIMEOUT
[2026-03-27 22:26:01] DIAGNOSTIC: Image verification failed after 7 attempts with exponential backoff
[2026-03-27 22:26:01] COMMON CAUSES: Registry catalog update delays, registry connectivity issues, or registry service problems
[2026-03-27 22:26:01] RECOVERY: 1. Manual verification: curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list 2. Check registry status: verify_microk8s_registry 3. Proceed with deployment if image exists 4. Or retry verification after waiting
[2026-03-27 22:26:01] ══════════════════════════════════════════════════════════════════════════════
[2026-03-27 22:26:01] ERROR: ❌ STEP 5 FAILED: Failed to push Docker image
[2026-03-27 22:26:01] ERROR: 🔄 INITIATING ROLLBACK PROCEDURE
[2026-03-27 22:26:01] ERROR: Deployment failed - attempting to restore previous state
[2026-03-27 22:26:01] INFO: 🔄 Rolling back using backup deployment manifest...
[2026-03-27 22:26:01] INFO: 🔄 Transferring backup deployment manifest to VM...
Error from server (Conflict): error when applying patch:
{"metadata":{"generation":29,"resourceVersion":"627253"},"status":{"observedGeneration":29}}
to:
Resource: "apps/v1, Resource=deployments", GroupVersionKind: "apps/v1, Kind=Deployment"
Name: "my-ag-ui-app", Namespace: "default"
for: "/home/ubuntu/deployment.yaml.backup": error when patching "/home/ubuntu/deployment.yaml.backup": Operation cannot be fulfilled on deployments.apps "my-ag-ui-app": the object has been modified; please apply your changes to the latest version and try again
[2026-03-27 22:26:06] ERROR: ❌ ROLLBACK FAILED: Could not apply backup deployment manifest
[2026-03-27 22:26:06] ERROR:    Manual intervention required to restore deployment state
