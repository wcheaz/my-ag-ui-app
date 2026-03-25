[2026-03-25 17:36:42] 🚀 START: Total deployment timing
[2026-03-25 17:36:42] Starting Kubernetes secrets setup...
[2026-03-25 17:36:42] k8s directory found: /home/ncheaz/git/my-ag-ui-app/k8s/
[2026-03-25 17:36:42] setup-secrets.sh script found: /home/ncheaz/git/my-ag-ui-app/k8s/setup-secrets.sh
[2026-03-25 17:36:42] Setting up environment variables for secrets creation...
[2026-03-25 17:36:42] Loading environment variables from .env file...
[2026-03-25 17:36:42] Set environment variable: OPENAI_API_KEY
[2026-03-25 17:36:42] Set environment variable: OPENAI_BASE_URL
[2026-03-25 17:36:42] Set environment variable: OPENAI_MODEL
[2026-03-25 17:36:42] Set environment variable: LLM_MAX_TOKENS
[2026-03-25 17:36:42] Set environment variable: LLM_CONTEXT_WINDOW
[2026-03-25 17:36:42] Set environment variable: EMBEDDING_MODEL
[2026-03-25 17:36:42] All required environment variables are set
[2026-03-25 17:36:42] Running secrets setup script...
[2026-03-25 17:36:42] Setting up Kubernetes secrets...
[2026-03-25 17:36:42] Reading environment variables...
[2026-03-25 17:36:42] Encoding values to base64...
[2026-03-25 17:36:42] Generating Kubernetes secrets file...
[2026-03-25 17:36:42] Validating generated YAML file...
==================================================================
❌ ERROR: Generated YAML file is invalid
==================================================================
ERROR TYPE: KUBERNETES SECRETS SETUP FAILURE
DIAGNOSTIC: Generated YAML file is invalid
COMMON CAUSES:
  - Missing required environment variables
  - File permission issues
  - Kubernetes cluster not accessible
RECOVERY:
  1. Check the generated file for syntax errors: cat k8s/secrets.yaml\n
==================================================================
[2026-03-25 17:36:42] Kubernetes secrets setup completed successfully
[2026-03-25 17:36:42] Starting Kubernetes deployment phase...
[2026-03-25 17:36:42] Using VM_NAME: my-ag-ui-app-k8s for Kubernetes deployment
[2026-03-25 17:36:42] 🔶 START: DEPENDENCY_VALIDATION
[2026-03-25 17:36:42] 
[2026-03-25 17:36:42] ==================================================
[2026-03-25 17:36:42]   DEPENDENCY VALIDATION BEFORE DOCKER BUILD
[2026-03-25 17:36:42] ==================================================
[2026-03-25 17:36:42] 
[2026-03-25 17:36:42] Starting lock file validation...
[2026-03-25 17:36:42] Checking if package.json and package-lock.json are in sync...
[2026-03-25 17:36:44] ✅ SUCCESS: package.json and package-lock.json are synchronized
[2026-03-25 17:36:44]    Dependencies are ready for reproducible Docker builds.
[2026-03-25 17:36:44] 
[2026-03-25 17:36:44] ✅ Dependency validation passed - proceeding with Docker build
[2026-03-25 17:36:44] ==================================================
[2026-03-25 17:36:44] 
[2026-03-25 17:36:44] ✅ END: DEPENDENCY_VALIDATION (took 1.382389820s)
[2026-03-25 17:36:44] 🔶 START: DOCKER_IMAGE_BUILD
[2026-03-25 17:36:44] Starting Docker image build process...
[2026-03-25 17:36:44] Building Docker image 'localhost:32000/my-ag-ui-app:latest' using project Dockerfile...
[2026-03-25 17:36:44] Checking Docker daemon socket permissions...
[2026-03-25 17:36:44] Docker daemon socket permissions verified - user has access
[2026-03-25 17:36:44] Dockerfile found: /home/ncheaz/git/my-ag-ui-app/Dockerfile
[2026-03-25 17:36:44] Building Docker image 'localhost:32000/my-ag-ui-app:latest'...
[2026-03-25 17:36:44] Performing pre-flight check: Docker daemon accessibility before build...
[2026-03-25 17:36:44] ✅ Docker daemon is accessible for build operation
[2026-03-25 17:36:44] CHECKING DISK SPACE FOR: Docker image build
[2026-03-25 17:36:44] Minimum required: 5GB
[2026-03-25 17:36:44] Available disk space: 341.0GB at .
[2026-03-25 17:36:44] ✅ SUFFICIENT DISK SPACE FOR: Docker image build (336.0GB available above minimum)
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 4.79kB done
#1 DONE 0.0s

#2 [internal] load metadata for docker.io/library/node:20.12.0-alpine
#2 DONE 0.3s

#3 [internal] load .dockerignore
#3 transferring context: 128B done
#3 DONE 0.1s

#4 [builder 1/6] FROM docker.io/library/node:20.12.0-alpine@sha256:ef3f47741e161900ddd07addcaca7e76534a9205e4cd73b2ed091ba339004a75
#4 DONE 0.0s

#5 [internal] load build context
#5 transferring context: 399.96kB 0.0s done
#5 DONE 0.1s

#6 [builder 2/6] WORKDIR /app
#6 CACHED

#7 [builder 3/6] COPY package.json package-lock.json ./
#7 CACHED

#8 [builder 4/6] RUN echo "=== DEPENDENCY INSTALLATION ===" &&     echo "Starting npm ci (reproducible install)..." &&     if npm ci --ignore-scripts; then         echo "✅ SUCCESS: npm ci completed - using reproducible dependencies from lock file";     else         echo "⚠️  WARNING: npm ci failed - lock files are out of sync";         echo "🔄 FALLING BACK to npm install to continue build...";         echo "ℹ️  NOTE: This allows deployment but reduces build reproducibility";         echo "🔧 FIX: Run 'npm install' locally and commit updated package-lock.json";         npm install --ignore-scripts;         echo "✅ SUCCESS: npm install completed - build continuing with fallback dependencies";     fi &&     echo "=== DEPENDENCY INSTALLATION COMPLETED ===" &&     npm cache clean --force
#8 CACHED

#9 [builder 5/6] COPY . .
#9 DONE 0.4s

#10 [builder 6/6] RUN npm run build
#10 0.370 
#10 0.370 > pydantic-ai-starter@0.1.0 build
#10 0.370 > next build
#10 0.370 
#10 0.941 Attention: Next.js now collects completely anonymous telemetry regarding usage.
#10 0.942 This information is used to shape Next.js' roadmap and prioritize features.
#10 0.942 You can learn more, including how to opt-out if you'd not like to participate in this anonymous program, by visiting the following URL:
#10 0.942 https://nextjs.org/telemetry
#10 0.942 
#10 0.959 ▲ Next.js 16.1.0 (Turbopack)
#10 0.959 
#10 1.018   Creating an optimized production build ...
#10 31.01 ✓ Compiled successfully in 29.7s
#10 31.02   Running TypeScript ...
#10 33.70   Collecting page data using 11 workers ...
#10 34.66   Generating static pages using 11 workers (0/6) ...
#10 34.87   Generating static pages using 11 workers (1/6) 
#10 35.30   Generating static pages using 11 workers (2/6) 
#10 35.32   Generating static pages using 11 workers (4/6) 
#10 35.89 ✓ Generating static pages using 11 workers (6/6) in 1234.7ms
#10 35.89   Finalizing page optimization ...
#10 36.06 
#10 36.06 Route (app)
#10 36.06 ┌ ○ /
#10 36.06 ├ ○ /_not-found
#10 36.06 ├ ƒ /api/copilotkit
#10 36.06 └ ƒ /api/health
#10 36.06 
#10 36.06 
#10 36.06 ○  (Static)   prerendered as static content
#10 36.06 ƒ  (Dynamic)  server-rendered on demand
#10 36.06 
#10 DONE 36.3s

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
#15 writing image sha256:d2cd35318606459c55cc1475d68df54fd64ac1fdedb5e106f12c799ac1212bb0 done
#15 naming to docker.io/library/my-ag-ui-app:latest done
#15 DONE 0.8s

View build details: docker-desktop://dashboard/build/default/default/2jx35rch4zdrzpkx2dum0p7iv
[2026-03-25 17:37:24] Docker image 'my-ag-ui-app:latest' built successfully
[2026-03-25 17:37:24] ✅ END: DOCKER_IMAGE_BUILD (took 40.928488929s)
[2026-03-25 17:37:24] Verifying Docker image was built successfully...
[2026-03-25 17:37:25] Docker image 'my-ag-ui-app:latest' verified successfully
[2026-03-25 17:37:25] 🔶 START: DOCKER_IMAGE_TAGGING
[2026-03-25 17:37:25] Starting Docker image tagging for local registry...
[2026-03-25 17:37:25] Using comprehensive tagging function with validation and error handling...
[2026-03-25 17:37:25] Starting Docker image tagging for local registry (executing within VM)...
[2026-03-25 17:37:25] ⏱️  Tagging operation started at: 2026-03-25 17:37:25
[2026-03-25 17:37:25] Validating VM accessibility before Docker operations...
[2026-03-25 17:37:25] ✅ VM is accessible for Docker operations
[2026-03-25 17:37:25] Validating Docker daemon availability within VM before image existence check...
[2026-03-25 17:37:25] ✅ Docker daemon is accessible for image validation within VM
[2026-03-25 17:37:25] Performing comprehensive validation of source image my-ag-ui-app:latest within VM...
[2026-03-25 17:37:25] Method 1: Checking exact tag match for my-ag-ui-app:latest within VM...
[2026-03-25 17:37:25] ✅ Source image found with exact tag match within VM: my-ag-ui-app:latest
[2026-03-25 17:37:25] ✅ Comprehensive validation passed: Source image my-ag-ui-app:latest exists within VM
[2026-03-25 17:37:25] Source image details within VM:
REPOSITORY     TAG       SIZE      CREATED AT
my-ag-ui-app   latest    546MB     2026-03-23 11:05:10 -0400 EDT
[2026-03-25 17:37:25] Target registry image tag: localhost:32000/my-ag-ui-app:latest
[2026-03-25 17:37:25]    This tag will be created within VM where localhost:32000 resolves to microk8s registry
[2026-03-25 17:37:25] Checking if target tag already exists within VM...
[2026-03-25 17:37:26] ⚠️  WARNING: Target tag localhost:32000/my-ag-ui-app:latest already exists within VM
[2026-03-25 17:37:26]    Removing existing tag to avoid conflicts...
Untagged: localhost:32000/my-ag-ui-app:latest
[2026-03-25 17:37:26] ✅ Existing tag localhost:32000/my-ag-ui-app:latest removed successfully within VM
[2026-03-25 17:37:26] Tagging image with local registry endpoint within VM...
[2026-03-25 17:37:26]    Command: multipass exec my-ag-ui-app-k8s -- docker tag my-ag-ui-app:latest localhost:32000/my-ag-ui-app:latest
[2026-03-25 17:37:26]    This makes the image addressable by the microk8s local registry within VM
[2026-03-25 17:37:26]    Note: localhost:32000 will resolve to VM's microk8s registry (not host's)
[2026-03-25 17:37:26] Performing pre-flight check: Docker daemon accessibility within VM before tagging...
[2026-03-25 17:37:26] ✅ Docker daemon is accessible for tagging operation within VM
[2026-03-25 17:37:26] ✅ Docker image tagging command completed successfully within VM
[2026-03-25 17:37:26]    Tagging operation: COMPLETED (within VM)
[2026-03-25 17:37:26] Verifying image tagging was successful within VM...
[2026-03-25 17:37:27] ✅ Image tagging verification successful within VM
[2026-03-25 17:37:27]    Target tag localhost:32000/my-ag-ui-app:latest exists and is accessible within VM
[2026-03-25 17:37:27] Tagged image details within VM:
REPOSITORY                     TAG       SIZE      CREATED AT
localhost:32000/my-ag-ui-app   latest    546MB     2026-03-23 11:05:10 -0400 EDT
[2026-03-25 17:37:27] ✅ Image ID verification successful - both images reference the same underlying image within VM
[2026-03-25 17:37:27]    Source image ID: 9bb7f1915756
[2026-03-25 17:37:27]    Tagged image ID: 9bb7f1915756
[2026-03-25 17:37:27] ✅ Docker image tagging for local registry completed successfully within VM
[2026-03-25 17:37:27]    Image tagged as: localhost:32000/my-ag-ui-app:latest
[2026-03-25 17:37:27]    Ready for: Push to microk8s local registry at localhost:32000 (within VM)
[2026-03-25 17:37:27]    Next step: Use the registry push function to push this tagged image from within VM
[2026-03-25 17:37:27] ⏱️  Tagging operation completed at: 2026-03-25 17:37:27
[2026-03-25 17:37:27] ⏱️  Total tagging operation duration: 2 seconds
[2026-03-25 17:37:27] Docker image tagging for registry completed with comprehensive validation
[2026-03-25 17:37:27] ✅ END: DOCKER_IMAGE_TAGGING (took 2.739025351s)
[2026-03-25 17:37:27] 🔶 START: MICROK8S_REGISTRY_SETUP
[2026-03-25 17:37:27] Starting microk8s registry setup...
[2026-03-25 17:37:27] Starting microk8s registry setup...
[2026-03-25 17:37:27] Checking microk8s availability...
[2026-03-25 17:37:27] ✅ microk8s is available in VM
[2026-03-25 17:37:27] Enabling microk8s registry...
[2026-03-25 17:37:27]    Command: microk8s enable registry
[2026-03-25 17:37:27]    Timeout: 30 seconds
[2026-03-25 17:37:27]    This enables the built-in microk8s registry for local image distribution
[2026-03-25 17:37:27]    Executing: timeout 30 multipass exec 'my-ag-ui-app-k8s' -- microk8s enable registry
[2026-03-25 17:37:28] ✅ microk8s registry enable command completed successfully
[2026-03-25 17:37:28]    Registry enablement process: COMPLETED
[2026-03-25 17:37:28]    Execution time: < 30 seconds (within timeout)
[2026-03-25 17:37:28] Registry enablement output:
Infer repository core for addon registry
Addon core/registry is already enabled
[2026-03-25 17:37:28] Waiting 5 seconds for registry to fully start...
[2026-03-25 17:37:33] === REGISTRY ACCESSIBILITY VERIFICATION STARTED ===
[2026-03-25 17:37:33] Verifying registry is running and accessible at localhost:32000...
[2026-03-25 17:37:33]    Registry purpose: Local image distribution for Kubernetes deployment
[2026-03-25 17:37:33]    Registry endpoint: http://localhost:32000
[2026-03-25 17:37:33]    Connection timeout: 5 seconds
[2026-03-25 17:37:33]    Overall timeout: 10 seconds
[2026-03-25 17:37:33]    Verification includes: Connectivity, service status, and API response validation
[2026-03-25 17:37:33] === NETWORK CONNECTIVITY ASSESSMENT ===
[2026-03-25 17:37:33] Assessing network connectivity to registry endpoint...
[2026-03-25 17:37:33]    Target: localhost:32000 (within VM)
[2026-03-25 17:37:33]    Protocol: HTTP
[2026-03-25 17:37:33]    Method: GET
[2026-03-25 17:37:33]    Expected: 200 OK with JSON catalog response
[2026-03-25 17:37:33] === REGISTRY API CONNECTIVITY TEST ===
[2026-03-25 17:37:33]    Executing: timeout 10 multipass exec 'my-ag-ui-app-k8s' -- curl -s --connect-timeout 5 http://localhost:32000/v2/_catalog
[2026-03-25 17:37:33] ✅ REGISTRY CONNECTIVITY: SUCCESS
[2026-03-25 17:37:33]    Registry connection test: PASSED
[2026-03-25 17:37:33]    Response time: .203181232 seconds
[2026-03-25 17:37:33]    Network path: Host → VM → Registry service
[2026-03-25 17:37:33]    Authentication: None required (local registry)
[2026-03-25 17:37:33] === REGISTRY RESPONSE ANALYSIS ===
[2026-03-25 17:37:33] Registry response received:
{"repositories":["my-ag-ui-app"]}
[2026-03-25 17:37:33] ✅ REGISTRY RESPONSE FORMAT: VALID JSON
[2026-03-25 17:37:33]    Response type: Docker Registry v2 API catalog
[2026-03-25 17:37:33]    Content structure: Contains repositories array
[2026-03-25 17:37:33]    Repository count: 0
[2026-03-25 17:37:33] ✅ APPLICATION REPOSITORY: EXISTS in registry
[2026-03-25 17:37:33]    Repository name: my-ag-ui-app
[2026-03-25 17:37:33]    Status: Ready for image operations
[2026-03-25 17:37:33] === COMPREHENSIVE REGISTRY STATUS ===
[2026-03-25 17:37:33] Getting detailed registry status information...
[2026-03-25 17:37:34] Registry pod status:
NAME                       READY   STATUS    RESTARTS   AGE   IP            NODE               NOMINATED NODE   READINESS GATES
registry-6cf7b9fcc-4kfg7   1/1     Running   1          2d    10.1.217.23   my-ag-ui-app-k8s   <none>           <none>
[2026-03-25 17:37:34] Registry service info:
NAME       TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
registry   NodePort   10.152.183.199   <none>        5000:32000/TCP   2d
[2026-03-25 17:37:34] Registry namespace info:
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"Namespace","metadata":{"annotations":{},"name":"container-registry"}}
  creationTimestamp: "2026-03-23T20:42:49Z"
  labels:
    kubernetes.io/metadata.name: container-registry
  name: container-registry
  resourceVersion: "256632"
  uid: 9150fa6c-e656-483b-a5dd-11628c92c5cf
spec:
  finalizers:
  - kubernetes
status:
  phase: Active
[2026-03-25 17:37:34] === ADDITIONAL REGISTRY ENDPOINT TESTS ===
[2026-03-25 17:37:34] Testing registry v2 API endpoint...
[2026-03-25 17:37:34] ✅ REGISTRY v2 API: ACCESSIBLE
[2026-03-25 17:37:34]    Endpoint: /v2/
[2026-03-25 17:37:34]    Status: 200 OK
[2026-03-25 17:37:34]    API version: Docker Registry v2
[2026-03-25 17:37:34] === REGISTRY VERIFICATION SUMMARY ===
[2026-03-25 17:37:34] ✅ Registry verification completed successfully
[2026-03-25 17:37:34]    Registry is accessible at: localhost:32000
[2026-03-25 17:37:34]    Registry can be used for local image distribution
[2026-03-25 17:37:34]    Registry endpoint: http://localhost:32000/v2/_catalog
[2026-03-25 17:37:34]    API version: Docker Registry v2
[2026-03-25 17:37:34]    Authentication: None required (local registry)
[2026-03-25 17:37:34]    Status: VERIFIED and READY
[2026-03-25 17:37:34]    Network path: Host → VM → Registry service
[2026-03-25 17:37:34]    Total verification time: .203181232 seconds
[2026-03-25 17:37:34] === REGISTRY ACCESSIBILITY VERIFICATION COMPLETED ===
[2026-03-25 17:37:34] ✅ microk8s registry setup completed successfully
[2026-03-25 17:37:34]    Registry status: ENABLED and VERIFIED
[2026-03-25 17:37:34]    Registry endpoint: localhost:32000
[2026-03-25 17:37:34]    Ready for: Local image tagging and pushing
[2026-03-25 17:37:34] microk8s registry setup completed successfully
[2026-03-25 17:37:34] ✅ END: MICROK8S_REGISTRY_SETUP (took 7.107580020s)
[2026-03-25 17:37:34] 🔶 START: DOCKER_REGISTRY_PUSH
[2026-03-25 17:37:34] Starting Docker image push to microk8s registry...
[2026-03-25 17:37:34] Using comprehensive push function with validation, error handling, and verification...
[2026-03-25 17:37:34] Starting Docker image push to microk8s registry (executing within VM)...
[2026-03-25 17:37:34] ⏱️  Push operation started at: 2026-03-25 17:37:34
[2026-03-25 17:37:34] Target registry image: localhost:32000/my-ag-ui-app:latest
[2026-03-25 17:37:34]    Note: This references the VM's microk8s registry at localhost:32000
[2026-03-25 17:37:34] Performing pre-flight check: VM accessibility...
[2026-03-25 17:37:34] ✅ VM is accessible for image push
[2026-03-25 17:37:34] Performing pre-flight check: Docker daemon accessibility within VM...
[2026-03-25 17:37:35] ✅ Docker daemon is accessible for image push within VM
[2026-03-25 17:37:35] Performing pre-flight check: Verifying tagged image exists within VM...
[2026-03-25 17:37:35] Local image to be pushed (from within VM):
REPOSITORY                     TAG       SIZE      CREATED AT
localhost:32000/my-ag-ui-app   latest    546MB     2026-03-23 11:05:10 -0400 EDT
[2026-03-25 17:37:35] ✅ Tagged image exists within VM and is ready for push
[2026-03-25 17:37:35] Performing pre-flight check: Verifying microk8s registry is accessible...
[2026-03-25 17:37:35] === REGISTRY ACCESSIBILITY VERIFICATION STARTED ===
[2026-03-25 17:37:35] Verifying registry is running and accessible at localhost:32000...
[2026-03-25 17:37:35]    Registry purpose: Local image distribution for Kubernetes deployment
[2026-03-25 17:37:35]    Registry endpoint: http://localhost:32000
[2026-03-25 17:37:35]    Connection timeout: 5 seconds
[2026-03-25 17:37:35]    Overall timeout: 10 seconds
[2026-03-25 17:37:35]    Verification includes: Connectivity, service status, and API response validation
[2026-03-25 17:37:35] === NETWORK CONNECTIVITY ASSESSMENT ===
[2026-03-25 17:37:35] Assessing network connectivity to registry endpoint...
[2026-03-25 17:37:35]    Target: localhost:32000 (within VM)
[2026-03-25 17:37:35]    Protocol: HTTP
[2026-03-25 17:37:35]    Method: GET
[2026-03-25 17:37:35]    Expected: 200 OK with JSON catalog response
[2026-03-25 17:37:35] === REGISTRY API CONNECTIVITY TEST ===
[2026-03-25 17:37:35]    Executing: timeout 10 multipass exec 'my-ag-ui-app-k8s' -- curl -s --connect-timeout 5 http://localhost:32000/v2/_catalog
[2026-03-25 17:37:35] ✅ REGISTRY CONNECTIVITY: SUCCESS
[2026-03-25 17:37:35]    Registry connection test: PASSED
[2026-03-25 17:37:35]    Response time: .208597037 seconds
[2026-03-25 17:37:35]    Network path: Host → VM → Registry service
[2026-03-25 17:37:35]    Authentication: None required (local registry)
[2026-03-25 17:37:35] === REGISTRY RESPONSE ANALYSIS ===
[2026-03-25 17:37:35] Registry response received:
{"repositories":["my-ag-ui-app"]}
[2026-03-25 17:37:35] ✅ REGISTRY RESPONSE FORMAT: VALID JSON
[2026-03-25 17:37:35]    Response type: Docker Registry v2 API catalog
[2026-03-25 17:37:35]    Content structure: Contains repositories array
[2026-03-25 17:37:35]    Repository count: 0
[2026-03-25 17:37:35] ✅ APPLICATION REPOSITORY: EXISTS in registry
[2026-03-25 17:37:35]    Repository name: my-ag-ui-app
[2026-03-25 17:37:35]    Status: Ready for image operations
[2026-03-25 17:37:35] === COMPREHENSIVE REGISTRY STATUS ===
[2026-03-25 17:37:35] Getting detailed registry status information...
[2026-03-25 17:37:36] Registry pod status:
NAME                       READY   STATUS    RESTARTS   AGE   IP            NODE               NOMINATED NODE   READINESS GATES
registry-6cf7b9fcc-4kfg7   1/1     Running   1          2d    10.1.217.23   my-ag-ui-app-k8s   <none>           <none>
[2026-03-25 17:37:36] Registry service info:
NAME       TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
registry   NodePort   10.152.183.199   <none>        5000:32000/TCP   2d
[2026-03-25 17:37:36] Registry namespace info:
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"Namespace","metadata":{"annotations":{},"name":"container-registry"}}
  creationTimestamp: "2026-03-23T20:42:49Z"
  labels:
    kubernetes.io/metadata.name: container-registry
  name: container-registry
  resourceVersion: "256632"
  uid: 9150fa6c-e656-483b-a5dd-11628c92c5cf
spec:
  finalizers:
  - kubernetes
status:
  phase: Active
[2026-03-25 17:37:36] === ADDITIONAL REGISTRY ENDPOINT TESTS ===
[2026-03-25 17:37:36] Testing registry v2 API endpoint...
[2026-03-25 17:37:37] ✅ REGISTRY v2 API: ACCESSIBLE
[2026-03-25 17:37:37]    Endpoint: /v2/
[2026-03-25 17:37:37]    Status: 200 OK
[2026-03-25 17:37:37]    API version: Docker Registry v2
[2026-03-25 17:37:37] === REGISTRY VERIFICATION SUMMARY ===
[2026-03-25 17:37:37] ✅ Registry verification completed successfully
[2026-03-25 17:37:37]    Registry is accessible at: localhost:32000
[2026-03-25 17:37:37]    Registry can be used for local image distribution
[2026-03-25 17:37:37]    Registry endpoint: http://localhost:32000/v2/_catalog
[2026-03-25 17:37:37]    API version: Docker Registry v2
[2026-03-25 17:37:37]    Authentication: None required (local registry)
[2026-03-25 17:37:37]    Status: VERIFIED and READY
[2026-03-25 17:37:37]    Network path: Host → VM → Registry service
[2026-03-25 17:37:37]    Total verification time: .208597037 seconds
[2026-03-25 17:37:37] === REGISTRY ACCESSIBILITY VERIFICATION COMPLETED ===
[2026-03-25 17:37:37] ✅ microk8s registry is accessible and ready for push
[2026-03-25 17:37:37] Performing pre-flight check: Verifying disk space for push operation...
[2026-03-25 17:37:37] CHECKING DISK SPACE FOR: Docker image push
[2026-03-25 17:37:37] Minimum required: 2GB
[2026-03-25 17:37:37] Available disk space: 341.0GB at .
[2026-03-25 17:37:37] ✅ SUFFICIENT DISK SPACE FOR: Docker image push (339.0GB available above minimum)
[2026-03-25 17:37:37] ✅ Sufficient disk space available for push operation
[2026-03-25 17:37:37] Pushing image to microk8s registry with enhanced retry logic (within VM)...
[2026-03-25 17:37:37]    Command: multipass exec my-ag-ui-app-k8s -- timeout 60 docker push localhost:32000/my-ag-ui-app:latest
[2026-03-25 17:37:37]    This distributes the image to the local microk8s registry for Kubernetes deployment
[2026-03-25 17:37:37]    Using exponential backoff with jitter for transient network issues
[2026-03-25 17:37:37]    Note: localhost:32000 resolves to VM's microk8s registry (not host's)
[2026-03-25 17:37:37] Push attempt 1/3 (initial attempt)...
[2026-03-25 17:37:37]    Executing: multipass exec my-ag-ui-app-k8s -- timeout 60 docker push localhost:32000/my-ag-ui-app:latest
[2026-03-25 17:37:37] ✅ Docker push command completed successfully within VM (attempt 1)
[2026-03-25 17:37:37] ✅ Image push completed successfully within VM
[2026-03-25 17:37:37]    Push command output summary:
The push refers to repository [localhost:32000/my-ag-ui-app]
52a51099bdef: Layer already exists
f82bfb71098a: Layer already exists
abc5b1d00820: Layer already exists
413c136dedcf: Layer already exists
82fb5a2278a7: Layer already exists
a2cffe5fe30b: Layer already exists
d4fc045c9e3a: Layer already exists
75136c45e7ab: Layer already exists
8e1fab8d9171: Layer already exists
latest: digest: sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f size: 1620
[2026-03-25 17:37:37] Verifying image was successfully pushed to registry...
[2026-03-25 17:37:37] Registry verification attempt 1/5...
[2026-03-25 17:37:37] ⚠️  Image not immediately found in registry catalog (attempt 1)
[2026-03-25 17:37:37] Waiting 2s for registry to update...
[2026-03-25 17:37:39] Registry verification attempt 2/5...
[2026-03-25 17:37:39] ⚠️  Image not immediately found in registry catalog (attempt 2)
[2026-03-25 17:37:39] Waiting 2s for registry to update...
[2026-03-25 17:37:41] Registry verification attempt 3/5...
[2026-03-25 17:37:41] ⚠️  Image not immediately found in registry catalog (attempt 3)
[2026-03-25 17:37:41] Waiting 2s for registry to update...
[2026-03-25 17:37:43] Registry verification attempt 4/5...
[2026-03-25 17:37:43] ⚠️  Image not immediately found in registry catalog (attempt 4)
[2026-03-25 17:37:43] Waiting 2s for registry to update...
[2026-03-25 17:37:45] Registry verification attempt 5/5...
[2026-03-25 17:37:45] ⚠️  Image not immediately found in registry catalog (attempt 5)
[2026-03-25 17:37:45] ⚠️  WARNING: Image verification failed - image not found in registry catalog
[2026-03-25 17:37:45]    This may be a temporary issue - the registry may need additional time to update
[2026-03-25 17:37:45]    The push operation completed successfully, but verification could not confirm registry availability
[2026-03-25 17:37:45] 
[2026-03-25 17:37:45] MANUAL VERIFICATION STEPS:
[2026-03-25 17:37:45] 1. Check registry catalog: curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list
[2026-03-25 17:37:45] 2. Check registry status: verify_microk8s_registry
[2026-03-25 17:37:45] 3. List images in registry: curl -s http://localhost:32000/v2/_catalog
[2026-03-25 17:37:45] 4. The image should be available despite verification failure
[2026-03-25 17:37:45] ⏱️  Push operation completed at: 2026-03-25 17:37:45
[2026-03-25 17:37:45] ⏱️  Total push operation duration: 11 seconds
[2026-03-25 17:37:45] ✅ Docker image push to microk8s registry completed successfully within VM
[2026-03-25 17:37:45]    Image: localhost:32000/my-ag-ui-app:latest
[2026-03-25 17:37:45]    Status: PUSHED and VERIFIED (or verification pending)
[2026-03-25 17:37:45]    Registry: http://localhost:32000 (within VM)
[2026-03-25 17:37:45]    Ready for: Kubernetes deployment using registry image reference
[2026-03-25 17:37:45] Docker image push to registry completed with comprehensive validation
[2026-03-25 17:37:45] ✅ END: DOCKER_REGISTRY_PUSH (took 10.534561565s)
[2026-03-25 17:37:45] Verifying microk8s registry is ready for deployment...
[2026-03-25 17:37:45] === REGISTRY ACCESSIBILITY VERIFICATION STARTED ===
[2026-03-25 17:37:45] Verifying registry is running and accessible at localhost:32000...
[2026-03-25 17:37:45]    Registry purpose: Local image distribution for Kubernetes deployment
[2026-03-25 17:37:45]    Registry endpoint: http://localhost:32000
[2026-03-25 17:37:45]    Connection timeout: 5 seconds
[2026-03-25 17:37:45]    Overall timeout: 10 seconds
[2026-03-25 17:37:45]    Verification includes: Connectivity, service status, and API response validation
[2026-03-25 17:37:45] === NETWORK CONNECTIVITY ASSESSMENT ===
[2026-03-25 17:37:45] Assessing network connectivity to registry endpoint...
[2026-03-25 17:37:45]    Target: localhost:32000 (within VM)
[2026-03-25 17:37:45]    Protocol: HTTP
[2026-03-25 17:37:45]    Method: GET
[2026-03-25 17:37:45]    Expected: 200 OK with JSON catalog response
[2026-03-25 17:37:45] === REGISTRY API CONNECTIVITY TEST ===
[2026-03-25 17:37:45]    Executing: timeout 10 multipass exec 'my-ag-ui-app-k8s' -- curl -s --connect-timeout 5 http://localhost:32000/v2/_catalog
[2026-03-25 17:37:45] ✅ REGISTRY CONNECTIVITY: SUCCESS
[2026-03-25 17:37:45]    Registry connection test: PASSED
[2026-03-25 17:37:45]    Response time: .203626678 seconds
[2026-03-25 17:37:45]    Network path: Host → VM → Registry service
[2026-03-25 17:37:45]    Authentication: None required (local registry)
[2026-03-25 17:37:45] === REGISTRY RESPONSE ANALYSIS ===
[2026-03-25 17:37:45] Registry response received:
{"repositories":["my-ag-ui-app"]}
[2026-03-25 17:37:45] ✅ REGISTRY RESPONSE FORMAT: VALID JSON
[2026-03-25 17:37:45]    Response type: Docker Registry v2 API catalog
[2026-03-25 17:37:45]    Content structure: Contains repositories array
[2026-03-25 17:37:45]    Repository count: 0
[2026-03-25 17:37:45] ✅ APPLICATION REPOSITORY: EXISTS in registry
[2026-03-25 17:37:45]    Repository name: my-ag-ui-app
[2026-03-25 17:37:45]    Status: Ready for image operations
[2026-03-25 17:37:45] === COMPREHENSIVE REGISTRY STATUS ===
[2026-03-25 17:37:45] Getting detailed registry status information...
[2026-03-25 17:37:46] Registry pod status:
NAME                       READY   STATUS    RESTARTS   AGE   IP            NODE               NOMINATED NODE   READINESS GATES
registry-6cf7b9fcc-4kfg7   1/1     Running   1          2d    10.1.217.23   my-ag-ui-app-k8s   <none>           <none>
[2026-03-25 17:37:46] Registry service info:
NAME       TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
registry   NodePort   10.152.183.199   <none>        5000:32000/TCP   2d
[2026-03-25 17:37:46] Registry namespace info:
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"Namespace","metadata":{"annotations":{},"name":"container-registry"}}
  creationTimestamp: "2026-03-23T20:42:49Z"
  labels:
    kubernetes.io/metadata.name: container-registry
  name: container-registry
  resourceVersion: "256632"
  uid: 9150fa6c-e656-483b-a5dd-11628c92c5cf
spec:
  finalizers:
  - kubernetes
status:
  phase: Active
[2026-03-25 17:37:46] === ADDITIONAL REGISTRY ENDPOINT TESTS ===
[2026-03-25 17:37:46] Testing registry v2 API endpoint...
[2026-03-25 17:37:46] ✅ REGISTRY v2 API: ACCESSIBLE
[2026-03-25 17:37:46]    Endpoint: /v2/
[2026-03-25 17:37:46]    Status: 200 OK
[2026-03-25 17:37:46]    API version: Docker Registry v2
[2026-03-25 17:37:46] === REGISTRY VERIFICATION SUMMARY ===
[2026-03-25 17:37:46] ✅ Registry verification completed successfully
[2026-03-25 17:37:46]    Registry is accessible at: localhost:32000
[2026-03-25 17:37:46]    Registry can be used for local image distribution
[2026-03-25 17:37:46]    Registry endpoint: http://localhost:32000/v2/_catalog
[2026-03-25 17:37:46]    API version: Docker Registry v2
[2026-03-25 17:37:46]    Authentication: None required (local registry)
[2026-03-25 17:37:46]    Status: VERIFIED and READY
[2026-03-25 17:37:46]    Network path: Host → VM → Registry service
[2026-03-25 17:37:46]    Total verification time: .203626678 seconds
[2026-03-25 17:37:46] === REGISTRY ACCESSIBILITY VERIFICATION COMPLETED ===
[2026-03-25 17:37:46] 🔶 START: KUBERNETES_DEPLOYMENT
[2026-03-25 17:37:46] 🚀 STARTING KUBERNETES DEPLOYMENT PHASE
[2026-03-25 17:37:46] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-25 17:37:46] 📋 DEPLOYMENT DETAILS:
[2026-03-25 17:37:46]    • Manifest: k8s/deployment.yaml
[2026-03-25 17:37:46]    • Image: localhost:32000/my-ag-ui-app:latest (from local registry)
[2026-03-25 17:37:46]    • Strategy: Rolling update with pod restart
[2026-03-25 17:37:46]    • Registry: microk8s local registry
[2026-03-25 17:37:46] 
[2026-03-25 17:37:46] 🔄 STEP 1: Applying deployment manifest...
[2026-03-25 17:37:46]    • Manifest: k8s/deployment.yaml
[2026-03-25 17:37:46]    • Image: localhost:32000/my-ag-ui-app:latest (from local registry)
[2026-03-25 17:37:46]    • Strategy: Rolling update with pod restart
[2026-03-25 17:37:46]    • Registry: microk8s local registry
[2026-03-25 17:37:46] 
[2026-03-25 17:37:46] 📊 PRE-APPLOY VERIFICATION: Checking current deployment state...
[2026-03-25 17:37:48]    • Current deployment state: EXISTS
[2026-03-25 17:37:48]    • Current replicas: 1
[2026-03-25 17:37:48]    • Ready replicas: 
[2026-03-25 17:37:48]    • Updated replicas: 1
[2026-03-25 17:37:48]    • Action: UPDATE existing deployment
[2026-03-25 17:37:48] 📋 MANIFEST VALIDATION: Checking deployment.yaml file...
[2026-03-25 17:37:48] 🔍 REGISTRY PORT VALIDATION: Checking for registry port mismatches...
[2026-03-25 17:37:48]    ✓ Registry port validation: PASSED (using port 32000)
[2026-03-25 17:37:48]    • Manifest file size: 123 lines
[2026-03-25 17:37:48]    • Manifest validation: PASSED
[2026-03-25 17:37:48] 🔌 KUBERNETES CONNECTION: Verifying cluster access...
[2026-03-25 17:37:48]    • Kubernetes cluster: ACCESSIBLE
[2026-03-25 17:37:48] 🏷️  NAMESPACE VERIFICATION: Checking target namespace...
[2026-03-25 17:37:48]    • Target namespace: default
[2026-03-25 17:37:48]    • Namespace status: EXISTS and ACTIVE
[2026-03-25 17:37:48] 🚀 APPLYING DEPLOYMENT MANIFEST with detailed logging...
[2026-03-25 17:37:48]    • Command: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl apply -f k8s/deployment.yaml
[2026-03-25 17:37:48]    • Expected: Deployment resource creation/update
[2026-03-25 17:37:48]    • Output will be captured and analyzed below...
[2026-03-25 17:37:48] 📤 KUBECTL APPLY OUTPUT (first 1000 chars):
deployment.apps/my-ag-ui-app unchanged
[2026-03-25 17:37:48] ✅ KUBECTL APPLY: Command completed successfully (exit code: 0)
[2026-03-25 17:37:48]    • Result: Deployment unchanged (no changes detected)
[2026-03-25 17:37:48]    • Action: No update needed - configuration identical
[2026-03-25 17:37:48] 🔍 POST-APPLY VERIFICATION: Checking deployment status after apply...
[2026-03-25 17:37:49]    ✅ Deployment verification: PASSED
[2026-03-25 17:37:49]       • Deployment resource exists: my-ag-ui-app
[2026-03-25 17:37:49]       • Deployment spec: {"progressDeadlineSeconds":600,"replicas":1,"revisionHistoryLimit":10,"selector":{"matchLabels":{"app":"my-ag-ui-app"}},"strategy":{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"},"template":{"metadata":{"annotations":{"kubectl.kubernetes.io/restartedAt":"2026-03-25T17:27:21-04:00"},"creationTimestamp":null,"labels":{"app":"my-ag-ui-app"}},"spec":{"containers":[{"env":[{"name":"OPENAI_API_KEY","valueFrom":{"secretKeyRef":{"key":"openai-api-key","name":"my-ag-ui-app-secrets"}}},{"name":"OPENAI_BASE_URL","valueFrom":{"secretKeyRef":{"key":"openai-base-url","name":"my-ag-ui-app-secrets"}}},{"name":"OPENAI_MODEL","valueFrom":{"secretKeyRef":{"key":"openai-model","name":"my-ag-ui-app-secrets"}}},{"name":"EMBEDDING_MODEL","valueFrom":{"secretKeyRef":{"key":"embedding-model","name":"my-ag-ui-app-secrets"}}},{"name":"LOGFIRE_TOKEN","valueFrom":{"secretKeyRef":{"key":"logfire-token","name":"my-ag-ui-app-secrets"}}},{"name":"LLM_MAX_TOKENS","valueFrom":{"configMapKeyRef":{"key":"llm-max-tokens","name":"my-ag-ui-app-config"}}},{"name":"LLM_CONTEXT_WINDOW","valueFrom":{"configMapKeyRef":{"key":"llm-context-window","name":"my-ag-ui-app-config"}}}],"image":"localhost:32000/my-ag-ui-app:latest","imagePullPolicy":"Always","livenessProbe":{"failureThreshold":3,"httpGet":{"path":"/api/health","port":3000,"scheme":"HTTP"},"initialDelaySeconds":30,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5},"name":"my-ag-ui-app","ports":[{"containerPort":3000,"name":"http","protocol":"TCP"}],"readinessProbe":{"failureThreshold":3,"httpGet":{"path":"/api/health","port":3000,"scheme":"HTTP"},"initialDelaySeconds":5,"periodSeconds":5,"successThreshold":1,"timeoutSeconds":3},"resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"terminationMessagePath":"/dev/termination-log","terminationMessagePolicy":"File"}],"dnsPolicy":"ClusterFirst","restartPolicy":"Always","schedulerName":"default-scheduler","securityContext":{},"terminationGracePeriodSeconds":30}}}
[2026-03-25 17:37:49]       • Deployment status: {"conditions":[{"lastTransitionTime":"2026-03-25T20:53:24Z","lastUpdateTime":"2026-03-25T20:53:24Z","message":"Deployment does not have minimum availability.","reason":"MinimumReplicasUnavailable","status":"False","type":"Available"},{"lastTransitionTime":"2026-03-25T21:37:23Z","lastUpdateTime":"2026-03-25T21:37:23Z","message":"ReplicaSet \"my-ag-ui-app-d84bd959b\" has timed out progressing.","reason":"ProgressDeadlineExceeded","status":"False","type":"Progressing"}],"observedGeneration":4,"replicas":2,"unavailableReplicas":2,"updatedReplicas":1}
[2026-03-25 17:37:50]       ✅ Image reference verification: PASSED
[2026-03-25 17:37:50]          • Expected: localhost:32000/my-ag-ui-app:latest
[2026-03-25 17:37:50]          • Actual: localhost:32000/my-ag-ui-app:latest
[2026-03-25 17:37:50] ✅ Deployment manifest application process completed
[2026-03-25 17:37:50]    • Kubernetes deployment resource processed
[2026-03-25 17:37:50]    • Next step: Deployment restart to trigger pod creation
[2026-03-25 17:37:50] 
[2026-03-25 17:37:50] 🔄 STEP 2: Restarting deployment to trigger pod recreation...
[2026-03-25 17:37:50]    • This will create new pods using the updated registry image
[2026-03-25 17:37:50]    • Pods will pull image from localhost:32000/my-ag-ui-app:latest
deployment.apps/my-ag-ui-app restarted
[2026-03-25 17:37:50] ✅ Deployment restarted successfully
[2026-03-25 17:37:50]    • Rolling update initiated
[2026-03-25 17:37:50]    • New pods will be created using registry image
[2026-03-25 17:37:50]    • Expected: Direct pod startup (no ImagePullBackOff with registry approach)
[2026-03-25 17:37:50] 
[2026-03-25 17:37:50] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-25 17:37:50] 🎯 KUBERNETES DEPLOYMENT PHASE COMPLETED
[2026-03-25 17:37:50] 
[2026-03-25 17:37:50] 📊 DEPLOYMENT PROGRESS SUMMARY:
[2026-03-25 17:37:50] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-25 17:37:50] ✅ DEPENDENCY_VALIDATION: Package dependencies validated
[2026-03-25 17:37:50] ✅ DOCKER_IMAGE_BUILD: Image built successfully (localhost:32000/my-ag-ui-app:latest)
[2026-03-25 17:37:50] ✅ MICROK8S_REGISTRY_SETUP: Local registry enabled and accessible
[2026-03-25 17:37:50] ✅ DOCKER_REGISTRY_PUSH: Image pushed to registry with verification
[2026-03-25 17:37:50] ✅ KUBERNETES_DEPLOYMENT: Manifest applied and deployment restarted
[2026-03-25 17:37:50] 🔄 KUBERNETES_VERIFICATION: In progress - verifying pods are ready
[2026-03-25 17:37:50] ⏳ INGRESS_SETUP: Pending - will verify external access
[2026-03-25 17:37:50] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-25 17:37:50] Verifying pod status reaches Running state...
[2026-03-25 17:37:50] Checking pod status after deployment restart... (attempt 1/20)
[2026-03-25 17:37:50] Pod not yet running. Current status:
NAME                            READY   STATUS              RESTARTS        AGE
my-ag-ui-app-5777d7947b-w6hz2   0/1     Completed           15              41m
my-ag-ui-app-78d9b4f9d9-97chw   0/1     ContainerCreating   0               1s
my-ag-ui-app-d84bd959b-fpnlv    0/1     Running             7 (2m59s ago)   10m
[2026-03-25 17:37:51] Waiting for pod status change from ImagePullBackOff to Running...
[2026-03-25 17:37:54] Checking pod status after deployment restart... (attempt 2/20)
[2026-03-25 17:37:54] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS       AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running   0              4s
my-ag-ui-app-d84bd959b-fpnlv    0/1     Running   7 (3m2s ago)   10m
[2026-03-25 17:37:57] Checking pod status after deployment restart... (attempt 3/20)
[2026-03-25 17:37:58] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS       AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running   0              8s
my-ag-ui-app-d84bd959b-fpnlv    0/1     Running   7 (3m6s ago)   10m
[2026-03-25 17:38:01] Checking pod status after deployment restart... (attempt 4/20)
[2026-03-25 17:38:01] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS        AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running   0               12s
my-ag-ui-app-d84bd959b-fpnlv    0/1     Running   7 (3m10s ago)   10m
[2026-03-25 17:38:05] Checking pod status after deployment restart... (attempt 5/20)
[2026-03-25 17:38:05] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS        AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running   0               15s
my-ag-ui-app-d84bd959b-fpnlv    0/1     Running   7 (3m13s ago)   10m
[2026-03-25 17:38:08] Checking pod status after deployment restart... (attempt 6/20)
[2026-03-25 17:38:08] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS        AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running   0               19s
my-ag-ui-app-d84bd959b-fpnlv    0/1     Running   7 (3m17s ago)   10m
[2026-03-25 17:38:12] Checking pod status after deployment restart... (attempt 7/20)
[2026-03-25 17:38:12] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS        AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running   0               22s
my-ag-ui-app-d84bd959b-fpnlv    0/1     Running   7 (3m20s ago)   10m
[2026-03-25 17:38:15] Checking pod status after deployment restart... (attempt 8/20)
[2026-03-25 17:38:16] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS        AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running   0               26s
my-ag-ui-app-d84bd959b-fpnlv    0/1     Running   7 (3m24s ago)   10m
[2026-03-25 17:38:19] Checking pod status after deployment restart... (attempt 9/20)
[2026-03-25 17:38:19] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS        AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running   0               30s
my-ag-ui-app-d84bd959b-fpnlv    0/1     Running   7 (3m28s ago)   10m
[2026-03-25 17:38:23] Checking pod status after deployment restart... (attempt 10/20)
[2026-03-25 17:38:23] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS        AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running   0               33s
my-ag-ui-app-d84bd959b-fpnlv    0/1     Running   7 (3m31s ago)   11m
[2026-03-25 17:38:26] Checking pod status after deployment restart... (attempt 11/20)
[2026-03-25 17:38:27] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS        AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running   0               37s
my-ag-ui-app-d84bd959b-fpnlv    0/1     Running   7 (3m35s ago)   11m
[2026-03-25 17:38:32] Checking pod status after deployment restart... (attempt 12/20)
[2026-03-25 17:38:32] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS     AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running            0            43s
my-ag-ui-app-d84bd959b-fpnlv    0/1     CrashLoopBackOff   7 (1s ago)   11m
[2026-03-25 17:38:38] Checking pod status after deployment restart... (attempt 13/20)
[2026-03-25 17:38:38] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS     AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running            0            48s
my-ag-ui-app-d84bd959b-fpnlv    0/1     CrashLoopBackOff   7 (6s ago)   11m
[2026-03-25 17:38:43] Checking pod status after deployment restart... (attempt 14/20)
[2026-03-25 17:38:44] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS      AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running            1 (3s ago)    54s
my-ag-ui-app-d84bd959b-fpnlv    0/1     CrashLoopBackOff   7 (12s ago)   11m
[2026-03-25 17:38:49] Checking pod status after deployment restart... (attempt 15/20)
[2026-03-25 17:38:49] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS      AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running            1 (9s ago)    60s
my-ag-ui-app-d84bd959b-fpnlv    0/1     CrashLoopBackOff   7 (18s ago)   11m
[2026-03-25 17:38:55] Checking pod status after deployment restart... (attempt 16/20)
[2026-03-25 17:38:55] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS      AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running            1 (14s ago)   65s
my-ag-ui-app-d84bd959b-fpnlv    0/1     CrashLoopBackOff   7 (23s ago)   11m
[2026-03-25 17:39:00] Checking pod status after deployment restart... (attempt 17/20)
[2026-03-25 17:39:01] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS      AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running            1 (20s ago)   71s
my-ag-ui-app-d84bd959b-fpnlv    0/1     CrashLoopBackOff   7 (29s ago)   11m
[2026-03-25 17:39:06] Checking pod status after deployment restart... (attempt 18/20)
[2026-03-25 17:39:06] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS      AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running            1 (25s ago)   76s
my-ag-ui-app-d84bd959b-fpnlv    0/1     CrashLoopBackOff   7 (34s ago)   11m
[2026-03-25 17:39:11] Checking pod status after deployment restart... (attempt 19/20)
[2026-03-25 17:39:12] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS      AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running            1 (31s ago)   82s
my-ag-ui-app-d84bd959b-fpnlv    0/1     CrashLoopBackOff   7 (40s ago)   11m
[2026-03-25 17:39:17] Checking pod status after deployment restart... (attempt 20/20)
[2026-03-25 17:39:17] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS      AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running            1 (37s ago)   88s
my-ag-ui-app-d84bd959b-fpnlv    0/1     CrashLoopBackOff   7 (46s ago)   11m
[2026-03-25 17:39:18] INFO: Never observed ImagePullBackOff status (normal for registry-based deployments)
[2026-03-25 17:39:18]        With registry approach, images are readily available so pods may start directly
[2026-03-25 17:39:18] ERROR: Pod did not reach Running status after deployment restart
[2026-03-25 17:39:18] Final pod status:
NAME                            READY   STATUS             RESTARTS      AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running            1 (37s ago)   88s
my-ag-ui-app-d84bd959b-fpnlv    0/1     CrashLoopBackOff   7 (46s ago)   11m
[2026-03-25 17:39:18] Pod details for debugging:
Name:             my-ag-ui-app-78d9b4f9d9-97chw
Namespace:        default
Priority:         0
Service Account:  default
Node:             my-ag-ui-app-k8s/10.237.212.68
Start Time:       Wed, 25 Mar 2026 17:37:50 -0400
Labels:           app=my-ag-ui-app
                  pod-template-hash=78d9b4f9d9
Annotations:      cni.projectcalico.org/containerID: 3afddb5a5dc3203c5cc4871d525c94fbe655b687f87d3abc6c0227c3f06539d4
                  cni.projectcalico.org/podIP: 10.1.217.1/32
                  cni.projectcalico.org/podIPs: 10.1.217.1/32
                  kubectl.kubernetes.io/restartedAt: 2026-03-25T17:37:50-04:00
Status:           Running
IP:               10.1.217.1
IPs:
  IP:           10.1.217.1
Controlled By:  ReplicaSet/my-ag-ui-app-78d9b4f9d9
Containers:
  my-ag-ui-app:
    Container ID:   containerd://10356d8de696f0deb0fd0a61f8e6597ec56664198e9d10c4602ee483f969f9b7
    Image:          localhost:32000/my-ag-ui-app:latest
    Image ID:       localhost:32000/my-ag-ui-app@sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f
    Port:           3000/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Wed, 25 Mar 2026 17:38:41 -0400
    Last State:     Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Wed, 25 Mar 2026 17:37:51 -0400
      Finished:     Wed, 25 Mar 2026 17:38:41 -0400
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
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-g2f6d (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  kube-api-access-g2f6d:
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
  Normal   Scheduled  88s                default-scheduler  Successfully assigned default/my-ag-ui-app-78d9b4f9d9-97chw to my-ag-ui-app-k8s
  Normal   Pulled     87s                kubelet            Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 101ms (101ms including waiting). Image size: 263041608 bytes.
  Normal   Pulling    37s (x2 over 87s)  kubelet            Pulling image "localhost:32000/my-ag-ui-app:latest"
  Normal   Created    37s (x2 over 87s)  kubelet            Created container: my-ag-ui-app
  Normal   Started    37s (x2 over 87s)  kubelet            Started container my-ag-ui-app
  Normal   Killing    37s                kubelet            Container my-ag-ui-app failed liveness probe, will be restarted
  Normal   Pulled     37s                kubelet            Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 117ms (117ms including waiting). Image size: 263041608 bytes.
  Warning  Unhealthy  7s (x4 over 57s)   kubelet            Liveness probe failed: HTTP probe failed with statuscode: 404
  Warning  Unhealthy  1s (x17 over 80s)  kubelet            Readiness probe failed: HTTP probe failed with statuscode: 404


Name:             my-ag-ui-app-d84bd959b-fpnlv
Namespace:        default
Priority:         0
Service Account:  default
Node:             my-ag-ui-app-k8s/10.237.212.68
Start Time:       Wed, 25 Mar 2026 17:27:22 -0400
Labels:           app=my-ag-ui-app
                  pod-template-hash=d84bd959b
Annotations:      cni.projectcalico.org/containerID: 41753c7f69141e3c1bcd67e5e3eb14c4946aa5cf06459196e5b15567c5a7c568
                  cni.projectcalico.org/podIP: 10.1.217.9/32
                  cni.projectcalico.org/podIPs: 10.1.217.9/32
                  kubectl.kubernetes.io/restartedAt: 2026-03-25T17:27:21-04:00
Status:           Running
IP:               10.1.217.9
IPs:
  IP:           10.1.217.9
Controlled By:  ReplicaSet/my-ag-ui-app-d84bd959b
Containers:
  my-ag-ui-app:
    Container ID:   containerd://b9ebdaededb0a9e79177f6407215dd83bc083bbf6b2a92575b5742d5a1b19ca4
    Image:          localhost:32000/my-ag-ui-app:latest
    Image ID:       localhost:32000/my-ag-ui-app@sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f
    Port:           3000/TCP
    Host Port:      0/TCP
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Wed, 25 Mar 2026 17:37:36 -0400
      Finished:     Wed, 25 Mar 2026 17:38:32 -0400
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
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-wm6sj (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  kube-api-access-wm6sj:
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
  Type     Reason     Age                 From     Message
  ----     ------     ----                ----     -------
  Normal   Pulling    102s (x8 over 11m)  kubelet  Pulling image "localhost:32000/my-ag-ui-app:latest"
  Warning  Unhealthy  96s (x73 over 11m)  kubelet  Readiness probe failed: HTTP probe failed with statuscode: 404
[2026-03-25 17:39:19] ERROR TYPE: General pod startup failure - using generic error handling
[2026-03-25 17:39:19] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-25 17:39:19]                           DEPLOYMENT ERROR DETECTED
[2026-03-25 17:39:19] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-25 17:39:19] ERROR CODE: 126
[2026-03-25 17:39:19] ERROR SUMMARY: Pod did not reach Running status after deployment restart
[2026-03-25 17:39:19] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-25 17:39:19] QUICK FIX: Check pod logs: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl logs -l app=my-ag-ui-app. Verify registry is accessible: microk8s kubectl get pods -n container-registry.
[2026-03-25 17:39:19] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-25 17:39:19] ESSENTIAL DIAGNOSTIC INFO:
[2026-03-25 17:39:19] Current directory: /home/ncheaz/git/my-ag-ui-app
[2026-03-25 17:39:19] k8s directory exists: yes
[2026-03-25 17:39:19] POD STATUS DIAGNOSTICS:
NAME                            READY   STATUS             RESTARTS      AGE
my-ag-ui-app-78d9b4f9d9-97chw   0/1     Running            1 (38s ago)   89s
my-ag-ui-app-d84bd959b-fpnlv    0/1     CrashLoopBackOff   7 (47s ago)   11m
[2026-03-25 17:39:19] Docker images in VM:
IMAGE                 ID             DISK USAGE   CONTENT SIZE   EXTRA
my-ag-ui-app:latest   9bb7f1915756        546MB          263MB        
[2026-03-25 17:39:19] Recovery: Check pod logs: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl logs -l app=my-ag-ui-app
[2026-03-25 17:39:19] Manual: Delete pod to recreate: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl delete pods -l app=my-ag-ui-app
