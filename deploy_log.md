[2026-03-23 17:57:00] 🚀 START: Total deployment timing
[2026-03-23 17:57:00] Starting Kubernetes secrets setup...
[2026-03-23 17:57:00] k8s directory found: /home/ncheaz/git/my-ag-ui-app/k8s/
[2026-03-23 17:57:00] setup-secrets.sh script found: /home/ncheaz/git/my-ag-ui-app/k8s/setup-secrets.sh
[2026-03-23 17:57:00] Setting up environment variables for secrets creation...
[2026-03-23 17:57:00] Loading environment variables from .env file...
[2026-03-23 17:57:00] Set environment variable: OPENAI_API_KEY
[2026-03-23 17:57:00] Set environment variable: OPENAI_BASE_URL
[2026-03-23 17:57:00] Set environment variable: OPENAI_MODEL
[2026-03-23 17:57:00] Set environment variable: LLM_MAX_TOKENS
[2026-03-23 17:57:00] Set environment variable: LLM_CONTEXT_WINDOW
[2026-03-23 17:57:00] Set environment variable: EMBEDDING_MODEL
[2026-03-23 17:57:00] All required environment variables are set
[2026-03-23 17:57:00] Running secrets setup script...
[2026-03-23 17:57:00] Setting up Kubernetes secrets...
[2026-03-23 17:57:00] Generating Kubernetes secrets file...
[2026-03-23 17:57:00] Kubernetes secrets file generated: k8s/secrets.yaml
[2026-03-23 17:57:00] Kubernetes secrets setup completed successfully
[2026-03-23 17:57:00] Starting Kubernetes deployment phase...
[2026-03-23 17:57:00] Using VM_NAME: my-ag-ui-app-k8s for Kubernetes deployment
[2026-03-23 17:57:00] 🔶 START: DEPENDENCY_VALIDATION
[2026-03-23 17:57:00] 
[2026-03-23 17:57:00] ==================================================
[2026-03-23 17:57:00]   DEPENDENCY VALIDATION BEFORE DOCKER BUILD
[2026-03-23 17:57:00] ==================================================
[2026-03-23 17:57:00] 
[2026-03-23 17:57:00] Starting lock file validation...
[2026-03-23 17:57:00] Checking if package.json and package-lock.json are in sync...
[2026-03-23 17:57:02] ✅ SUCCESS: package.json and package-lock.json are synchronized
[2026-03-23 17:57:02]    Dependencies are ready for reproducible Docker builds.
[2026-03-23 17:57:02] 
[2026-03-23 17:57:02] ✅ Dependency validation passed - proceeding with Docker build
[2026-03-23 17:57:02] ==================================================
[2026-03-23 17:57:02] 
[2026-03-23 17:57:02] ✅ END: DEPENDENCY_VALIDATION (took 1.188718238s)
[2026-03-23 17:57:02] 🔶 START: DOCKER_IMAGE_BUILD
[2026-03-23 17:57:02] Starting Docker image build process...
[2026-03-23 17:57:02] Building Docker image 'localhost:32000/my-ag-ui-app:latest' using project Dockerfile...
[2026-03-23 17:57:02] Checking Docker daemon socket permissions...
[2026-03-23 17:57:02] Docker daemon socket permissions verified - user has access
[2026-03-23 17:57:02] Dockerfile found: /home/ncheaz/git/my-ag-ui-app/Dockerfile
[2026-03-23 17:57:02] Building Docker image 'localhost:32000/my-ag-ui-app:latest'...
[2026-03-23 17:57:02] Performing pre-flight check: Docker daemon accessibility before build...
[2026-03-23 17:57:02] ✅ Docker daemon is accessible for build operation
[2026-03-23 17:57:02] CHECKING DISK SPACE FOR: Docker image build
[2026-03-23 17:57:02] Minimum required: 5GB
[2026-03-23 17:57:02] Available disk space: 20.0GB at .
[2026-03-23 17:57:02] ✅ SUFFICIENT DISK SPACE FOR: Docker image build (15.0GB available above minimum)
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 4.73kB done
#1 DONE 0.0s

#2 [internal] load metadata for docker.io/library/node:20.12.0-alpine
#2 DONE 0.2s

#3 [internal] load .dockerignore
#3 transferring context: 128B done
#3 DONE 0.1s

#4 [builder 1/6] FROM docker.io/library/node:20.12.0-alpine@sha256:ef3f47741e161900ddd07addcaca7e76534a9205e4cd73b2ed091ba339004a75
#4 DONE 0.0s

#5 [internal] load build context
#5 transferring context: 54.07kB 0.0s done
#5 DONE 0.7s

#6 [builder 2/6] WORKDIR /app
#6 CACHED

#7 [builder 3/6] COPY package.json package-lock.json ./
#7 CACHED

#8 [builder 4/6] RUN echo "=== DEPENDENCY INSTALLATION ===" &&     echo "Starting npm ci (reproducible install)..." &&     if npm ci --ignore-scripts; then         echo "✅ SUCCESS: npm ci completed - using reproducible dependencies from lock file";     else         echo "⚠️  WARNING: npm ci failed - lock files are out of sync";         echo "🔄 FALLING BACK to npm install to continue build...";         echo "ℹ️  NOTE: This allows deployment but reduces build reproducibility";         echo "🔧 FIX: Run 'npm install' locally and commit updated package-lock.json";         npm install --ignore-scripts;         echo "✅ SUCCESS: npm install completed - build continuing with fallback dependencies";     fi &&     echo "=== DEPENDENCY INSTALLATION COMPLETED ===" &&     npm cache clean --force
#8 CACHED

#9 [builder 5/6] COPY . .
#9 DONE 0.4s

#10 [builder 6/6] RUN npm run build
#10 0.359 
#10 0.359 > pydantic-ai-starter@0.1.0 build
#10 0.359 > next build
#10 0.359 
#10 0.970 Attention: Next.js now collects completely anonymous telemetry regarding usage.
#10 0.970 This information is used to shape Next.js' roadmap and prioritize features.
#10 0.970 You can learn more, including how to opt-out if you'd not like to participate in this anonymous program, by visiting the following URL:
#10 0.970 https://nextjs.org/telemetry
#10 0.970 
#10 0.986 ▲ Next.js 16.1.0 (Turbopack)
#10 0.986 
#10 1.041   Creating an optimized production build ...
#10 32.23 ✓ Compiled successfully in 30.9s
#10 32.24   Running TypeScript ...
#10 34.93   Collecting page data using 11 workers ...
#10 35.93   Generating static pages using 11 workers (0/5) ...
#10 36.62   Generating static pages using 11 workers (1/5) 
#10 36.64   Generating static pages using 11 workers (2/5) 
#10 36.64   Generating static pages using 11 workers (3/5) 
#10 37.24 ✓ Generating static pages using 11 workers (5/5) in 1309.8ms
#10 37.25   Finalizing page optimization ...
#10 37.41 
#10 37.41 Route (app)
#10 37.41 ┌ ○ /
#10 37.41 ├ ○ /_not-found
#10 37.41 └ ƒ /api/copilotkit
#10 37.41 
#10 37.41 
#10 37.41 ○  (Static)   prerendered as static content
#10 37.41 ƒ  (Dynamic)  server-rendered on demand
#10 37.41 
#10 DONE 37.8s

#11 [runner 3/6] RUN addgroup --system --gid 1001 nodejs &&     adduser --system --uid 1001 nextjs
#11 CACHED

#12 [runner 4/6] COPY --from=builder /app/public ./public
#12 CACHED

#13 [runner 5/6] COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
#13 DONE 0.6s

#14 [runner 6/6] COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
#14 DONE 0.2s

#15 exporting to image
#15 exporting layers
#15 exporting layers 0.7s done
#15 writing image sha256:8f077d657d7168b342ef3ba4ebfaf68e0affc7322a11d09e5a16febe61dacefa done
#15 naming to localhost:32000/my-ag-ui-app:latest done
#15 DONE 0.7s

View build details: docker-desktop://dashboard/build/default/default/of5hfxvvf5i1ebtth0dcdnj42

 [33m4 warnings found (use docker --debug to expand):
[0m - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "LOGFIRE_TOKEN") (line 93)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "LOGFIRE_TOKEN") (line 94)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "OPENAI_API_KEY") (line 77)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "OPENAI_API_KEY") (line 80)
[2026-03-23 17:57:45] Docker image 'localhost:32000/my-ag-ui-app:latest' built successfully
[2026-03-23 17:57:45] ✅ END: DOCKER_IMAGE_BUILD (took 42.923831048s)
[2026-03-23 17:57:45] Verifying Docker image was built successfully...
[2026-03-23 17:57:45] Docker image 'localhost:32000/my-ag-ui-app:latest' verified successfully
[2026-03-23 17:57:45] 🔶 START: MICROK8S_REGISTRY_SETUP
[2026-03-23 17:57:45] Starting microk8s registry setup...
[2026-03-23 17:57:45] Starting microk8s registry setup...
[2026-03-23 17:57:45] Checking microk8s availability...
[2026-03-23 17:57:45] ✅ microk8s is available in VM
[2026-03-23 17:57:45] Enabling microk8s registry...
[2026-03-23 17:57:45]    Command: microk8s enable registry
[2026-03-23 17:57:45]    Timeout: 30 seconds
[2026-03-23 17:57:45]    This enables the built-in microk8s registry for local image distribution
[2026-03-23 17:57:45]    Executing: timeout 30 multipass exec 'my-ag-ui-app-k8s' -- microk8s enable registry
[2026-03-23 17:57:46] ✅ microk8s registry enable command completed successfully
[2026-03-23 17:57:46]    Registry enablement process: COMPLETED
[2026-03-23 17:57:46]    Execution time: < 30 seconds (within timeout)
[2026-03-23 17:57:46] Registry enablement output:
Infer repository core for addon registry
Addon core/registry is already enabled
[2026-03-23 17:57:46] Waiting 5 seconds for registry to fully start...
[2026-03-23 17:57:51] Verifying registry is running and accessible at localhost:32000...
[2026-03-23 17:57:51]    Registry endpoint: http://localhost:32000
[2026-03-23 17:57:51]    Connection timeout: 5 seconds
[2026-03-23 17:57:51]    Overall timeout: 10 seconds
[2026-03-23 17:57:51]    Executing: timeout 10 multipass exec 'my-ag-ui-app-k8s' -- curl -s --connect-timeout 5 http://localhost:32000/v2/_catalog
[2026-03-23 17:57:51] ✅ Registry is accessible at localhost:32000
[2026-03-23 17:57:51]    Registry connection test: PASSED
[2026-03-23 17:57:51]    Response time: < 5 seconds (within timeout)
[2026-03-23 17:57:51] Registry response:
{"repositories":["my-ag-ui-app"]}
[2026-03-23 17:57:51] Getting detailed registry status...
[2026-03-23 17:57:52] Registry pod status:
NAME                       READY   STATUS    RESTARTS   AGE   IP            NODE               NOMINATED NODE   READINESS GATES
registry-6cf7b9fcc-4kfg7   1/1     Running   1          75m   10.1.217.23   my-ag-ui-app-k8s   <none>           <none>
[2026-03-23 17:57:52] Registry service info:
NAME       TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
registry   NodePort   10.152.183.199   <none>        5000:32000/TCP   75m
[2026-03-23 17:57:52] ✅ Registry verification completed successfully
[2026-03-23 17:57:52]    Registry is accessible at: localhost:32000
[2026-03-23 17:57:52]    Registry can be used for local image distribution
[2026-03-23 17:57:52]    Registry endpoint: http://localhost:32000/v2/_catalog
[2026-03-23 17:57:52]    Status: VERIFIED and READY
[2026-03-23 17:57:52] ✅ microk8s registry setup completed successfully
[2026-03-23 17:57:52]    Registry status: ENABLED and VERIFIED
[2026-03-23 17:57:52]    Registry endpoint: localhost:32000
[2026-03-23 17:57:52]    Ready for: Local image tagging and pushing
[2026-03-23 17:57:52] microk8s registry setup completed successfully
[2026-03-23 17:57:52] ✅ END: MICROK8S_REGISTRY_SETUP (took 6.963488465s)
[2026-03-23 17:57:52] 🔶 START: DOCKER_REGISTRY_PUSH
[2026-03-23 17:57:52] Starting Docker image push to microk8s registry...
[2026-03-23 17:57:52] Using comprehensive push function with validation, error handling, and verification...
[2026-03-23 17:57:52] Starting Docker image push to microk8s registry...
[2026-03-23 17:57:52] ⏱️  Push operation started at: 2026-03-23 17:57:52
[2026-03-23 17:57:52] Target registry image: localhost:32000/my-ag-ui-app:latest
[2026-03-23 17:57:52] Performing pre-flight check: Docker daemon accessibility...
[2026-03-23 17:57:52] ✅ Docker daemon is accessible for image push
[2026-03-23 17:57:52] Performing pre-flight check: Verifying tagged image exists locally...
[2026-03-23 17:57:52] Local image to be pushed:
REPOSITORY                     TAG       SIZE      CREATED AT
localhost:32000/my-ag-ui-app   latest    256MB     2026-03-23 17:57:44 -0400 EDT
[2026-03-23 17:57:52] ✅ Tagged image exists locally and is ready for push
[2026-03-23 17:57:52] Performing pre-flight check: Verifying microk8s registry is accessible...
[2026-03-23 17:57:52] Verifying registry is running and accessible at localhost:32000...
[2026-03-23 17:57:52]    Registry endpoint: http://localhost:32000
[2026-03-23 17:57:52]    Connection timeout: 5 seconds
[2026-03-23 17:57:52]    Overall timeout: 10 seconds
[2026-03-23 17:57:52]    Executing: timeout 10 multipass exec 'my-ag-ui-app-k8s' -- curl -s --connect-timeout 5 http://localhost:32000/v2/_catalog
[2026-03-23 17:57:52] ✅ Registry is accessible at localhost:32000
[2026-03-23 17:57:52]    Registry connection test: PASSED
[2026-03-23 17:57:52]    Response time: < 5 seconds (within timeout)
[2026-03-23 17:57:52] Registry response:
{"repositories":["my-ag-ui-app"]}
[2026-03-23 17:57:52] Getting detailed registry status...
[2026-03-23 17:57:52] Registry pod status:
NAME                       READY   STATUS    RESTARTS   AGE   IP            NODE               NOMINATED NODE   READINESS GATES
registry-6cf7b9fcc-4kfg7   1/1     Running   1          75m   10.1.217.23   my-ag-ui-app-k8s   <none>           <none>
[2026-03-23 17:57:52] Registry service info:
NAME       TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
registry   NodePort   10.152.183.199   <none>        5000:32000/TCP   75m
[2026-03-23 17:57:52] ✅ Registry verification completed successfully
[2026-03-23 17:57:52]    Registry is accessible at: localhost:32000
[2026-03-23 17:57:52]    Registry can be used for local image distribution
[2026-03-23 17:57:52]    Registry endpoint: http://localhost:32000/v2/_catalog
[2026-03-23 17:57:52]    Status: VERIFIED and READY
[2026-03-23 17:57:52] ✅ microk8s registry is accessible and ready for push
[2026-03-23 17:57:52] Performing pre-flight check: Verifying disk space for push operation...
[2026-03-23 17:57:52] CHECKING DISK SPACE FOR: Docker image push
[2026-03-23 17:57:52] Minimum required: 2GB
[2026-03-23 17:57:52] Available disk space: 20.0GB at .
[2026-03-23 17:57:52] ✅ SUFFICIENT DISK SPACE FOR: Docker image push (18.0GB available above minimum)
[2026-03-23 17:57:52] ✅ Sufficient disk space available for push operation
[2026-03-23 17:57:52] Pushing image to microk8s registry with enhanced retry logic...
[2026-03-23 17:57:52]    Command: docker push localhost:32000/my-ag-ui-app:latest
[2026-03-23 17:57:52]    This distributes the image to the local microk8s registry for Kubernetes deployment
[2026-03-23 17:57:52]    Using exponential backoff with jitter for transient network issues
[2026-03-23 17:57:52] Push attempt 1/3 (initial attempt)...
[2026-03-23 17:57:52]    Executing: timeout 60 docker push localhost:32000/my-ag-ui-app:latest
[2026-03-23 17:57:52] ❌ Docker push command failed (exit code: 1, attempt 1)
[2026-03-23 17:57:52] Push error output (attempt 1):
The push refers to repository [localhost:32000/my-ag-ui-app]
Get "http://localhost:32000/v2/": dial tcp 127.0.0.1:32000: connect: connection refused
[2026-03-23 17:57:52] ANALYZING PUSH FAILURE (attempt 1)...
[2026-03-23 17:57:52] ERROR TYPE: TRANSIENT NETWORK CONNECTIVITY FAILURE
[2026-03-23 17:57:53] DIAGNOSTIC: Transient network connectivity issues preventing registry communication
[2026-03-23 17:57:53] RECOVERY: Will retry with exponential backoff (transient network issue - attempt 1/3)
[2026-03-23 17:57:53] Waiting 0s before retry attempt 2 (exponential backoff with jitter)...
[2026-03-23 17:57:53] Push attempt 2/3 (retry delay: 4s - exponential backoff with jitter)...
[2026-03-23 17:57:53]    Executing: timeout 60 docker push localhost:32000/my-ag-ui-app:latest
[2026-03-23 17:57:53] ❌ Docker push command failed (exit code: 1, attempt 2)
[2026-03-23 17:57:53] Push error output (attempt 2):
The push refers to repository [localhost:32000/my-ag-ui-app]
Get "http://localhost:32000/v2/": dial tcp 127.0.0.1:32000: connect: connection refused
[2026-03-23 17:57:53] ANALYZING PUSH FAILURE (attempt 2)...
[2026-03-23 17:57:53] ERROR TYPE: TRANSIENT NETWORK CONNECTIVITY FAILURE
[2026-03-23 17:57:53] DIAGNOSTIC: Transient network connectivity issues preventing registry communication
[2026-03-23 17:57:53] RECOVERY: Will retry with exponential backoff (transient network issue - attempt 2/3)
[2026-03-23 17:57:53] Waiting 4s before retry attempt 3 (exponential backoff with jitter)...
[2026-03-23 17:57:57] Push attempt 3/3 (retry delay: 9s - exponential backoff with jitter)...
[2026-03-23 17:57:57]    Executing: timeout 60 docker push localhost:32000/my-ag-ui-app:latest
[2026-03-23 17:57:57] ❌ Docker push command failed (exit code: 1, attempt 3)
[2026-03-23 17:57:57] Push error output (attempt 3):
The push refers to repository [localhost:32000/my-ag-ui-app]
Get "http://localhost:32000/v2/": dial tcp 127.0.0.1:32000: connect: connection refused
[2026-03-23 17:57:57] ERROR: Final push attempt failed - no more retries available
[2026-03-23 17:57:57] NOTE: All 3 attempts used exponential backoff with jitter for transient issues
[2026-03-23 17:57:57] ❌ ERROR: All push attempts failed (3 attempts)
[2026-03-23 17:57:57]    Image could not be pushed to microk8s registry
[2026-03-23 17:57:57] 
[2026-03-23 17:57:57] COMPREHENSIVE RECOVERY STEPS:
[2026-03-23 17:57:57] 1. Verify Docker daemon is running: docker info
[2026-03-23 17:57:57] 2. Check image exists locally: docker images localhost:32000/my-ag-ui-app:latest
[2026-03-23 17:57:57] 3. Verify registry is accessible: curl -s http://localhost:32000/v2/_catalog
[2026-03-23 17:57:57] 4. Enable registry if needed: microk8s enable registry
[2026-03-23 17:57:57] 5. Check network connectivity: ping -c 2 localhost
[2026-03-23 17:57:57] 6. Check disk space: df -h
[2026-03-23 17:57:57] 7. Manual push attempt: docker push localhost:32000/my-ag-ui-app:latest
[2026-03-23 17:57:57] 8. Check registry logs: microk8s kubectl logs -n container-registry -l app=registry
[2026-03-23 17:57:57] DEPLOYMENT ERROR [Code: 131]: Failed to push Docker image to microk8s registry
[2026-03-23 17:57:57] RECOVERY SUGGESTION: Comprehensive image push failed. Check logs above for detailed error analysis and recovery steps.
[2026-03-23 17:57:57] ENHANCED RECOVERY SUGGESTIONS FOR REGISTRY PUSH FAILURES:
[2026-03-23 17:57:57] 1. Verify Docker daemon is running: docker info
[2026-03-23 17:57:57] 2. Start Docker daemon if needed: sudo systemctl start docker
[2026-03-23 17:57:57] 3. Verify tagged image exists: docker images localhost:32000/my-ag-ui-app:latest
[2026-03-23 17:57:57] 4. Verify microk8s registry is accessible: curl -s http://localhost:32000/v2/_catalog
[2026-03-23 17:57:57] 5. Enable microk8s registry if needed: microk8s enable registry
[2026-03-23 17:57:57] 6. Check registry pod status: microk8s kubectl get pods -n container-registry
[2026-03-23 17:57:57] 7. Check registry logs: microk8s kubectl logs -n container-registry -l app=registry
[2026-03-23 17:57:57] 8. Check network connectivity: ping -c 2 localhost
[2026-03-23 17:57:57] 9. Check disk space: df -h
[2026-03-23 17:57:57] 10. Manual push attempt: docker push localhost:32000/my-ag-ui-app:latest
[2026-03-23 17:57:57] 11. If all else fails, restart registry: microk8s stop && microk8s start
[2026-03-23 17:57:57] ESSENTIAL DIAGNOSTIC INFO:
[2026-03-23 17:57:57] Current directory: /home/ncheaz/git/my-ag-ui-app
[2026-03-23 17:57:57] k8s directory exists: yes
