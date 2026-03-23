[2026-03-23 11:04:26] 🚀 START: Total deployment timing
[2026-03-23 11:04:26] Starting Kubernetes secrets setup...
[2026-03-23 11:04:26] k8s directory found: /home/ncheaz/git/my-ag-ui-app/k8s/
[2026-03-23 11:04:26] setup-secrets.sh script found: /home/ncheaz/git/my-ag-ui-app/k8s/setup-secrets.sh
[2026-03-23 11:04:26] Setting up environment variables for secrets creation...
[2026-03-23 11:04:26] Loading environment variables from .env file...
[2026-03-23 11:04:26] Set environment variable: OPENAI_API_KEY
[2026-03-23 11:04:26] Set environment variable: OPENAI_BASE_URL
[2026-03-23 11:04:26] Set environment variable: OPENAI_MODEL
[2026-03-23 11:04:26] Set environment variable: LLM_MAX_TOKENS
[2026-03-23 11:04:26] Set environment variable: LLM_CONTEXT_WINDOW
[2026-03-23 11:04:26] Set environment variable: EMBEDDING_MODEL
[2026-03-23 11:04:26] All required environment variables are set
[2026-03-23 11:04:26] Running secrets setup script...
[2026-03-23 11:04:26] Setting up Kubernetes secrets...
[2026-03-23 11:04:26] Generating Kubernetes secrets file...
[2026-03-23 11:04:26] Kubernetes secrets file generated: k8s/secrets.yaml
[2026-03-23 11:04:26] Kubernetes secrets setup completed successfully
[2026-03-23 11:04:26] Starting Kubernetes deployment phase...
[2026-03-23 11:04:26] Using VM_NAME: my-ag-ui-app-k8s for Kubernetes deployment
[2026-03-23 11:04:26] 🔶 START: DEPENDENCY_VALIDATION
[2026-03-23 11:04:26] 
[2026-03-23 11:04:26] ==================================================
[2026-03-23 11:04:26]   DEPENDENCY VALIDATION BEFORE DOCKER BUILD
[2026-03-23 11:04:26] ==================================================
[2026-03-23 11:04:26] 
[2026-03-23 11:04:26] Starting lock file validation...
[2026-03-23 11:04:26] Checking if package.json and package-lock.json are in sync...
[2026-03-23 11:04:28] ✅ SUCCESS: package.json and package-lock.json are synchronized
[2026-03-23 11:04:28]    Dependencies are ready for reproducible Docker builds.
[2026-03-23 11:04:28] 
[2026-03-23 11:04:28] ✅ Dependency validation passed - proceeding with Docker build
[2026-03-23 11:04:28] ==================================================
[2026-03-23 11:04:28] 
[2026-03-23 11:04:28] ✅ END: DEPENDENCY_VALIDATION (took 1.491933976s)
[2026-03-23 11:04:28] 🔶 START: DOCKER_IMAGE_BUILD
[2026-03-23 11:04:28] Starting Docker image build process...
[2026-03-23 11:04:28] Building Docker image 'my-ag-ui-app:latest' using project Dockerfile...
[2026-03-23 11:04:28] Checking Docker daemon socket permissions...
[2026-03-23 11:04:28] Docker daemon socket permissions verified - user has access
[2026-03-23 11:04:28] Dockerfile found: /home/ncheaz/git/my-ag-ui-app/Dockerfile
[2026-03-23 11:04:28] Building Docker image 'my-ag-ui-app:latest'...
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 4.73kB done
#1 DONE 0.0s

#2 [internal] load metadata for docker.io/library/node:20.12.0-alpine
#2 DONE 0.1s

#3 [internal] load .dockerignore
#3 transferring context: 128B done
#3 DONE 0.0s

#4 [builder 1/6] FROM docker.io/library/node:20.12.0-alpine@sha256:ef3f47741e161900ddd07addcaca7e76534a9205e4cd73b2ed091ba339004a75
#4 DONE 0.0s

#5 [internal] load build context
#5 transferring context: 263.19MB 0.4s done
#5 DONE 0.4s

#6 [builder 2/6] WORKDIR /app
#6 CACHED

#7 [builder 3/6] COPY package.json package-lock.json ./
#7 CACHED

#8 [builder 4/6] RUN echo "=== DEPENDENCY INSTALLATION ===" &&     echo "Starting npm ci (reproducible install)..." &&     if npm ci --ignore-scripts; then         echo "✅ SUCCESS: npm ci completed - using reproducible dependencies from lock file";     else         echo "⚠️  WARNING: npm ci failed - lock files are out of sync";         echo "🔄 FALLING BACK to npm install to continue build...";         echo "ℹ️  NOTE: This allows deployment but reduces build reproducibility";         echo "🔧 FIX: Run 'npm install' locally and commit updated package-lock.json";         npm install --ignore-scripts;         echo "✅ SUCCESS: npm install completed - build continuing with fallback dependencies";     fi &&     echo "=== DEPENDENCY INSTALLATION COMPLETED ===" &&     npm cache clean --force
#8 CACHED

#9 [builder 5/6] COPY . .
#9 DONE 1.2s

#10 [builder 6/6] RUN npm run build
#10 0.317 
#10 0.317 > pydantic-ai-starter@0.1.0 build
#10 0.317 > next build
#10 0.317 
#10 0.950 Attention: Next.js now collects completely anonymous telemetry regarding usage.
#10 0.950 This information is used to shape Next.js' roadmap and prioritize features.
#10 0.950 You can learn more, including how to opt-out if you'd not like to participate in this anonymous program, by visiting the following URL:
#10 0.950 https://nextjs.org/telemetry
#10 0.950 
#10 0.958 ▲ Next.js 16.1.0 (Turbopack)
#10 0.958 
#10 1.003   Creating an optimized production build ...
#10 31.81 ✓ Compiled successfully in 30.5s
#10 31.81   Running TypeScript ...
#10 34.44   Collecting page data using 11 workers ...
#10 35.43   Generating static pages using 11 workers (0/5) ...
#10 36.07   Generating static pages using 11 workers (1/5) 
#10 36.10   Generating static pages using 11 workers (2/5) 
#10 36.10   Generating static pages using 11 workers (3/5) 
#10 36.76 ✓ Generating static pages using 11 workers (5/5) in 1327.4ms
#10 36.77   Finalizing page optimization ...
#10 36.93 
#10 36.94 Route (app)
#10 36.94 ┌ ○ /
#10 36.94 ├ ○ /_not-found
#10 36.94 └ ƒ /api/copilotkit
#10 36.94 
#10 36.94 
#10 36.94 ○  (Static)   prerendered as static content
#10 36.94 ƒ  (Dynamic)  server-rendered on demand
#10 36.94 
#10 DONE 37.2s

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
#15 writing image sha256:b57276563abc50e11d141f2ca5d0b586cefd5f9599891702726e03f7673ec9c2 done
#15 naming to docker.io/library/my-ag-ui-app:latest done
#15 DONE 0.8s

View build details: docker-desktop://dashboard/build/default/default/ttind0ll7apepkarjmxbvjm2j
[2026-03-23 11:05:10] Docker image 'my-ag-ui-app:latest' built successfully
[2026-03-23 11:05:10] ✅ END: DOCKER_IMAGE_BUILD (took 42.918311511s)
[2026-03-23 11:05:10] Verifying Docker image was built successfully...
[2026-03-23 11:05:10] Docker image 'my-ag-ui-app:latest' verified successfully
[2026-03-23 11:05:11] 🔶 START: VM_DOCKER_SETUP
[2026-03-23 11:05:11] Starting VM Docker setup...
[2026-03-23 11:05:11] Starting Docker setup in VM 'my-ag-ui-app-k8s'...
[2026-03-23 11:05:11] Initializing Docker state tracking...
[2026-03-23 11:05:11] Loading Docker state cache...
[2026-03-23 11:05:11] ⚠️  Docker state cache expired (29571305 minutes old, max: 30 minutes)
[2026-03-23 11:05:11] ℹ️  No valid cache available - performing full Docker setup
[2026-03-23 11:05:11] Clearing Docker state cache...
[2026-03-23 11:05:11] ✅ Docker state cache file removed: /tmp/docker-setup-state-my-ag-ui-app-k8s.json
[2026-03-23 11:05:11] Performing initial VM health check before Docker setup...
[2026-03-23 11:05:11] VM Health Check: initial-setup
[2026-03-23 11:05:11] Checking VM existence and basic accessibility...
[2026-03-23 11:05:11] ✅ VM exists and multipass service is accessible
[2026-03-23 11:05:11] Checking VM state...
[2026-03-23 11:05:11] ✅ VM state is Running
[2026-03-23 11:05:11] Checking VM basic responsiveness...
[2026-03-23 11:05:11] ✅ VM is responding to basic commands
[2026-03-23 11:05:11] Checking VM network connectivity...
[2026-03-23 11:05:11] ✅ VM has external network connectivity
[2026-03-23 11:05:11] Checking VM system resources...
[2026-03-23 11:05:12] VM Memory Usage: 1.5Gi/7.5Gi, CPU Load: 0.0%
[2026-03-23 11:05:12] ✅ VM Health Check PASSED: initial-setup
[2026-03-23 11:05:12] Performing optimized Docker availability check in VM...
[2026-03-23 11:05:12] Quick Docker availability check (CLI + daemon)...
[2026-03-23 11:05:12] ✅ OPTIMIZED: Docker CLI and daemon confirmed working in one check
[2026-03-23 11:05:12] ✅ Docker version detected: 29.3.0
[2026-03-23 11:05:12] ✅ OPTIMIZATION: Skipping individual CLI verification - already confirmed by combined check
[2026-03-23 11:05:12] Finalizing Docker state tracking...
[2026-03-23 11:05:12] Updating Docker state cache with final setup status...
[2026-03-23 11:05:12] Creating Docker state cache...
[2026-03-23 11:05:12] ✅ Docker state cache created: /tmp/docker-setup-state-my-ag-ui-app-k8s.json
[2026-03-23 11:05:12] 📊 DOCKER STATE TRACKING SUMMARY:
[2026-03-23 11:05:12] - Docker CLI available: true
[2026-03-23 11:05:12] - Docker daemon running: true
[2026-03-23 11:05:12] - User in docker group: 
[2026-03-23 11:05:12] - Docker no-sudo working: 
[2026-03-23 11:05:12] - Cache file: /tmp/docker-setup-state-my-ag-ui-app-k8s.json
[2026-03-23 11:05:12] - Next deployment will use cached state (valid for 30 minutes)
[2026-03-23 11:05:12] VM Docker setup completed successfully
[2026-03-23 11:05:12] ✅ END: VM_DOCKER_SETUP (took 1.612869604s)
[2026-03-23 11:05:12] 
[2026-03-23 11:05:12] Starting image loading methods comparison test...
[2026-03-23 11:05:12] === TASK 8.17: TESTING IMAGE LOADING WITH DIFFERENT METHODS ===
[2026-03-23 11:05:12] Testing both pipe method and file transfer method for Docker image loading...
[2026-03-23 11:05:12] Checking VM accessibility before method testing...
[2026-03-23 11:05:12] ✅ VM is accessible
[2026-03-23 11:05:12] Checking Docker daemon status in VM...
[2026-03-23 11:05:13] ✅ Docker daemon is running in VM
[2026-03-23 11:05:13] Creating temporary test directory: /tmp/image-loading-methods-test-45367
[2026-03-23 11:05:13] Step 1: Checking if my-ag-ui-app:latest image exists locally...
[2026-03-23 11:05:13] ✅ my-ag-ui-app:latest image exists locally
[2026-03-23 11:05:13] Cleaning up any existing test image from VM...
Untagged: my-ag-ui-app:latest
Deleted: sha256:772703e933ca67729b4c835e23c67f77f8d717d8adaf963e71ba44b284f0c98e
[2026-03-23 11:05:13] 
[2026-03-23 11:05:13] ==================================================
[2026-03-23 11:05:13]            TESTING PIPE METHOD
[2026-03-23 11:05:13] ==================================================
[2026-03-23 11:05:13] Command: docker save my-ag-ui-app:latest | multipass exec 'my-ag-ui-app-k8s' -- docker load
[2026-03-23 11:05:13] Starting pipe method test...
failed to ingest "blobs/sha256/52a51099bdef19b1884cced99c8948344b445e2b2f55eb1ce8c4be41ad3f14f9": short read: expected 20517376 bytes but got 2187264: unexpected EOF
[2026-03-23 11:05:14] ✅ PIPE METHOD: Command completed successfully in 1 seconds
[2026-03-23 11:05:15] ❌ PIPE METHOD: Command succeeded but image not found in VM (silent failure)
[2026-03-23 11:05:15]    This indicates a potential issue with the pipe method
[2026-03-23 11:05:15] Cleaning up image from VM after pipe test...
[2026-03-23 11:05:15] 
[2026-03-23 11:05:15] ==================================================
[2026-03-23 11:05:15]            TESTING FILE TRANSFER METHOD
[2026-03-23 11:05:15] ==================================================
[2026-03-23 11:05:15] Command sequence: docker save → multipass transfer → docker load
[2026-03-23 11:05:15] Step 2: Saving Docker image to file...
[2026-03-23 11:05:15]    Executing: docker save my-ag-ui-app:latest -o /tmp/image-loading-methods-test-45367/test-image.tar
[2026-03-23 11:05:16] ✅ FILE TRANSFER METHOD: Docker image saved successfully: 251M (263066624 bytes)
[2026-03-23 11:05:16] Step 3: Transferring image file to VM using multipass transfer...
[2026-03-23 11:05:16]    Executing: multipass transfer /tmp/image-loading-methods-test-45367/test-image.tar my-ag-ui-app-k8s:/home/ubuntu/test-image.tar
[2026-03-23T11:05:17.174] [error] [sftp] cannot access /tmp/image-loading-methods-test-45367/test-image.tar: No such file or directory
[2026-03-23 11:05:17] ✅ FILE TRANSFER METHOD: Image file transferred successfully in 1 seconds
[2026-03-23 11:05:17] Step 4: Verifying file exists in VM after transfer...
[2026-03-23 11:05:17] ✅ FILE TRANSFER METHOD: File exists in VM with size: 
[2026-03-23 11:05:17] Step 5: Loading Docker image in VM using docker load...
[2026-03-23 11:05:17]    Executing: docker load -i /home/ubuntu/test-image.tar
open /home/ubuntu/test-image.tar: no such file or directory
[2026-03-23 11:05:17] ✅ FILE TRANSFER METHOD: Docker image loaded successfully in VM in 0 seconds
[2026-03-23 11:05:17] Step 6: Verifying image is available in VM's Docker daemon...
[2026-03-23 11:05:17] ❌ FILE TRANSFER METHOD: Image not found in VM's Docker daemon after load
[2026-03-23 11:05:17]    Images in VM:
IMAGE   ID             DISK USAGE   CONTENT SIZE   EXTRA
WARNING: This output is designed for human readability. For machine-readable output, please use --format.
[2026-03-23 11:05:18] ❌ Image loading methods comparison test failed
[2026-03-23 11:05:18]    This may indicate issues with the Docker environment or VM connectivity
[2026-03-23 11:05:18]    Continuing with deployment, but method-specific issues may occur
[2026-03-23 11:05:18] 🔶 START: DOCKER_IMAGE_LOAD
[2026-03-23 11:05:18] Starting Docker image load into VM...
[2026-03-23 11:05:18] Loading Docker image 'my-ag-ui-app:latest' into multipass VM...
[2026-03-23 11:05:18] 
[2026-03-23 11:05:18] Starting multipass transfer accessibility verification...
[2026-03-23 11:05:18] === TASK 8.16: VERIFYING MULTIPASS TRANSFER ACCESSIBILITY FROM HOST SYSTEM ===
[2026-03-23 11:05:18] Testing multipass transfer accessibility with various file locations and permissions...
[2026-03-23 11:05:18] Checking VM accessibility before transfer accessibility test...
[2026-03-23 11:05:18] ✅ VM is accessible
[2026-03-23 11:05:18] Creating temporary accessibility test directory: /tmp/multipass-access-test-45367
[2026-03-23 11:05:18] Testing: Standard file in /tmp
[2026-03-23 11:05:18]   File path: Standard file in /tmp
[2026-03-23 11:05:18]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:18]   Testing multipass transfer to: /home/ubuntu/access-test-tmp
[2026-03-23 11:05:18]   ✅ TRANSFER SUCCESS: Standard file in /tmp (0s)
[2026-03-23 11:05:19]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:19]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:19] Testing: /tmp/multipass-access-test-45367/standard-file.txt
[2026-03-23 11:05:19]   File path: /tmp/multipass-access-test-45367/standard-file.txt
[2026-03-23 11:05:19]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:19]   Testing multipass transfer to: /home/ubuntu/access-test-standard-file.txt
[2026-03-23 11:05:19]   ❌ TRANSFER FAILED: /tmp/multipass-access-test-45367/standard-file.txt (0s)
[2026-03-23 11:05:19]      Error details: [2026-03-23T11:05:19.774] [error] [sftp] cannot access /tmp/multipass-access-test-45367/standard-file.txt: No such file or directory
[2026-03-23 11:05:19]      ERROR TYPE: File accessibility issue
[2026-03-23 11:05:19]      DIAGNOSTIC: multipass transfer cannot access the file from host system
[2026-03-23 11:05:19]      POSSIBLE CAUSES:
[2026-03-23 11:05:19]        - File path does not exist
[2026-03-23 11:05:19]        - File permissions prevent reading
[2026-03-23 11:05:19]        - Parent directory permissions prevent access
[2026-03-23 11:05:19]        - System-level file access restrictions
[2026-03-23 11:05:19] Testing: Standard test content
[2026-03-23 11:05:19]   File path: Standard test content
[2026-03-23 11:05:19]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:19]   Testing multipass transfer to: /home/ubuntu/access-test-Standard test content
[2026-03-23 11:05:20]   ✅ TRANSFER SUCCESS: Standard test content (1s)
[2026-03-23 11:05:20]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:20]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:20] Testing: SUCCESS
[2026-03-23 11:05:20]   File path: SUCCESS
[2026-03-23 11:05:20]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:20]   Testing multipass transfer to: /home/ubuntu/access-test-SUCCESS
[2026-03-23 11:05:20]   ✅ TRANSFER SUCCESS: SUCCESS (0s)
[2026-03-23 11:05:21]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:21]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:21] Testing: File in /tmp/docker-image-load-* directory
[2026-03-23 11:05:21]   File path: File in /tmp/docker-image-load-* directory
[2026-03-23 11:05:21]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:21]   Testing multipass transfer to: /home/ubuntu/access-test-docker-image-load-* directory
[2026-03-23 11:05:21]   ✅ TRANSFER SUCCESS: File in /tmp/docker-image-load-* directory (0s)
[2026-03-23 11:05:22]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:22]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:22] Testing: /tmp/multipass-access-test-45367/docker-image-load-12345/test-image.tar
[2026-03-23 11:05:22]   File path: /tmp/multipass-access-test-45367/docker-image-load-12345/test-image.tar
[2026-03-23 11:05:22]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:22]   Testing multipass transfer to: /home/ubuntu/access-test-test-image.tar
[2026-03-23 11:05:22]   ❌ TRANSFER FAILED: /tmp/multipass-access-test-45367/docker-image-load-12345/test-image.tar (0s)
[2026-03-23 11:05:22]      Error details: [2026-03-23T11:05:22.882] [error] [sftp] cannot access /tmp/multipass-access-test-45367/docker-image-load-12345/test-image.tar: No such file or directory
[2026-03-23 11:05:22]      ERROR TYPE: File accessibility issue
[2026-03-23 11:05:22]      DIAGNOSTIC: multipass transfer cannot access the file from host system
[2026-03-23 11:05:22]      POSSIBLE CAUSES:
[2026-03-23 11:05:22]        - File path does not exist
[2026-03-23 11:05:22]        - File permissions prevent reading
[2026-03-23 11:05:22]        - Parent directory permissions prevent access
[2026-03-23 11:05:22]        - System-level file access restrictions
[2026-03-23 11:05:22] Testing: Docker image test content
[2026-03-23 11:05:22]   File path: Docker image test content
[2026-03-23 11:05:22]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:22]   Testing multipass transfer to: /home/ubuntu/access-test-Docker image test content
[2026-03-23 11:05:23]   ✅ TRANSFER SUCCESS: Docker image test content (1s)
[2026-03-23 11:05:23]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:23]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:23] Testing: SUCCESS
[2026-03-23 11:05:23]   File path: SUCCESS
[2026-03-23 11:05:23]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:23]   Testing multipass transfer to: /home/ubuntu/access-test-SUCCESS
[2026-03-23 11:05:24]   ✅ TRANSFER SUCCESS: SUCCESS (1s)
[2026-03-23 11:05:24]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:24]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:24] Testing: File in /tmp without subdirectory
[2026-03-23 11:05:24]   File path: File in /tmp without subdirectory
[2026-03-23 11:05:24]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:24]   Testing multipass transfer to: /home/ubuntu/access-test-tmp without subdirectory
[2026-03-23 11:05:25]   ✅ TRANSFER SUCCESS: File in /tmp without subdirectory (1s)
[2026-03-23 11:05:25]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:25]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:25] Testing: /tmp/direct-access-test-45367-45367/file.txt
[2026-03-23 11:05:25]   File path: /tmp/direct-access-test-45367-45367/file.txt
[2026-03-23 11:05:25]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:25]   Testing multipass transfer to: /home/ubuntu/access-test-file.txt
[2026-03-23 11:05:26]   ❌ TRANSFER FAILED: /tmp/direct-access-test-45367-45367/file.txt (1s)
[2026-03-23 11:05:26]      Error details: [2026-03-23T11:05:26.075] [error] [sftp] cannot access /tmp/direct-access-test-45367-45367/file.txt: No such file or directory
[2026-03-23 11:05:26]      ERROR TYPE: File accessibility issue
[2026-03-23 11:05:26]      DIAGNOSTIC: multipass transfer cannot access the file from host system
[2026-03-23 11:05:26]      POSSIBLE CAUSES:
[2026-03-23 11:05:26]        - File path does not exist
[2026-03-23 11:05:26]        - File permissions prevent reading
[2026-03-23 11:05:26]        - Parent directory permissions prevent access
[2026-03-23 11:05:26]        - System-level file access restrictions
[2026-03-23 11:05:26] Testing: Direct access test content
[2026-03-23 11:05:26]   File path: Direct access test content
[2026-03-23 11:05:26]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:26]   Testing multipass transfer to: /home/ubuntu/access-test-Direct access test content
[2026-03-23 11:05:26]   ✅ TRANSFER SUCCESS: Direct access test content (0s)
[2026-03-23 11:05:26]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:26]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:27] Testing: SUCCESS
[2026-03-23 11:05:27]   File path: SUCCESS
[2026-03-23 11:05:27]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:27]   Testing multipass transfer to: /home/ubuntu/access-test-SUCCESS
[2026-03-23 11:05:27]   ✅ TRANSFER SUCCESS: SUCCESS (0s)
[2026-03-23 11:05:27]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:27]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:28] Testing: File in current working directory
[2026-03-23 11:05:28]   File path: File in current working directory
[2026-03-23 11:05:28]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:28]   Testing multipass transfer to: /home/ubuntu/access-test-File in current working directory
[2026-03-23 11:05:28]   ✅ TRANSFER SUCCESS: File in current working directory (0s)
[2026-03-23 11:05:28]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:28]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:29] Testing: ./current-dir-test-45367-45367/file.txt
[2026-03-23 11:05:29]   File path: ./current-dir-test-45367-45367/file.txt
[2026-03-23 11:05:29]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:29]   Testing multipass transfer to: /home/ubuntu/access-test-file.txt
[2026-03-23 11:05:29]   ✅ TRANSFER SUCCESS: ./current-dir-test-45367-45367/file.txt (0s)
[2026-03-23 11:05:29]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:29]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:29] Testing: Current directory test content
[2026-03-23 11:05:29]   File path: Current directory test content
[2026-03-23 11:05:30]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:30]   Testing multipass transfer to: /home/ubuntu/access-test-Current directory test content
[2026-03-23 11:05:30]   ✅ TRANSFER SUCCESS: Current directory test content (0s)
[2026-03-23 11:05:30]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:30]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:30] Testing: SUCCESS
[2026-03-23 11:05:30]   File path: SUCCESS
[2026-03-23 11:05:30]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:30]   Testing multipass transfer to: /home/ubuntu/access-test-SUCCESS
[2026-03-23 11:05:31]   ✅ TRANSFER SUCCESS: SUCCESS (1s)
[2026-03-23 11:05:31]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:31]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:31] Testing: Hidden file
[2026-03-23 11:05:31]   File path: Hidden file
[2026-03-23 11:05:31]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:31]   Testing multipass transfer to: /home/ubuntu/access-test-Hidden file
[2026-03-23 11:05:32]   ✅ TRANSFER SUCCESS: Hidden file (1s)
[2026-03-23 11:05:32]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:32]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:32] Testing: /tmp/multipass-access-test-45367/.hidden-file
[2026-03-23 11:05:32]   File path: /tmp/multipass-access-test-45367/.hidden-file
[2026-03-23 11:05:32]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:32]   Testing multipass transfer to: /home/ubuntu/access-test-.hidden-file
[2026-03-23 11:05:33]   ❌ TRANSFER FAILED: /tmp/multipass-access-test-45367/.hidden-file (1s)
[2026-03-23 11:05:33]      Error details: [2026-03-23T11:05:33.139] [error] [sftp] cannot access /tmp/multipass-access-test-45367/.hidden-file: No such file or directory
[2026-03-23 11:05:33]      ERROR TYPE: File accessibility issue
[2026-03-23 11:05:33]      DIAGNOSTIC: multipass transfer cannot access the file from host system
[2026-03-23 11:05:33]      POSSIBLE CAUSES:
[2026-03-23 11:05:33]        - File path does not exist
[2026-03-23 11:05:33]        - File permissions prevent reading
[2026-03-23 11:05:33]        - Parent directory permissions prevent access
[2026-03-23 11:05:33]        - System-level file access restrictions
[2026-03-23 11:05:33] Testing: Hidden test content
[2026-03-23 11:05:33]   File path: Hidden test content
[2026-03-23 11:05:33]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:33]   Testing multipass transfer to: /home/ubuntu/access-test-Hidden test content
[2026-03-23 11:05:33]   ✅ TRANSFER SUCCESS: Hidden test content (0s)
[2026-03-23 11:05:33]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:33]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:34] Testing: SUCCESS
[2026-03-23 11:05:34]   File path: SUCCESS
[2026-03-23 11:05:34]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:34]   Testing multipass transfer to: /home/ubuntu/access-test-SUCCESS
[2026-03-23 11:05:34]   ✅ TRANSFER SUCCESS: SUCCESS (0s)
[2026-03-23 11:05:34]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:34]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:35] Testing: File with spaces in name
[2026-03-23 11:05:35]   File path: File with spaces in name
[2026-03-23 11:05:35]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:35]   Testing multipass transfer to: /home/ubuntu/access-test-File with spaces in name
[2026-03-23 11:05:35]   ✅ TRANSFER SUCCESS: File with spaces in name (0s)
[2026-03-23 11:05:35]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:35]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:36] Testing: /tmp/multipass-access-test-45367/file with spaces.txt
[2026-03-23 11:05:36]   File path: /tmp/multipass-access-test-45367/file with spaces.txt
[2026-03-23 11:05:36]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:36]   Testing multipass transfer to: /home/ubuntu/access-test-file with spaces.txt
[2026-03-23 11:05:36]   ❌ TRANSFER FAILED: /tmp/multipass-access-test-45367/file with spaces.txt (0s)
[2026-03-23 11:05:36]      Error details: [2026-03-23T11:05:36.233] [error] [sftp] cannot access /tmp/multipass-access-test-45367/file with spaces.txt: No such file or directory
[2026-03-23 11:05:36]      ERROR TYPE: File accessibility issue
[2026-03-23 11:05:36]      DIAGNOSTIC: multipass transfer cannot access the file from host system
[2026-03-23 11:05:36]      POSSIBLE CAUSES:
[2026-03-23 11:05:36]        - File path does not exist
[2026-03-23 11:05:36]        - File permissions prevent reading
[2026-03-23 11:05:36]        - Parent directory permissions prevent access
[2026-03-23 11:05:36]        - System-level file access restrictions
[2026-03-23 11:05:36] Testing: File with spaces content
[2026-03-23 11:05:36]   File path: File with spaces content
[2026-03-23 11:05:36]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:36]   Testing multipass transfer to: /home/ubuntu/access-test-File with spaces content
[2026-03-23 11:05:36]   ✅ TRANSFER SUCCESS: File with spaces content (0s)
[2026-03-23 11:05:37]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:37]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:37] Testing: SUCCESS
[2026-03-23 11:05:37]   File path: SUCCESS
[2026-03-23 11:05:37]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:37]   Testing multipass transfer to: /home/ubuntu/access-test-SUCCESS
[2026-03-23 11:05:37]   ✅ TRANSFER SUCCESS: SUCCESS (0s)
[2026-03-23 11:05:37]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:37]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:38] Testing: File with special characters
[2026-03-23 11:05:38]   File path: File with special characters
[2026-03-23 11:05:38]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:38]   Testing multipass transfer to: /home/ubuntu/access-test-File with special characters
[2026-03-23 11:05:38]   ✅ TRANSFER SUCCESS: File with special characters (0s)
[2026-03-23 11:05:38]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:38]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:39] Testing: /tmp/multipass-access-test-45367/special-chars-@#$%^&.txt
[2026-03-23 11:05:39]   File path: /tmp/multipass-access-test-45367/special-chars-@#$%^&.txt
[2026-03-23 11:05:39]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:39]   Testing multipass transfer to: /home/ubuntu/access-test-special-chars-@#$%^&.txt
[2026-03-23 11:05:39]   ❌ TRANSFER FAILED: /tmp/multipass-access-test-45367/special-chars-@#$%^&.txt (0s)
[2026-03-23 11:05:39]      Error details: [2026-03-23T11:05:39.331] [error] [sftp] cannot access /tmp/multipass-access-test-45367/special-chars-@#$%^&.txt: No such file or directory
[2026-03-23 11:05:39]      ERROR TYPE: File accessibility issue
[2026-03-23 11:05:39]      DIAGNOSTIC: multipass transfer cannot access the file from host system
[2026-03-23 11:05:39]      POSSIBLE CAUSES:
[2026-03-23 11:05:39]        - File path does not exist
[2026-03-23 11:05:39]        - File permissions prevent reading
[2026-03-23 11:05:39]        - Parent directory permissions prevent access
[2026-03-23 11:05:39]        - System-level file access restrictions
[2026-03-23 11:05:39] Testing: Special chars test content
[2026-03-23 11:05:39]   File path: Special chars test content
[2026-03-23 11:05:39]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:39]   Testing multipass transfer to: /home/ubuntu/access-test-Special chars test content
[2026-03-23 11:05:39]   ✅ TRANSFER SUCCESS: Special chars test content (0s)
[2026-03-23 11:05:40]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:40]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:40] Testing: SUCCESS
[2026-03-23 11:05:40]   File path: SUCCESS
[2026-03-23 11:05:40]   File details: size=4.0K, permissions=-rw-rw-r--
[2026-03-23 11:05:40]   Testing multipass transfer to: /home/ubuntu/access-test-SUCCESS
[2026-03-23 11:05:40]   ✅ TRANSFER SUCCESS: SUCCESS (0s)
[2026-03-23 11:05:41]   ✅ VERIFICATION PASSED: File content matches in VM
[2026-03-23 11:05:41]   ✅ Host file size: 4.0K, VM file size: 4.0K
[2026-03-23 11:05:41] 
[2026-03-23 11:05:41] Testing permission scenarios...
[2026-03-23 11:05:41] Testing read-only file: /tmp/multipass-access-test-45367/readonly-file.txt
[2026-03-23 11:05:41]   ❌ Read-only file transfer: FAILED
[2026-03-23 11:05:41] Testing file in restricted directory: /tmp/multipass-access-test-45367/restricted-dir/restricted-file.txt
[2026-03-23 11:05:41]   ❌ Restricted directory file transfer: FAILED
[2026-03-23 11:05:41] 
[2026-03-23 11:05:41] === MULTIPASS TRANSFER ACCESSIBILITY VERIFICATION RESULTS ===
[2026-03-23 11:05:41] Total tests performed: 28
[2026-03-23 11:05:41] Successful transfers:  22
[2026-03-23 11:05:41] Failed transfers:      6
[2026-03-23 11:05:41] ⚠️  WARNING: Some multipass transfer accessibility tests failed
[2026-03-23 11:05:41] ❌ multipass transfer has accessibility issues with certain files
[2026-03-23 11:05:41] 
[2026-03-23 11:05:41] RECOMMENDATIONS:
[2026-03-23 11:05:41] 1. Use /tmp/ directory for temporary files (avoid complex subdirectories)
[2026-03-23 11:05:41] 2. Ensure files have read permissions before transfer
[2026-03-23 11:05:41] 3. Avoid special characters and spaces in file names when possible
[2026-03-23 11:05:41] 4. Use absolute paths for files to be transferred
[2026-03-23 11:05:41] ⚠️  PARTIAL: Some transfers work - use compatible file paths
[2026-03-23 11:05:41] ✅ Multipass transfer accessibility verification completed successfully
[2026-03-23 11:05:41] 
[2026-03-23 11:05:41] Starting comprehensive Docker image load investigation...
[2026-03-23 11:05:41] 
[2026-03-23 11:05:41] ==================================================
[2026-03-23 11:05:41]       DOCKER IMAGE LOAD FAILURE INVESTIGATION
[2026-03-23 11:05:41] ==================================================
[2026-03-23 11:05:41] 
[2026-03-23 11:05:41] INVESTIGATION STEP 1: Verifying Docker image exists on host...
[2026-03-23 11:05:41] ✅ INVESTIGATION FINDING: Docker image 'my-ag-ui-app:latest' exists on host
[2026-03-23 11:05:41]    Host image details:
REPOSITORY     TAG       SIZE      CREATED AT
my-ag-ui-app   latest    256MB     2026-03-23 11:05:10 -0400 EDT
[2026-03-23 11:05:41] 
[2026-03-23 11:05:41] INVESTIGATION STEP 2: Checking VM disk space before transfer...
[2026-03-23 11:05:41]    VM disk information:
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        19G  5.5G   13G  30% /
[2026-03-23 11:05:41] ✅ INVESTIGATION FINDING: Sufficient disk space in VM (13GB available)
[2026-03-23 11:05:41] 
[2026-03-23 11:05:41] INVESTIGATION STEP 3: Testing alternative file locations for Docker image save...
[2026-03-23 11:05:41] 
[2026-03-23 11:05:41] Testing file location 1/3: /tmp/ without subdirectory
[2026-03-23 11:05:41]    File path: /tmp/my-ag-ui-app-latest-45367-alternative1.tar
[2026-03-23 11:05:41]    Testing docker save to: /tmp/my-ag-ui-app-latest-45367-alternative1.tar
[2026-03-23 11:05:43] ✅ Location 1: Docker save successful
[2026-03-23 11:05:43]    File size: 251M
[2026-03-23 11:05:43]    Testing multipass transfer with this file...
[2026-03-23 11:05:43] ❌ Location 1: Multipass transfer failed
[2026-03-23 11:05:44] 
[2026-03-23 11:05:44] Testing file location 2/3: Current working directory
[2026-03-23 11:05:44]    File path: ./my-ag-ui-app-latest-45367-alternative2.tar
[2026-03-23 11:05:44]    Testing docker save to: ./my-ag-ui-app-latest-45367-alternative2.tar
[2026-03-23 11:05:45] ✅ Location 2: Docker save successful
[2026-03-23 11:05:45]    File size: 251M
[2026-03-23 11:05:45]    Testing multipass transfer with this file...
[2026-03-23 11:05:46] ✅ Location 2: Multipass transfer successful
[2026-03-23 11:05:46] ✅ Location 2: File exists in VM
Loaded image: my-ag-ui-app:latest
[2026-03-23 11:05:49] ✅ Location 2: Docker load successful in VM
[2026-03-23 11:05:49] ✅ Location 2: FULL SUCCESS - All operations completed
[2026-03-23 11:05:49] 
[2026-03-23 11:05:49] ==================================================
[2026-03-23 11:05:49]       ALTERNATIVE FILE LOCATION TEST RESULTS
[2026-03-23 11:05:49] ==================================================
[2026-03-23 11:05:49] ✅ SUCCESS: Found working file location
[2026-03-23 11:05:49]    Working location: ./my-ag-ui-app-latest-45367-alternative2.tar
[2026-03-23 11:05:49]    Using this location for detailed diagnostics...
[2026-03-23 11:05:49] 
[2026-03-23 11:05:49] INVESTIGATION STEP 4: Saving Docker image to file with comprehensive diagnostics...
[2026-03-23 11:05:49]    Validating file path construction for selected location...
[2026-03-23 11:05:49] ✅ INVESTIGATION FINDING: File path validation passed
[2026-03-23 11:05:49]    Selected location: ./my-ag-ui-app-latest-45367-alternative2.tar
[2026-03-23 11:05:49]    Directory: Current working directory
[2026-03-23 11:05:49]    Checking Docker daemon status on host...
[2026-03-23 11:05:49]    Host Docker daemon status: running
[2026-03-23 11:05:49]    Saving Docker image to file: ./my-ag-ui-app-latest-45367-alternative2.tar
[2026-03-23 11:05:49]    This may take a while for large images...
[2026-03-23 11:05:49]    EXECUTING: docker save my-ag-ui-app:latest > "./my-ag-ui-app-latest-45367-alternative2.tar"
[2026-03-23 11:05:49]    Capturing stdout and stderr separately for detailed debugging...
[2026-03-23 11:05:51]    Docker save command completed in 2 seconds
[2026-03-23 11:05:51]    Docker save exit code: 0
[2026-03-23 11:05:51] ✅ INVESTIGATION FINDING: Docker save command succeeded
[2026-03-23 11:05:51]    Docker save execution time: 2 seconds
[2026-03-23 11:05:51]    === DETAILED DOCKER SAVE SUCCESS LOGGING ===
[2026-03-23 11:05:51]    Command executed: docker save my-ag-ui-app:latest > "./my-ag-ui-app-latest-45367-alternative2.tar"
[2026-03-23 11:05:51]    Stdout: Successfully redirected to image file
[2026-03-23 11:05:51]    Stderr: No warnings or errors
[2026-03-23 11:05:51]    === END DOCKER SAVE SUCCESS LOGGING ===
[2026-03-23 11:05:51]    Verifying saved file properties...
[2026-03-23 11:05:51] ✅ INVESTIGATION FINDING: Docker image saved successfully
[2026-03-23 11:05:51]    File path: ./my-ag-ui-app-latest-45367-alternative2.tar
[2026-03-23 11:05:51]    File size: 251M (263066624 bytes)
[2026-03-23 11:05:51]    File MD5 hash: 074af516a84f77f669e0186969f8eaa2
[2026-03-23 11:05:51] 
[2026-03-23 11:05:51] INVESTIGATION STEP 5: Testing file integrity before transfer...
[2026-03-23 11:05:51]    Testing saved image by loading it back locally...
[2026-03-23 11:05:51] ✅ INVESTIGATION FINDING: Saved image file integrity verified (can be loaded back locally)
Untagged: my-ag-ui-app:latest
Deleted: sha256:b57276563abc50e11d141f2ca5d0b586cefd5f9599891702726e03f7673ec9c2
[2026-03-23 11:05:51] 
[2026-03-23 11:05:51] INVESTIGATION STEP 6: Transferring image file to VM with detailed diagnostics...
[2026-03-23 11:05:51]    Checking VM accessibility before transfer...
[2026-03-23 11:05:52] ✅ INVESTIGATION FINDING: VM is accessible
[2026-03-23 11:05:52]    Transferring image file to VM: my-ag-ui-app-k8s:/home/ubuntu/my-ag-ui-app-latest.tar
[2026-03-23 11:05:52]    This may take a while for large images...
[2026-03-23 11:05:53] ✅ INVESTIGATION FINDING: Image file transferred successfully to VM
[2026-03-23 11:05:53] 
[2026-03-23 11:05:53] INVESTIGATION STEP 7: Verifying file exists in VM after transfer...
[2026-03-23 11:05:54] ✅ INVESTIGATION FINDING: Transferred file exists in VM
[2026-03-23 11:05:54]    VM file path: /home/ubuntu/my-ag-ui-app-latest.tar
[2026-03-23 11:05:54]    VM file size: 251M (263066624 bytes)
[2026-03-23 11:05:54]    VM file MD5 hash: 074af516a84f77f669e0186969f8eaa2
[2026-03-23 11:05:54] ✅ INVESTIGATION FINDING: File size matches between host and VM
[2026-03-23 11:05:54] ✅ INVESTIGATION FINDING: File MD5 hash matches between host and VM
[2026-03-23 11:05:54]    File integrity verified - no corruption during transfer
[2026-03-23 11:05:54] 
[2026-03-23 11:05:54] INVESTIGATION STEP 8: Loading Docker image in VM with comprehensive monitoring...
[2026-03-23 11:05:54]    Checking Docker daemon status in VM before load...
[2026-03-23 11:05:54]    VM Docker daemon status: running
[2026-03-23 11:05:54]    Checking VM disk space before docker load...
[2026-03-23 11:05:54]    VM disk space before load: 12GB available
[2026-03-23 11:05:54]    Loading Docker image in VM...
[2026-03-23 11:05:54]    This may take a while for large images...
[2026-03-23 11:05:54]    === TASK 8.8: DOCKER LOAD WITH RETRY LOGIC ===
[2026-03-23 11:05:54]    Docker load will attempt up to 3 times with exponential backoff
[2026-03-23 11:05:54]    === DOCKER LOAD ATTEMPT 1/3 ===
[2026-03-23 11:05:54]    === TASK 8.4: VERIFY DOCKER LOAD COMMAND RECEPTION AND EXECUTION ===
[2026-03-23 11:05:54]    Step 1: Verifying command transmission to VM...
[2026-03-23 11:05:54]    EXECUTING: multipass exec "my-ag-ui-app-k8s" -- sh -c "docker load -i /home/ubuntu/my-ag-ui-app-latest.tar"
[2026-03-23 11:05:54]    Capturing stdout and stderr separately in VM for detailed debugging...
[2026-03-23 11:05:54]    Step 2: Creating command receipt verification in VM...
[2026-03-23 11:05:54]    ✓ Command receipt verification: VM is ready to receive commands
[2026-03-23 11:05:54]    ✓ Receipt confirmation: DOCKER_LOAD_COMMAND_RECEIVED: 1774278354.487614951
[2026-03-23 11:05:54]    Step 3: Executing docker load command with transmission verification...
[2026-03-23 11:05:54]    EXECUTING in VM: docker load -i /home/ubuntu/my-ag-ui-app-latest.tar 1> /tmp/vm_load_stdout.log 2> /tmp/vm_load_stderr.log; echo 'DOCKER_LOAD_EXECUTION_ATTEMPTED: $?' > /tmp/docker_load_execution.log
[2026-03-23 11:05:56]    ✅ DOCKER LOAD ATTEMPT 1 SUCCEEDED
[2026-03-23 11:05:56]    Step 4: Verifying command execution in VM...
[2026-03-23 11:05:57]    Execution verification log: DOCKER_LOAD_EXECUTION_ATTEMPTED: $?
[2026-03-23 11:05:57]    ✓ Command execution verified in VM (internal exit code: $?)
[2026-03-23 11:05:57]    ⚠️  Exit code mismatch - multipass: 0, VM internal: $?
[2026-03-23 11:05:57]       This may indicate communication issues between host and VM
[2026-03-23 11:05:57]    Step 5: Retrieving command output from VM...
[2026-03-23 11:05:57]    Stdout file exists in VM: yes
[2026-03-23 11:05:57]    Stderr file exists in VM: yes
[2026-03-23 11:05:57]    === END TASK 8.4: DOCKER LOAD COMMAND VERIFICATION ===
[2026-03-23 11:05:57]    Docker load command completed in 3 seconds
[2026-03-23 11:05:57]    Docker load exit code: 0
[2026-03-23 11:05:57]    === END TASK 8.8: DOCKER LOAD WITH RETRY LOGIC ===
[2026-03-23 11:05:57]    === DETAILED DOCKER LOAD LOGGING ===
[2026-03-23 11:05:57]    Command executed in VM: docker load -i /home/ubuntu/my-ag-ui-app-latest.tar
[2026-03-23 11:05:57]    Stdout content:
Loaded image: my-ag-ui-app:latest
[2026-03-23 11:05:57]    Stderr content:
[2026-03-23 11:05:57]    No stderr output captured
[2026-03-23 11:05:57]    === END DETAILED DOCKER LOAD LOGGING ===
[2026-03-23 11:05:57]    Docker load combined output (stdout + stderr):
Loaded image: my-ag-ui-app:latest
[2026-03-23 11:05:57] ✅ INVESTIGATION FINDING: Docker load command succeeded in VM on first attempt
[2026-03-23 11:05:57]    Duration: 3 seconds
[2026-03-23 11:05:57]    === DETAILED DOCKER LOAD SUCCESS ANALYSIS ===
[2026-03-23 11:05:57]    Stdout analysis:
[2026-03-23 11:05:57]    ✓ Stdout confirms successful image load
[2026-03-23 11:05:57]    ✓ Loaded image: my-ag-ui-app:latest
[2026-03-23 11:05:57]    - No stderr content (clean execution)
[2026-03-23 11:05:57]    === END DOCKER LOAD SUCCESS ANALYSIS ===
[2026-03-23 11:05:57]    === TASK 8.6: EXPLICIT DOCKER LOAD ERROR CHECKING ===
[2026-03-23 11:05:57]    Explicit Validation Step 1: Verifying docker load operation completion...
[2026-03-23 11:05:57]    ✓ EXPLICIT: Docker load operation reported success in stdout
[2026-03-23 11:05:57]    Explicit Validation Step 2: Checking for silent failures...
[2026-03-23 11:05:57]    ✓ EXPLICIT: No stderr content (clean execution)
[2026-03-23 11:05:57]    Explicit Validation Step 3: Verifying image file processing...
[2026-03-23 11:05:57]    ✓ EXPLICIT: Image file processing completed (found success message)
[2026-03-23 11:05:57]    Explicit Validation Step 4: Verifying Docker daemon processing...
[2026-03-23 11:05:57]    ✓ EXPLICIT: No Docker daemon processing issues (no stderr)
[2026-03-23 11:05:57]    Explicit Validation Step 5: Overall docker load validation...
[2026-03-23 11:05:57]    ✅ EXPLICIT: All explicit validation checks passed
[2026-03-23 11:05:57]       ✓ Docker load operation completed successfully
[2026-03-23 11:05:57]       ✓ Image file was properly processed
[2026-03-23 11:05:57]       ✓ Docker daemon handled the load correctly
[2026-03-23 11:05:57]    === END TASK 8.6: EXPLICIT DOCKER LOAD ERROR CHECKING ===
[2026-03-23 11:05:57]    Checking VM disk space after docker load...
[2026-03-23 11:05:58]    VM disk space after load: 12GB available
[2026-03-23 11:05:58]    Disk space used by image: 0GB
[2026-03-23 11:05:58] ✅ INVESTIGATION FINDING: Docker image loaded successfully in VM
[2026-03-23 11:05:58]    Load duration: 3 seconds
[2026-03-23 11:05:58] 
[2026-03-23 11:05:58] INVESTIGATION STEP 9: Verifying image exists in VM's Docker daemon...
[2026-03-23 11:05:58]    Waiting 2 seconds after load before verification...
[2026-03-23 11:06:00]    Docker images command in VM (exit code: 0):
REPOSITORY     TAG       SIZE      CREATED AT
my-ag-ui-app   latest    546MB     2026-03-23 11:05:10 -0400 EDT
[2026-03-23 11:06:00] ✅ INVESTIGATION FINDING: Docker image 'my-ag-ui-app:latest' found in VM
[2026-03-23 11:06:00]    VM image size: 546MB
[2026-03-23 11:06:00]    VM image created: 2026-03-23 11:05:10
[2026-03-23 11:06:00] 
[2026-03-23 11:06:00] INVESTIGATION STEP 10: Enhanced system diagnostics and error reporting...
[2026-03-23 11:06:00]    Enhanced Diagnostic 10.1: Network connectivity diagnostics...
[2026-03-23 11:06:00]    Testing host-to-VM network connectivity...
[2026-03-23 11:06:00]    ✓ NETWORK: VM can reach external network
[2026-03-23 11:06:00]    ✓ NETWORK: DNS resolution working in VM
[2026-03-23 11:06:00]    ✓ NETWORK: Docker registry accessible
[2026-03-23 11:06:00]    Network diagnostics completed in 0 seconds
[2026-03-23 11:06:00]    Enhanced Diagnostic 10.2: System resource monitoring...
[2026-03-23 11:06:00]    Collecting VM system resource information...
[2026-03-23 11:06:01]    CPU: AMD Ryzen 5 7600X 6-Core Processor (4 cores)
[2026-03-23 11:06:01]    Memory: Total=7.5Gi, Available=6.0Gi
[2026-03-23 11:06:01]    Load average:0.52, 0.22, 0.16
[2026-03-23 11:06:01]    ❌ RESOURCE: Critically low memory available (6.0Gi)
[2026-03-23 11:06:01]       This may cause Docker operations to fail
[2026-03-23 11:06:01]    Enhanced Diagnostic 10.3: Docker daemon configuration verification...
[2026-03-23 11:06:01]    Checking Docker daemon configuration in VM...
[2026-03-23 11:06:01]    Docker service status: active
[2026-03-23 11:06:02]    Docker daemon config exists: no
[2026-03-23 11:06:02]    Checking Docker daemon logs for recent errors...
[2026-03-23 11:06:02]    ⚠️  DOCKER: Recent errors/warnings found in Docker daemon logs
[2026-03-23 11:06:02]       Relevant log entries:
Mar 23 11:01:40 my-ag-ui-app-k8s dockerd[1368885]: time="2026-03-23T11:01:40.714029977-04:00" level=error msg="failed to validate image signature" error="resolving signature chain for image sha256:772703e933ca67729b4c835e23c67f77f8d717d8adaf963e71ba44b284f0c98e: expected image index descriptor, got application/vnd.oci.image.manifest.v1+json"
Mar 23 11:01:57 my-ag-ui-app-k8s dockerd[1368885]: time="2026-03-23T11:01:57.158402350-04:00" level=warning msg="multiple images have the same target, but one of them is still dangling" refs="[{docker.io/library/my-ag-ui-app:latest map[] {application/vnd.oci.image.manifest.v1+json sha256:772703e933ca67729b4c835e23c67f77f8d717d8adaf963e71ba44b284f0c98e 1620 [] map[io.containerd.image.name:docker.io/library/my-ag-ui-app:latest org.opencontainers.image.ref.name:latest] [] <nil> } 2026-03-23 15:01:40.699882157 +0000 UTC 2026-03-23 15:01:49.606734574 +0000 UTC} {moby-dangling@sha256:772703e933ca67729b4c835e23c67f77f8d717d8adaf963e71ba44b284f0c98e map[] {application/vnd.oci.image.manifest.v1+json sha256:772703e933ca67729b4c835e23c67f77f8d717d8adaf963e71ba44b284f0c98e 1620 [] map[io.containerd.image.name:docker.io/library/my-ag-ui-app:latest org.opencontainers.image.ref.name:latest] [] <nil> } 2026-03-23 15:01:49.590935025 +0000 UTC 2026-03-23 15:01:49.590935025 +0000 UTC}]"
Mar 23 11:05:48 my-ag-ui-app-k8s dockerd[1368885]: time="2026-03-23T11:05:48.542913185-04:00" level=error msg="failed to validate image signature" error="resolving signature chain for image sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f: expected image index descriptor, got application/vnd.oci.image.manifest.v1+json"
[2026-03-23 11:06:02]    Enhanced Diagnostic 10.4: File system validation...
[2026-03-23 11:06:02]    Checking file system health in VM...
[2026-03-23 11:06:02]    File system: /dev/sda1, Size: 19G, Used: 6.5G, Available: 12G (36% used)
[2026-03-23 11:06:02]    ✓ FILESYSTEM: healthy disk usage (36%)
[2026-03-23 11:06:02]    Docker data directory exists: yes
[2026-03-23 11:06:02]    Docker data directory size: 4.0K
[2026-03-23 11:06:02]    Enhanced Diagnostic 10.5: Comprehensive error context collection...
[2026-03-23 11:06:02]    Collecting system information for error context...
[2026-03-23 11:06:03]    Operating System: Ubuntu 24.04.4 LTS
[2026-03-23 11:06:03]    Kernel version: 6.8.0-101-generic
[2026-03-23 11:06:03]    Docker version: Docker version 29.3.0, build 5927d80
[2026-03-23 11:06:03]    Current user: ubuntu
[2026-03-23 11:06:03]    User groups: ubuntu adm cdrom sudo dip lxd docker microk8s
[2026-03-23 11:06:03]    ✓ USER: user is in docker group
[2026-03-23 11:06:04]    Docker socket permissions: srw-rw---- 1 root docker 0 Mar 22 16:42 /var/run/docker.sock
[2026-03-23 11:06:04] 
[2026-03-23 11:06:04] INVESTIGATION STEP 11: Testing Docker image functionality in VM...
[2026-03-23 11:06:04]    Testing if image can be inspected...
[2026-03-23 11:06:04] ✅ INVESTIGATION FINDING: Docker image can be inspected in VM
[2026-03-23 11:06:04]    VM image ID: sha256:9bb7f
[2026-03-23 11:06:04]    VM image size: 263041608 bytes
[2026-03-23 11:06:04] 
[2026-03-23 11:06:04] INVESTIGATION CLEANUP: Removing temporary file in VM...
[2026-03-23 11:06:04] INVESTIGATION CLEANUP: Removing detailed logging temporary files...
[2026-03-23 11:06:04] INVESTIGATION CLEANUP: Removing temporary files in VM...
[2026-03-23 11:06:04] INVESTIGATION CLEANUP: Removing local temporary directory...
[2026-03-23 11:06:04] 
[2026-03-23 11:06:04] ==================================================
[2026-03-23 11:06:04]       ENHANCED INVESTIGATION COMPLETED SUCCESSFULLY
[2026-03-23 11:06:04] ==================================================
[2026-03-23 11:06:04] 
[2026-03-23 11:06:04] ✅ All investigation steps passed
[2026-03-23 11:06:04] ✅ Docker image is properly loaded and functional in VM
[2026-03-23 11:06:04] ✅ Image transfer was successful with no corruption
[2026-03-23 11:06:04] ✅ Image can be accessed and inspected in VM
[2026-03-23 11:06:04] ✅ Network connectivity verified and healthy
[2026-03-23 11:06:04] ✅ System resources monitored and sufficient
[2026-03-23 11:06:04] ✅ Docker daemon configuration validated
[2026-03-23 11:06:04] ✅ File system health confirmed
[2026-03-23 11:06:04] ✅ Comprehensive error context collected
[2026-03-23 11:06:04] 
[2026-03-23 11:06:04] ✅ Docker image load investigation completed successfully
[2026-03-23 11:06:04] ✅ END: DOCKER_IMAGE_LOAD (took 46.330315730s)
[2026-03-23 11:06:04] Verifying Docker image is available in VM's Docker daemon...
[2026-03-23 11:06:04] All Docker images in VM:
REPOSITORY     TAG       SIZE      CREATED AT
my-ag-ui-app   latest    546MB     2026-03-23 11:05:10 -0400 EDT
[2026-03-23 11:06:04] Docker image 'my-ag-ui-app:latest' verified successfully in VM
[2026-03-23 11:06:04] 🔶 START: KUBERNETES_FILE_TRANSFER
[2026-03-23 11:06:04] Preparing to create k8s directory in VM...
[2026-03-23 11:06:04] Creating k8s directory in VM...
[2026-03-23 11:06:05] k8s directory created successfully in VM
[2026-03-23 11:06:05] Transferring secrets.yaml to VM...
[2026-03-23 11:06:05] secrets.yaml transferred successfully to VM
[2026-03-23 11:06:05] Transferring deployment.yaml to VM...
[2026-03-23 11:06:05] deployment.yaml transferred successfully to VM
[2026-03-23 11:06:05] Transferring service.yaml to VM...
[2026-03-23 11:06:05] service.yaml transferred successfully to VM
[2026-03-23 11:06:05] Transferring ingress.yaml to VM...
[2026-03-23 11:06:05] ingress.yaml transferred successfully to VM
[2026-03-23 11:06:05] Starting file validation process in VM...
[2026-03-23 11:06:05] Validating that secrets.yaml exists in VM...
[2026-03-23 11:06:06] secrets.yaml validation successful - file exists in VM
[2026-03-23 11:06:06] Validating that deployment.yaml exists in VM...
[2026-03-23 11:06:06] deployment.yaml validation successful - file exists in VM
[2026-03-23 11:06:06] Validating that service.yaml exists in VM...
[2026-03-23 11:06:06] service.yaml validation successful - file exists in VM
[2026-03-23 11:06:06] Validating that ingress.yaml exists in VM...
[2026-03-23 11:06:06] ingress.yaml validation successful - file exists in VM
[2026-03-23 11:06:06] All Kubernetes files validated successfully in VM
[2026-03-23 11:06:06] ✅ END: KUBERNETES_FILE_TRANSFER (took 1.742392769s)
[2026-03-23 11:06:06] 🔶 START: KUBERNETES_SECRETS_SETUP
[2026-03-23 11:06:06] Applying Kubernetes secrets...
secret/my-ag-ui-app-secrets unchanged
configmap/my-ag-ui-app-config unchanged
[2026-03-23 11:06:07] Kubernetes secrets applied successfully
[2026-03-23 11:06:07] ✅ END: KUBERNETES_SECRETS_SETUP (took .421233876s)
[2026-03-23 11:06:07] 🔶 START: KUBERNETES_DEPLOYMENT
[2026-03-23 11:06:07] Applying deployment manifest...
deployment.apps/my-ag-ui-app unchanged
[2026-03-23 11:06:07] Deployment manifest applied successfully
[2026-03-23 11:06:07] Restarting deployment to trigger pod recreation with new image...
deployment.apps/my-ag-ui-app restarted
[2026-03-23 11:06:07] Deployment restarted successfully - pods will be recreated with new image
[2026-03-23 11:06:07] Verifying pod status changes from ImagePullBackOff to Running...
[2026-03-23 11:06:07] Checking pod status after deployment restart... (attempt 1/20)
[2026-03-23 11:06:08] Pod not yet running. Current status:
NAME                            READY   STATUS                   RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ContainerCreating        0          1s
my-ag-ui-app-64568b4968-h85n8   1/1     Running                  1          37h
my-ag-ui-app-6746d8d677-psl8c   0/1     ContainerStatusUnknown   0          4m8s
[2026-03-23 11:06:08] Waiting for pod status change from ImagePullBackOff to Running...
[2026-03-23 11:06:11] Checking pod status after deployment restart... (attempt 2/20)
[2026-03-23 11:06:11] Pod status: ImagePullBackOff detected (expected before pod starts running)
[2026-03-23 11:06:11] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ImagePullBackOff   0          5s
my-ag-ui-app-64568b4968-h85n8   1/1     Running            1          37h
[2026-03-23 11:06:15] Checking pod status after deployment restart... (attempt 3/20)
[2026-03-23 11:06:15] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ImagePullBackOff   0          8s
my-ag-ui-app-64568b4968-h85n8   1/1     Running            1          37h
[2026-03-23 11:06:18] Checking pod status after deployment restart... (attempt 4/20)
[2026-03-23 11:06:19] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ImagePullBackOff   0          12s
my-ag-ui-app-64568b4968-h85n8   1/1     Running            1          37h
[2026-03-23 11:06:22] Checking pod status after deployment restart... (attempt 5/20)
[2026-03-23 11:06:22] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ImagePullBackOff   0          16s
my-ag-ui-app-64568b4968-h85n8   1/1     Running            1          37h
[2026-03-23 11:06:26] Checking pod status after deployment restart... (attempt 6/20)
[2026-03-23 11:06:26] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ImagePullBackOff   0          19s
my-ag-ui-app-64568b4968-h85n8   1/1     Running            1          37h
[2026-03-23 11:06:29] Checking pod status after deployment restart... (attempt 7/20)
[2026-03-23 11:06:30] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ImagePullBackOff   0          23s
my-ag-ui-app-64568b4968-h85n8   1/1     Running            1          37h
[2026-03-23 11:06:33] Checking pod status after deployment restart... (attempt 8/20)
[2026-03-23 11:06:33] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ImagePullBackOff   0          27s
my-ag-ui-app-64568b4968-h85n8   1/1     Running            1          37h
[2026-03-23 11:06:37] Checking pod status after deployment restart... (attempt 9/20)
[2026-03-23 11:06:37] Pod not yet running. Current status:
NAME                            READY   STATUS         RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ErrImagePull   0          30s
my-ag-ui-app-64568b4968-h85n8   1/1     Running        1          37h
[2026-03-23 11:06:40] Checking pod status after deployment restart... (attempt 10/20)
[2026-03-23 11:06:41] Pod not yet running. Current status:
NAME                            READY   STATUS         RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ErrImagePull   0          34s
my-ag-ui-app-64568b4968-h85n8   1/1     Running        1          37h
[2026-03-23 11:06:44] Checking pod status after deployment restart... (attempt 11/20)
[2026-03-23 11:06:44] Pod not yet running. Current status:
NAME                            READY   STATUS         RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ErrImagePull   0          38s
my-ag-ui-app-64568b4968-h85n8   1/1     Running        1          37h
[2026-03-23 11:06:50] Checking pod status after deployment restart... (attempt 12/20)
[2026-03-23 11:06:50] Pod not yet running. Current status:
NAME                            READY   STATUS         RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ErrImagePull   0          43s
my-ag-ui-app-64568b4968-h85n8   1/1     Running        1          37h
[2026-03-23 11:06:55] Checking pod status after deployment restart... (attempt 13/20)
[2026-03-23 11:06:56] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ImagePullBackOff   0          49s
my-ag-ui-app-64568b4968-h85n8   1/1     Running            1          37h
[2026-03-23 11:07:01] Checking pod status after deployment restart... (attempt 14/20)
[2026-03-23 11:07:01] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ImagePullBackOff   0          55s
my-ag-ui-app-64568b4968-h85n8   1/1     Running            1          37h
[2026-03-23 11:07:07] Checking pod status after deployment restart... (attempt 15/20)
[2026-03-23 11:07:07] Pod not yet running. Current status:
NAME                            READY   STATUS         RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ErrImagePull   0          60s
my-ag-ui-app-64568b4968-h85n8   1/1     Running        1          37h
[2026-03-23 11:07:12] Checking pod status after deployment restart... (attempt 16/20)
[2026-03-23 11:07:13] Pod not yet running. Current status:
NAME                            READY   STATUS         RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ErrImagePull   0          66s
my-ag-ui-app-64568b4968-h85n8   1/1     Running        1          37h
[2026-03-23 11:07:18] Checking pod status after deployment restart... (attempt 17/20)
[2026-03-23 11:07:18] Pod not yet running. Current status:
NAME                            READY   STATUS         RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ErrImagePull   0          72s
my-ag-ui-app-64568b4968-h85n8   1/1     Running        1          37h
[2026-03-23 11:07:24] Checking pod status after deployment restart... (attempt 18/20)
[2026-03-23 11:07:24] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ImagePullBackOff   0          77s
my-ag-ui-app-64568b4968-h85n8   1/1     Running            1          37h
[2026-03-23 11:07:29] Checking pod status after deployment restart... (attempt 19/20)
[2026-03-23 11:07:30] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ImagePullBackOff   0          83s
my-ag-ui-app-64568b4968-h85n8   1/1     Running            1          37h
[2026-03-23 11:07:35] Checking pod status after deployment restart... (attempt 20/20)
[2026-03-23 11:07:35] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ImagePullBackOff   0          88s
my-ag-ui-app-64568b4968-h85n8   1/1     Running            1          37h
[2026-03-23 11:07:35] ERROR: Pod did not reach Running status after deployment restart
[2026-03-23 11:07:35] Final pod status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ImagePullBackOff   0          89s
my-ag-ui-app-64568b4968-h85n8   1/1     Running            1          37h
[2026-03-23 11:07:36] Pod details for debugging:
Name:             my-ag-ui-app-58584948f8-dq24z
Namespace:        default
Priority:         0
Service Account:  default
Node:             my-ag-ui-app-k8s/10.237.212.68
Start Time:       Mon, 23 Mar 2026 11:06:07 -0400
Labels:           app=my-ag-ui-app
                  pod-template-hash=58584948f8
Annotations:      cni.projectcalico.org/containerID: 4e9a2038b388ee82980d80c70e7645c878bcaa784f9c520f5d70d383876ae6e9
                  cni.projectcalico.org/podIP: 10.1.217.18/32
                  cni.projectcalico.org/podIPs: 10.1.217.18/32
                  kubectl.kubernetes.io/restartedAt: 2026-03-23T11:06:07-04:00
Status:           Pending
IP:               10.1.217.18
IPs:
  IP:           10.1.217.18
Controlled By:  ReplicaSet/my-ag-ui-app-58584948f8
Containers:
  my-ag-ui-app:
    Container ID:   
    Image:          my-ag-ui-app:latest
    Image ID:       
    Port:           3000/TCP
    Host Port:      0/TCP
    State:          Waiting
      Reason:       ImagePullBackOff
    Ready:          False
    Restart Count:  0
    Limits:
      cpu:     500m
      memory:  512Mi
    Requests:
      cpu:      100m
      memory:   256Mi
    Liveness:   http-get http://:3000/health delay=30s timeout=5s period=10s #success=1 #failure=3
    Readiness:  http-get http://:3000/health delay=5s timeout=3s period=5s #success=1 #failure=3
    Environment:
      OPENAI_API_KEY:      <set to the key 'openai-api-key' in secret 'my-ag-ui-app-secrets'>         Optional: false
      OPENAI_BASE_URL:     <set to the key 'openai-base-url' in secret 'my-ag-ui-app-secrets'>        Optional: false
      OPENAI_MODEL:        <set to the key 'openai-model' in secret 'my-ag-ui-app-secrets'>           Optional: false
      EMBEDDING_MODEL:     <set to the key 'embedding-model' in secret 'my-ag-ui-app-secrets'>        Optional: false
      LOGFIRE_TOKEN:       <set to the key 'logfire-token' in secret 'my-ag-ui-app-secrets'>          Optional: false
      LLM_MAX_TOKENS:      <set to the key 'llm-max-tokens' of config map 'my-ag-ui-app-config'>      Optional: false
      LLM_CONTEXT_WINDOW:  <set to the key 'llm-context-window' of config map 'my-ag-ui-app-config'>  Optional: false
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-x5qkz (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  kube-api-access-x5qkz:
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
  Normal   Scheduled  88s                default-scheduler  Successfully assigned default/my-ag-ui-app-58584948f8-dq24z to my-ag-ui-app-k8s
  Normal   Pulling    44s (x3 over 88s)  kubelet            Pulling image "my-ag-ui-app:latest"
  Warning  Failed     44s (x3 over 88s)  kubelet            Failed to pull image "my-ag-ui-app:latest": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/my-ag-ui-app:latest": failed to unpack image on snapshotter overlayfs: unexpected media type text/html for sha256:f77c7a12d8c2e93e4122bea2b9cc50a8742af407192a1d3646e6df6f30361d89: not found
  Warning  Failed     44s (x3 over 88s)  kubelet            Error: ErrImagePull
  Normal   BackOff    4s (x6 over 87s)   kubelet            Back-off pulling image "my-ag-ui-app:latest"
  Warning  Failed     4s (x6 over 87s)   kubelet            Error: ImagePullBackOff


Name:             my-ag-ui-app-64568b4968-h85n8
Namespace:        default
Priority:         0
Service Account:  default
Node:             my-ag-ui-app-k8s/10.237.212.68
Start Time:       Sat, 21 Mar 2026 21:09:17 -0400
Labels:           app=my-ag-ui-app
                  pod-template-hash=64568b4968
Annotations:      cni.projectcalico.org/containerID: 3a292b993f50700e3f675073dd5b69b84c293eaac5fe3db7f016e01f2ed5ebaf
                  cni.projectcalico.org/podIP: 10.1.217.12/32
                  cni.projectcalico.org/podIPs: 10.1.217.12/32
Status:           Running
IP:               10.1.217.12
IPs:
  IP:           10.1.217.12
Controlled By:  ReplicaSet/my-ag-ui-app-64568b4968
Containers:
  my-ag-ui-app:
    Container ID:   containerd://0294b28f39eb0bcd3d55ebc53d56854fb5096537c99bd4e892cb50388d864d6e
    Image:          nginx:latest
    Image ID:       docker.io/library/nginx@sha256:dec7a90bd0973b076832dc56933fe876bc014929e14b4ec49923951405370112
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Sun, 22 Mar 2026 16:43:00 -0400
    Ready:          True
    Restart Count:  1
    Limits:
      cpu:     500m
      memory:  512Mi
    Requests:
      cpu:      100m
      memory:   256Mi
    Liveness:   http-get http://:80/ delay=30s timeout=5s period=10s #success=1 #failure=3
    Readiness:  http-get http://:80/ delay=5s timeout=3s period=5s #success=1 #failure=3
    Environment:
      OPENAI_API_KEY:      <set to the key 'openai-api-key' in secret 'my-ag-ui-app-secrets'>         Optional: false
      OPENAI_BASE_URL:     <set to the key 'openai-base-url' in secret 'my-ag-ui-app-secrets'>        Optional: false
      OPENAI_MODEL:        <set to the key 'openai-model' in secret 'my-ag-ui-app-secrets'>           Optional: false
      EMBEDDING_MODEL:     <set to the key 'embedding-model' in secret 'my-ag-ui-app-secrets'>        Optional: false
      LOGFIRE_TOKEN:       <set to the key 'logfire-token' in secret 'my-ag-ui-app-secrets'>          Optional: false
      LLM_MAX_TOKENS:      <set to the key 'llm-max-tokens' of config map 'my-ag-ui-app-config'>      Optional: false
      LLM_CONTEXT_WINDOW:  <set to the key 'llm-context-window' of config map 'my-ag-ui-app-config'>  Optional: false
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-t58v9 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-t58v9:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>
[2026-03-23 11:07:36] DEPLOYMENT ERROR [Code: 126]: Pod did not reach Running status after deployment restart
[2026-03-23 11:07:36] RECOVERY SUGGESTION: Check pod logs: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl logs -l app=my-ag-ui-app. Verify image was loaded correctly in VM.
[2026-03-23 11:07:36] ESSENTIAL DIAGNOSTIC INFO:
[2026-03-23 11:07:36] Current directory: /home/ncheaz/git/my-ag-ui-app
[2026-03-23 11:07:36] k8s directory exists: yes
[2026-03-23 11:07:36] POD STATUS DIAGNOSTICS:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-58584948f8-dq24z   0/1     ImagePullBackOff   0          89s
my-ag-ui-app-64568b4968-h85n8   1/1     Running            1          37h
[2026-03-23 11:07:36] Docker images in VM:
IMAGE                 ID             DISK USAGE   CONTENT SIZE   EXTRA
my-ag-ui-app:latest   9bb7f1915756        546MB          263MB        
[2026-03-23 11:07:37] Recovery: Check pod logs: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl logs -l app=my-ag-ui-app
[2026-03-23 11:07:37] Manual: Delete pod to recreate: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl delete pods -l app=my-ag-ui-app
