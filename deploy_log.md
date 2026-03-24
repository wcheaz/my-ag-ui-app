[2026-03-24 11:30:13] 🚀 START: Total deployment timing
[2026-03-24 11:30:13] Starting Kubernetes secrets setup...
[2026-03-24 11:30:13] k8s directory found: /home/ncheaz/git/my-ag-ui-app/k8s/
[2026-03-24 11:30:13] setup-secrets.sh script found: /home/ncheaz/git/my-ag-ui-app/k8s/setup-secrets.sh
[2026-03-24 11:30:13] Setting up environment variables for secrets creation...
[2026-03-24 11:30:13] Loading environment variables from .env file...
[2026-03-24 11:30:13] Set environment variable: OPENAI_API_KEY
[2026-03-24 11:30:13] Set environment variable: OPENAI_BASE_URL
[2026-03-24 11:30:13] Set environment variable: OPENAI_MODEL
[2026-03-24 11:30:13] Set environment variable: LLM_MAX_TOKENS
[2026-03-24 11:30:13] Set environment variable: LLM_CONTEXT_WINDOW
[2026-03-24 11:30:13] Set environment variable: EMBEDDING_MODEL
[2026-03-24 11:30:13] All required environment variables are set
[2026-03-24 11:30:13] Running secrets setup script...
[2026-03-24 11:30:13] Setting up Kubernetes secrets...
[2026-03-24 11:30:13] Generating Kubernetes secrets file...
[2026-03-24 11:30:13] Kubernetes secrets file generated: k8s/secrets.yaml
[2026-03-24 11:30:13] Kubernetes secrets setup completed successfully
[2026-03-24 11:30:13] Starting Kubernetes deployment phase...
[2026-03-24 11:30:13] Using VM_NAME: my-ag-ui-app-k8s for Kubernetes deployment
[2026-03-24 11:30:13] 🔶 START: DEPENDENCY_VALIDATION
[2026-03-24 11:30:13] 
[2026-03-24 11:30:13] ==================================================
[2026-03-24 11:30:13]   DEPENDENCY VALIDATION BEFORE DOCKER BUILD
[2026-03-24 11:30:13] ==================================================
[2026-03-24 11:30:13] 
[2026-03-24 11:30:13] Starting lock file validation...
[2026-03-24 11:30:13] Checking if package.json and package-lock.json are in sync...
[2026-03-24 11:30:15] ✅ SUCCESS: package.json and package-lock.json are synchronized
[2026-03-24 11:30:15]    Dependencies are ready for reproducible Docker builds.
[2026-03-24 11:30:15] 
[2026-03-24 11:30:15] ✅ Dependency validation passed - proceeding with Docker build
[2026-03-24 11:30:15] ==================================================
[2026-03-24 11:30:15] 
[2026-03-24 11:30:15] ✅ END: DEPENDENCY_VALIDATION (took 1.172149899s)
[2026-03-24 11:30:15] 🔶 START: DOCKER_IMAGE_BUILD
[2026-03-24 11:30:15] Starting Docker image build process...
[2026-03-24 11:30:15] Building Docker image 'localhost:32000/my-ag-ui-app:latest' using project Dockerfile...
[2026-03-24 11:30:15] Checking Docker daemon socket permissions...
[2026-03-24 11:30:15] Docker daemon socket permissions verified - user has access
[2026-03-24 11:30:15] Dockerfile found: /home/ncheaz/git/my-ag-ui-app/Dockerfile
[2026-03-24 11:30:15] Building Docker image 'localhost:32000/my-ag-ui-app:latest'...
[2026-03-24 11:30:15] Performing pre-flight check: Docker daemon accessibility before build...
[2026-03-24 11:30:15] ✅ Docker daemon is accessible for build operation
[2026-03-24 11:30:15] CHECKING DISK SPACE FOR: Docker image build
[2026-03-24 11:30:15] Minimum required: 5GB
[2026-03-24 11:30:15] Available disk space: 369.0GB at .
[2026-03-24 11:30:15] ✅ SUFFICIENT DISK SPACE FOR: Docker image build (364.0GB available above minimum)
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 4.73kB done
#1 DONE 0.1s

#2 [internal] load metadata for docker.io/library/node:20.12.0-alpine
#2 DONE 0.9s

#3 [internal] load .dockerignore
#3 transferring context:
#3 transferring context: 128B done
#3 DONE 0.2s

#4 [internal] load build context
#4 DONE 0.0s

#5 [builder 1/6] FROM docker.io/library/node:20.12.0-alpine@sha256:ef3f47741e161900ddd07addcaca7e76534a9205e4cd73b2ed091ba339004a75
#5 resolve docker.io/library/node:20.12.0-alpine@sha256:ef3f47741e161900ddd07addcaca7e76534a9205e4cd73b2ed091ba339004a75
#5 resolve docker.io/library/node:20.12.0-alpine@sha256:ef3f47741e161900ddd07addcaca7e76534a9205e4cd73b2ed091ba339004a75 0.2s done
#5 sha256:ef3f47741e161900ddd07addcaca7e76534a9205e4cd73b2ed091ba339004a75 1.43kB / 1.43kB done
#5 sha256:73753e08a8755a0838696135be60a5f1e33c6cf92a15bc4e71465f3d0fda6422 1.16kB / 1.16kB done
#5 sha256:09c27ad02af8a1416d21c72ed2428dcfc10d86e9ad0f7234c7d876fab740c7d6 7.14kB / 7.14kB done
#5 sha256:4abcf20661432fb2d719aaf90656f55c287f8ca915dc1c92ec14ff61e67fbaf8 0B / 3.41MB 0.1s
#5 sha256:4abcf20661432fb2d719aaf90656f55c287f8ca915dc1c92ec14ff61e67fbaf8 2.10MB / 3.41MB 0.3s
#5 sha256:e5682cd217711ef874f1e9e97a15da5cf88aee99e69f49d8024b90c10f70cffb 0B / 42.20MB 0.3s
#5 sha256:ed63b364a3a06c54b73ccb4609a8aadc9b00cc76757f40d27c5a08440a196d1e 0B / 2.34MB 0.3s
#5 ...

#4 [internal] load build context
#4 transferring context: 30.44MB 0.2s done
#4 DONE 0.7s

#5 [builder 1/6] FROM docker.io/library/node:20.12.0-alpine@sha256:ef3f47741e161900ddd07addcaca7e76534a9205e4cd73b2ed091ba339004a75
#5 extracting sha256:4abcf20661432fb2d719aaf90656f55c287f8ca915dc1c92ec14ff61e67fbaf8
#5 sha256:4abcf20661432fb2d719aaf90656f55c287f8ca915dc1c92ec14ff61e67fbaf8 3.41MB / 3.41MB 0.4s done
#5 sha256:e5682cd217711ef874f1e9e97a15da5cf88aee99e69f49d8024b90c10f70cffb 10.49MB / 42.20MB 0.6s
#5 sha256:ed63b364a3a06c54b73ccb4609a8aadc9b00cc76757f40d27c5a08440a196d1e 2.10MB / 2.34MB 0.5s
#5 extracting sha256:4abcf20661432fb2d719aaf90656f55c287f8ca915dc1c92ec14ff61e67fbaf8 0.1s done
#5 sha256:39c48b75308248db440b30f97a8241f0fe72f599e69b59aab20eee1db478c962 0B / 448B 0.6s
#5 sha256:e5682cd217711ef874f1e9e97a15da5cf88aee99e69f49d8024b90c10f70cffb 13.63MB / 42.20MB 0.7s
#5 sha256:ed63b364a3a06c54b73ccb4609a8aadc9b00cc76757f40d27c5a08440a196d1e 2.34MB / 2.34MB 0.6s done
#5 sha256:39c48b75308248db440b30f97a8241f0fe72f599e69b59aab20eee1db478c962 448B / 448B 0.7s done
#5 sha256:e5682cd217711ef874f1e9e97a15da5cf88aee99e69f49d8024b90c10f70cffb 20.97MB / 42.20MB 1.0s
#5 sha256:e5682cd217711ef874f1e9e97a15da5cf88aee99e69f49d8024b90c10f70cffb 25.17MB / 42.20MB 1.2s
#5 sha256:e5682cd217711ef874f1e9e97a15da5cf88aee99e69f49d8024b90c10f70cffb 36.70MB / 42.20MB 1.4s
#5 sha256:e5682cd217711ef874f1e9e97a15da5cf88aee99e69f49d8024b90c10f70cffb 42.20MB / 42.20MB 1.6s
#5 sha256:e5682cd217711ef874f1e9e97a15da5cf88aee99e69f49d8024b90c10f70cffb 42.20MB / 42.20MB 1.7s done
#5 extracting sha256:e5682cd217711ef874f1e9e97a15da5cf88aee99e69f49d8024b90c10f70cffb
#5 extracting sha256:e5682cd217711ef874f1e9e97a15da5cf88aee99e69f49d8024b90c10f70cffb 0.4s done
#5 extracting sha256:ed63b364a3a06c54b73ccb4609a8aadc9b00cc76757f40d27c5a08440a196d1e
#5 extracting sha256:ed63b364a3a06c54b73ccb4609a8aadc9b00cc76757f40d27c5a08440a196d1e 0.1s done
#5 extracting sha256:39c48b75308248db440b30f97a8241f0fe72f599e69b59aab20eee1db478c962
#5 extracting sha256:39c48b75308248db440b30f97a8241f0fe72f599e69b59aab20eee1db478c962 done
#5 DONE 3.8s

#6 [builder 2/6] WORKDIR /app
#6 DONE 1.2s

#7 [runner 3/6] RUN addgroup --system --gid 1001 nodejs &&     adduser --system --uid 1001 nextjs
#7 ...

#8 [builder 3/6] COPY package.json package-lock.json ./
#8 DONE 0.5s

#9 [builder 4/6] RUN echo "=== DEPENDENCY INSTALLATION ===" &&     echo "Starting npm ci (reproducible install)..." &&     if npm ci --ignore-scripts; then         echo "✅ SUCCESS: npm ci completed - using reproducible dependencies from lock file";     else         echo "⚠️  WARNING: npm ci failed - lock files are out of sync";         echo "🔄 FALLING BACK to npm install to continue build...";         echo "ℹ️  NOTE: This allows deployment but reduces build reproducibility";         echo "🔧 FIX: Run 'npm install' locally and commit updated package-lock.json";         npm install --ignore-scripts;         echo "✅ SUCCESS: npm install completed - build continuing with fallback dependencies";     fi &&     echo "=== DEPENDENCY INSTALLATION COMPLETED ===" &&     npm cache clean --force
#9 ...

#7 [runner 3/6] RUN addgroup --system --gid 1001 nodejs &&     adduser --system --uid 1001 nextjs
#7 DONE 0.9s

#9 [builder 4/6] RUN echo "=== DEPENDENCY INSTALLATION ===" &&     echo "Starting npm ci (reproducible install)..." &&     if npm ci --ignore-scripts; then         echo "✅ SUCCESS: npm ci completed - using reproducible dependencies from lock file";     else         echo "⚠️  WARNING: npm ci failed - lock files are out of sync";         echo "🔄 FALLING BACK to npm install to continue build...";         echo "ℹ️  NOTE: This allows deployment but reduces build reproducibility";         echo "🔧 FIX: Run 'npm install' locally and commit updated package-lock.json";         npm install --ignore-scripts;         echo "✅ SUCCESS: npm install completed - build continuing with fallback dependencies";     fi &&     echo "=== DEPENDENCY INSTALLATION COMPLETED ===" &&     npm cache clean --force
#9 0.505 === DEPENDENCY INSTALLATION ===
#9 0.505 Starting npm ci (reproducible install)...
#9 1.821 npm WARN ERESOLVE overriding peer dependency
#9 1.821 npm WARN While resolving: cmdk@0.2.1
#9 1.821 npm WARN Found: react@19.2.3
#9 1.821 npm WARN node_modules/react
#9 1.821 npm WARN   react@"^19.2.1" from the root project
#9 1.821 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.821 npm WARN 
#9 1.821 npm WARN Could not resolve dependency:
#9 1.821 npm WARN peer react@"^18.0.0" from cmdk@0.2.1
#9 1.821 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk
#9 1.822 npm WARN   cmdk@"^0.2.0" from @copilotkit/react-textarea@1.54.0
#9 1.822 npm WARN   node_modules/@copilotkit/react-textarea
#9 1.822 npm WARN 
#9 1.822 npm WARN Conflicting peer dependency: react@18.3.1
#9 1.822 npm WARN node_modules/react
#9 1.822 npm WARN   peer react@"^18.0.0" from cmdk@0.2.1
#9 1.822 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk
#9 1.822 npm WARN     cmdk@"^0.2.0" from @copilotkit/react-textarea@1.54.0
#9 1.822 npm WARN     node_modules/@copilotkit/react-textarea
#9 1.827 npm WARN ERESOLVE overriding peer dependency
#9 1.827 npm WARN While resolving: cmdk@0.2.1
#9 1.827 npm WARN Found: react-dom@19.2.3
#9 1.827 npm WARN node_modules/react-dom
#9 1.827 npm WARN   react-dom@"^19.2.1" from the root project
#9 1.827 npm WARN   34 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.827 npm WARN 
#9 1.827 npm WARN Could not resolve dependency:
#9 1.827 npm WARN peer react-dom@"^18.0.0" from cmdk@0.2.1
#9 1.827 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk
#9 1.827 npm WARN   cmdk@"^0.2.0" from @copilotkit/react-textarea@1.54.0
#9 1.827 npm WARN   node_modules/@copilotkit/react-textarea
#9 1.827 npm WARN 
#9 1.827 npm WARN Conflicting peer dependency: react-dom@18.3.1
#9 1.827 npm WARN node_modules/react-dom
#9 1.827 npm WARN   peer react-dom@"^18.0.0" from cmdk@0.2.1
#9 1.827 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk
#9 1.828 npm WARN     cmdk@"^0.2.0" from @copilotkit/react-textarea@1.54.0
#9 1.828 npm WARN     node_modules/@copilotkit/react-textarea
#9 1.851 npm WARN ERESOLVE overriding peer dependency
#9 1.851 npm WARN While resolving: lucide-react@0.274.0
#9 1.851 npm WARN Found: react@19.2.3
#9 1.851 npm WARN node_modules/react
#9 1.851 npm WARN   react@"^19.2.1" from the root project
#9 1.851 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.851 npm WARN 
#9 1.851 npm WARN Could not resolve dependency:
#9 1.851 npm WARN peer react@"^16.5.1 || ^17.0.0 || ^18.0.0" from lucide-react@0.274.0
#9 1.851 npm WARN node_modules/@copilotkit/react-textarea/node_modules/lucide-react
#9 1.851 npm WARN   lucide-react@"^0.274.0" from @copilotkit/react-textarea@1.54.0
#9 1.851 npm WARN   node_modules/@copilotkit/react-textarea
#9 1.851 npm WARN 
#9 1.851 npm WARN Conflicting peer dependency: react@18.3.1
#9 1.851 npm WARN node_modules/react
#9 1.851 npm WARN   peer react@"^16.5.1 || ^17.0.0 || ^18.0.0" from lucide-react@0.274.0
#9 1.851 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/lucide-react
#9 1.851 npm WARN     lucide-react@"^0.274.0" from @copilotkit/react-textarea@1.54.0
#9 1.851 npm WARN     node_modules/@copilotkit/react-textarea
#9 1.879 npm WARN ERESOLVE overriding peer dependency
#9 1.879 npm WARN While resolving: @radix-ui/react-dialog@1.0.0
#9 1.879 npm WARN Found: react@19.2.3
#9 1.879 npm WARN node_modules/react
#9 1.879 npm WARN   react@"^19.2.1" from the root project
#9 1.879 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.879 npm WARN 
#9 1.879 npm WARN Could not resolve dependency:
#9 1.879 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-dialog@1.0.0
#9 1.879 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.879 npm WARN   @radix-ui/react-dialog@"1.0.0" from cmdk@0.2.1
#9 1.879 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk
#9 1.879 npm WARN 
#9 1.879 npm WARN Conflicting peer dependency: react@18.3.1
#9 1.879 npm WARN node_modules/react
#9 1.879 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-dialog@1.0.0
#9 1.879 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.879 npm WARN     @radix-ui/react-dialog@"1.0.0" from cmdk@0.2.1
#9 1.879 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk
#9 1.884 npm WARN ERESOLVE overriding peer dependency
#9 1.884 npm WARN While resolving: @radix-ui/react-dialog@1.0.0
#9 1.884 npm WARN Found: react-dom@19.2.3
#9 1.884 npm WARN node_modules/react-dom
#9 1.884 npm WARN   react-dom@"^19.2.1" from the root project
#9 1.884 npm WARN   34 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.884 npm WARN 
#9 1.884 npm WARN Could not resolve dependency:
#9 1.884 npm WARN peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-dialog@1.0.0
#9 1.885 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.885 npm WARN   @radix-ui/react-dialog@"1.0.0" from cmdk@0.2.1
#9 1.885 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk
#9 1.885 npm WARN 
#9 1.885 npm WARN Conflicting peer dependency: react-dom@18.3.1
#9 1.885 npm WARN node_modules/react-dom
#9 1.885 npm WARN   peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-dialog@1.0.0
#9 1.885 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.885 npm WARN     @radix-ui/react-dialog@"1.0.0" from cmdk@0.2.1
#9 1.885 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk
#9 1.894 npm WARN ERESOLVE overriding peer dependency
#9 1.894 npm WARN While resolving: @radix-ui/react-compose-refs@1.0.0
#9 1.894 npm WARN Found: react@19.2.3
#9 1.894 npm WARN node_modules/react
#9 1.894 npm WARN   react@"^19.2.1" from the root project
#9 1.894 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.894 npm WARN 
#9 1.894 npm WARN Could not resolve dependency:
#9 1.894 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-compose-refs@1.0.0
#9 1.894 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-compose-refs
#9 1.894 npm WARN   @radix-ui/react-compose-refs@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.894 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.894 npm WARN   4 more (@radix-ui/react-dismissable-layer, ...)
#9 1.894 npm WARN 
#9 1.894 npm WARN Conflicting peer dependency: react@18.3.1
#9 1.894 npm WARN node_modules/react
#9 1.894 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-compose-refs@1.0.0
#9 1.894 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-compose-refs
#9 1.894 npm WARN     @radix-ui/react-compose-refs@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.894 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.894 npm WARN     4 more (@radix-ui/react-dismissable-layer, ...)
#9 1.902 npm WARN ERESOLVE overriding peer dependency
#9 1.902 npm WARN While resolving: @radix-ui/react-context@1.0.0
#9 1.903 npm WARN Found: react@19.2.3
#9 1.903 npm WARN node_modules/react
#9 1.903 npm WARN   react@"^19.2.1" from the root project
#9 1.903 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.903 npm WARN 
#9 1.903 npm WARN Could not resolve dependency:
#9 1.903 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-context@1.0.0
#9 1.903 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-context
#9 1.903 npm WARN   @radix-ui/react-context@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.903 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.903 npm WARN 
#9 1.903 npm WARN Conflicting peer dependency: react@18.3.1
#9 1.903 npm WARN node_modules/react
#9 1.903 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-context@1.0.0
#9 1.903 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-context
#9 1.903 npm WARN     @radix-ui/react-context@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.903 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.913 npm WARN ERESOLVE overriding peer dependency
#9 1.913 npm WARN While resolving: @radix-ui/react-dismissable-layer@1.0.0
#9 1.913 npm WARN Found: react@19.2.3
#9 1.913 npm WARN node_modules/react
#9 1.913 npm WARN   react@"^19.2.1" from the root project
#9 1.913 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.913 npm WARN 
#9 1.913 npm WARN Could not resolve dependency:
#9 1.913 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-dismissable-layer@1.0.0
#9 1.913 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer
#9 1.913 npm WARN   @radix-ui/react-dismissable-layer@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.913 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.913 npm WARN 
#9 1.913 npm WARN Conflicting peer dependency: react@18.3.1
#9 1.913 npm WARN node_modules/react
#9 1.913 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-dismissable-layer@1.0.0
#9 1.913 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer
#9 1.913 npm WARN     @radix-ui/react-dismissable-layer@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.913 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.917 npm WARN ERESOLVE overriding peer dependency
#9 1.917 npm WARN While resolving: @radix-ui/react-dismissable-layer@1.0.0
#9 1.917 npm WARN Found: react-dom@19.2.3
#9 1.917 npm WARN node_modules/react-dom
#9 1.917 npm WARN   react-dom@"^19.2.1" from the root project
#9 1.917 npm WARN   34 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.917 npm WARN 
#9 1.917 npm WARN Could not resolve dependency:
#9 1.917 npm WARN peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-dismissable-layer@1.0.0
#9 1.917 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer
#9 1.917 npm WARN   @radix-ui/react-dismissable-layer@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.917 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.917 npm WARN 
#9 1.918 npm WARN Conflicting peer dependency: react-dom@18.3.1
#9 1.918 npm WARN node_modules/react-dom
#9 1.918 npm WARN   peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-dismissable-layer@1.0.0
#9 1.918 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer
#9 1.918 npm WARN     @radix-ui/react-dismissable-layer@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.918 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.926 npm WARN ERESOLVE overriding peer dependency
#9 1.926 npm WARN While resolving: @radix-ui/react-focus-guards@1.0.0
#9 1.926 npm WARN Found: react@19.2.3
#9 1.926 npm WARN node_modules/react
#9 1.926 npm WARN   react@"^19.2.1" from the root project
#9 1.926 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.926 npm WARN 
#9 1.926 npm WARN Could not resolve dependency:
#9 1.926 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-focus-guards@1.0.0
#9 1.926 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-guards
#9 1.926 npm WARN   @radix-ui/react-focus-guards@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.926 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.926 npm WARN 
#9 1.926 npm WARN Conflicting peer dependency: react@18.3.1
#9 1.926 npm WARN node_modules/react
#9 1.926 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-focus-guards@1.0.0
#9 1.926 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-guards
#9 1.926 npm WARN     @radix-ui/react-focus-guards@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.926 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.934 npm WARN ERESOLVE overriding peer dependency
#9 1.934 npm WARN While resolving: @radix-ui/react-focus-scope@1.0.0
#9 1.934 npm WARN Found: react@19.2.3
#9 1.934 npm WARN node_modules/react
#9 1.935 npm WARN   react@"^19.2.1" from the root project
#9 1.935 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.935 npm WARN 
#9 1.935 npm WARN Could not resolve dependency:
#9 1.935 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-focus-scope@1.0.0
#9 1.935 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-scope
#9 1.935 npm WARN   @radix-ui/react-focus-scope@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.935 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.935 npm WARN 
#9 1.935 npm WARN Conflicting peer dependency: react@18.3.1
#9 1.935 npm WARN node_modules/react
#9 1.935 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-focus-scope@1.0.0
#9 1.935 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-scope
#9 1.935 npm WARN     @radix-ui/react-focus-scope@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.935 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.939 npm WARN ERESOLVE overriding peer dependency
#9 1.939 npm WARN While resolving: @radix-ui/react-focus-scope@1.0.0
#9 1.939 npm WARN Found: react-dom@19.2.3
#9 1.939 npm WARN node_modules/react-dom
#9 1.939 npm WARN   react-dom@"^19.2.1" from the root project
#9 1.939 npm WARN   34 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.939 npm WARN 
#9 1.939 npm WARN Could not resolve dependency:
#9 1.939 npm WARN peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-focus-scope@1.0.0
#9 1.939 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-scope
#9 1.939 npm WARN   @radix-ui/react-focus-scope@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.939 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.939 npm WARN 
#9 1.939 npm WARN Conflicting peer dependency: react-dom@18.3.1
#9 1.939 npm WARN node_modules/react-dom
#9 1.939 npm WARN   peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-focus-scope@1.0.0
#9 1.939 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-scope
#9 1.939 npm WARN     @radix-ui/react-focus-scope@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.939 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.947 npm WARN ERESOLVE overriding peer dependency
#9 1.947 npm WARN While resolving: @radix-ui/react-id@1.0.0
#9 1.947 npm WARN Found: react@19.2.3
#9 1.947 npm WARN node_modules/react
#9 1.947 npm WARN   react@"^19.2.1" from the root project
#9 1.947 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.947 npm WARN 
#9 1.947 npm WARN Could not resolve dependency:
#9 1.947 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-id@1.0.0
#9 1.947 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-id
#9 1.947 npm WARN   @radix-ui/react-id@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.947 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.947 npm WARN 
#9 1.947 npm WARN Conflicting peer dependency: react@18.3.1
#9 1.947 npm WARN node_modules/react
#9 1.947 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-id@1.0.0
#9 1.947 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-id
#9 1.947 npm WARN     @radix-ui/react-id@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.947 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.955 npm WARN ERESOLVE overriding peer dependency
#9 1.955 npm WARN While resolving: @radix-ui/react-portal@1.0.0
#9 1.955 npm WARN Found: react@19.2.3
#9 1.955 npm WARN node_modules/react
#9 1.955 npm WARN   react@"^19.2.1" from the root project
#9 1.955 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.955 npm WARN 
#9 1.955 npm WARN Could not resolve dependency:
#9 1.955 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-portal@1.0.0
#9 1.955 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-portal
#9 1.955 npm WARN   @radix-ui/react-portal@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.955 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.955 npm WARN 
#9 1.955 npm WARN Conflicting peer dependency: react@18.3.1
#9 1.955 npm WARN node_modules/react
#9 1.955 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-portal@1.0.0
#9 1.955 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-portal
#9 1.955 npm WARN     @radix-ui/react-portal@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.955 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.959 npm WARN ERESOLVE overriding peer dependency
#9 1.959 npm WARN While resolving: @radix-ui/react-portal@1.0.0
#9 1.959 npm WARN Found: react-dom@19.2.3
#9 1.959 npm WARN node_modules/react-dom
#9 1.959 npm WARN   react-dom@"^19.2.1" from the root project
#9 1.959 npm WARN   34 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.959 npm WARN 
#9 1.959 npm WARN Could not resolve dependency:
#9 1.959 npm WARN peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-portal@1.0.0
#9 1.959 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-portal
#9 1.959 npm WARN   @radix-ui/react-portal@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.959 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.959 npm WARN 
#9 1.959 npm WARN Conflicting peer dependency: react-dom@18.3.1
#9 1.959 npm WARN node_modules/react-dom
#9 1.960 npm WARN   peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-portal@1.0.0
#9 1.960 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-portal
#9 1.960 npm WARN     @radix-ui/react-portal@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.960 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.968 npm WARN ERESOLVE overriding peer dependency
#9 1.968 npm WARN While resolving: @radix-ui/react-presence@1.0.0
#9 1.968 npm WARN Found: react@19.2.3
#9 1.968 npm WARN node_modules/react
#9 1.968 npm WARN   react@"^19.2.1" from the root project
#9 1.968 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.968 npm WARN 
#9 1.968 npm WARN Could not resolve dependency:
#9 1.968 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-presence@1.0.0
#9 1.968 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-presence
#9 1.968 npm WARN   @radix-ui/react-presence@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.968 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.968 npm WARN 
#9 1.968 npm WARN Conflicting peer dependency: react@18.3.1
#9 1.968 npm WARN node_modules/react
#9 1.968 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-presence@1.0.0
#9 1.968 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-presence
#9 1.968 npm WARN     @radix-ui/react-presence@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.968 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.973 npm WARN ERESOLVE overriding peer dependency
#9 1.973 npm WARN While resolving: @radix-ui/react-presence@1.0.0
#9 1.973 npm WARN Found: react-dom@19.2.3
#9 1.973 npm WARN node_modules/react-dom
#9 1.973 npm WARN   react-dom@"^19.2.1" from the root project
#9 1.973 npm WARN   34 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.973 npm WARN 
#9 1.973 npm WARN Could not resolve dependency:
#9 1.973 npm WARN peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-presence@1.0.0
#9 1.973 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-presence
#9 1.973 npm WARN   @radix-ui/react-presence@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.973 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.973 npm WARN 
#9 1.973 npm WARN Conflicting peer dependency: react-dom@18.3.1
#9 1.973 npm WARN node_modules/react-dom
#9 1.973 npm WARN   peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-presence@1.0.0
#9 1.973 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-presence
#9 1.973 npm WARN     @radix-ui/react-presence@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.973 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.981 npm WARN ERESOLVE overriding peer dependency
#9 1.981 npm WARN While resolving: @radix-ui/react-primitive@1.0.0
#9 1.981 npm WARN Found: react@19.2.3
#9 1.981 npm WARN node_modules/react
#9 1.981 npm WARN   react@"^19.2.1" from the root project
#9 1.981 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.981 npm WARN 
#9 1.981 npm WARN Could not resolve dependency:
#9 1.981 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-primitive@1.0.0
#9 1.981 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-primitive
#9 1.981 npm WARN   @radix-ui/react-primitive@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.981 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.981 npm WARN   3 more (@radix-ui/react-dismissable-layer, ...)
#9 1.981 npm WARN 
#9 1.981 npm WARN Conflicting peer dependency: react@18.3.1
#9 1.981 npm WARN node_modules/react
#9 1.981 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-primitive@1.0.0
#9 1.981 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-primitive
#9 1.981 npm WARN     @radix-ui/react-primitive@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.981 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.981 npm WARN     3 more (@radix-ui/react-dismissable-layer, ...)
#9 1.986 npm WARN ERESOLVE overriding peer dependency
#9 1.986 npm WARN While resolving: @radix-ui/react-primitive@1.0.0
#9 1.986 npm WARN Found: react-dom@19.2.3
#9 1.986 npm WARN node_modules/react-dom
#9 1.986 npm WARN   react-dom@"^19.2.1" from the root project
#9 1.986 npm WARN   34 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.986 npm WARN 
#9 1.986 npm WARN Could not resolve dependency:
#9 1.986 npm WARN peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-primitive@1.0.0
#9 1.986 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-primitive
#9 1.986 npm WARN   @radix-ui/react-primitive@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.986 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.986 npm WARN   3 more (@radix-ui/react-dismissable-layer, ...)
#9 1.986 npm WARN 
#9 1.987 npm WARN Conflicting peer dependency: react-dom@18.3.1
#9 1.987 npm WARN node_modules/react-dom
#9 1.987 npm WARN   peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-primitive@1.0.0
#9 1.987 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-primitive
#9 1.987 npm WARN     @radix-ui/react-primitive@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.987 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.987 npm WARN     3 more (@radix-ui/react-dismissable-layer, ...)
#9 1.995 npm WARN ERESOLVE overriding peer dependency
#9 1.995 npm WARN While resolving: @radix-ui/react-slot@1.0.0
#9 1.995 npm WARN Found: react@19.2.3
#9 1.995 npm WARN node_modules/react
#9 1.995 npm WARN   react@"^19.2.1" from the root project
#9 1.995 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 1.995 npm WARN 
#9 1.995 npm WARN Could not resolve dependency:
#9 1.996 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-slot@1.0.0
#9 1.996 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-slot
#9 1.996 npm WARN   @radix-ui/react-slot@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.996 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.996 npm WARN   1 more (@radix-ui/react-primitive)
#9 1.996 npm WARN 
#9 1.996 npm WARN Conflicting peer dependency: react@18.3.1
#9 1.996 npm WARN node_modules/react
#9 1.996 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-slot@1.0.0
#9 1.996 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-slot
#9 1.996 npm WARN     @radix-ui/react-slot@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 1.996 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 1.996 npm WARN     1 more (@radix-ui/react-primitive)
#9 2.005 npm WARN ERESOLVE overriding peer dependency
#9 2.005 npm WARN While resolving: @radix-ui/react-use-controllable-state@1.0.0
#9 2.005 npm WARN Found: react@19.2.3
#9 2.005 npm WARN node_modules/react
#9 2.005 npm WARN   react@"^19.2.1" from the root project
#9 2.005 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 2.005 npm WARN 
#9 2.005 npm WARN Could not resolve dependency:
#9 2.005 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-controllable-state@1.0.0
#9 2.005 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-use-controllable-state
#9 2.005 npm WARN   @radix-ui/react-use-controllable-state@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 2.005 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 2.005 npm WARN 
#9 2.005 npm WARN Conflicting peer dependency: react@18.3.1
#9 2.005 npm WARN node_modules/react
#9 2.005 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-controllable-state@1.0.0
#9 2.005 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-use-controllable-state
#9 2.005 npm WARN     @radix-ui/react-use-controllable-state@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 2.005 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 2.170 npm WARN ERESOLVE overriding peer dependency
#9 2.170 npm WARN While resolving: react-remove-scroll@2.5.4
#9 2.170 npm WARN Found: react@19.2.3
#9 2.171 npm WARN node_modules/react
#9 2.171 npm WARN   react@"^19.2.1" from the root project
#9 2.171 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 2.171 npm WARN 
#9 2.171 npm WARN Could not resolve dependency:
#9 2.171 npm WARN peer react@"^16.8.0 || ^17.0.0 || ^18.0.0" from react-remove-scroll@2.5.4
#9 2.171 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/react-remove-scroll
#9 2.171 npm WARN   react-remove-scroll@"2.5.4" from @radix-ui/react-dialog@1.0.0
#9 2.171 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 2.171 npm WARN 
#9 2.171 npm WARN Conflicting peer dependency: react@18.3.1
#9 2.171 npm WARN node_modules/react
#9 2.171 npm WARN   peer react@"^16.8.0 || ^17.0.0 || ^18.0.0" from react-remove-scroll@2.5.4
#9 2.171 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/react-remove-scroll
#9 2.171 npm WARN     react-remove-scroll@"2.5.4" from @radix-ui/react-dialog@1.0.0
#9 2.171 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 2.182 npm WARN ERESOLVE overriding peer dependency
#9 2.182 npm WARN While resolving: @radix-ui/react-use-callback-ref@1.0.0
#9 2.182 npm WARN Found: react@19.2.3
#9 2.182 npm WARN node_modules/react
#9 2.182 npm WARN   react@"^19.2.1" from the root project
#9 2.182 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 2.182 npm WARN 
#9 2.182 npm WARN Could not resolve dependency:
#9 2.182 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-callback-ref@1.0.0
#9 2.182 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer/node_modules/@radix-ui/react-use-callback-ref
#9 2.182 npm WARN   @radix-ui/react-use-callback-ref@"1.0.0" from @radix-ui/react-dismissable-layer@1.0.0
#9 2.182 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer
#9 2.182 npm WARN   1 more (@radix-ui/react-use-escape-keydown)
#9 2.182 npm WARN 
#9 2.182 npm WARN Conflicting peer dependency: react@18.3.1
#9 2.182 npm WARN node_modules/react
#9 2.182 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-callback-ref@1.0.0
#9 2.182 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer/node_modules/@radix-ui/react-use-callback-ref
#9 2.182 npm WARN     @radix-ui/react-use-callback-ref@"1.0.0" from @radix-ui/react-dismissable-layer@1.0.0
#9 2.182 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer
#9 2.182 npm WARN     1 more (@radix-ui/react-use-escape-keydown)
#9 2.191 npm WARN ERESOLVE overriding peer dependency
#9 2.191 npm WARN While resolving: @radix-ui/react-use-escape-keydown@1.0.0
#9 2.191 npm WARN Found: react@19.2.3
#9 2.191 npm WARN node_modules/react
#9 2.191 npm WARN   react@"^19.2.1" from the root project
#9 2.191 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 2.191 npm WARN 
#9 2.191 npm WARN Could not resolve dependency:
#9 2.191 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-escape-keydown@1.0.0
#9 2.191 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer/node_modules/@radix-ui/react-use-escape-keydown
#9 2.191 npm WARN   @radix-ui/react-use-escape-keydown@"1.0.0" from @radix-ui/react-dismissable-layer@1.0.0
#9 2.191 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer
#9 2.191 npm WARN 
#9 2.191 npm WARN Conflicting peer dependency: react@18.3.1
#9 2.191 npm WARN node_modules/react
#9 2.191 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-escape-keydown@1.0.0
#9 2.191 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer/node_modules/@radix-ui/react-use-escape-keydown
#9 2.191 npm WARN     @radix-ui/react-use-escape-keydown@"1.0.0" from @radix-ui/react-dismissable-layer@1.0.0
#9 2.191 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer
#9 2.201 npm WARN ERESOLVE overriding peer dependency
#9 2.201 npm WARN While resolving: @radix-ui/react-use-callback-ref@1.0.0
#9 2.201 npm WARN Found: react@19.2.3
#9 2.201 npm WARN node_modules/react
#9 2.201 npm WARN   react@"^19.2.1" from the root project
#9 2.201 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 2.201 npm WARN 
#9 2.201 npm WARN Could not resolve dependency:
#9 2.201 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-callback-ref@1.0.0
#9 2.201 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-scope/node_modules/@radix-ui/react-use-callback-ref
#9 2.201 npm WARN   @radix-ui/react-use-callback-ref@"1.0.0" from @radix-ui/react-focus-scope@1.0.0
#9 2.201 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-scope
#9 2.201 npm WARN 
#9 2.201 npm WARN Conflicting peer dependency: react@18.3.1
#9 2.201 npm WARN node_modules/react
#9 2.201 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-callback-ref@1.0.0
#9 2.201 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-scope/node_modules/@radix-ui/react-use-callback-ref
#9 2.201 npm WARN     @radix-ui/react-use-callback-ref@"1.0.0" from @radix-ui/react-focus-scope@1.0.0
#9 2.201 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-scope
#9 2.210 npm WARN ERESOLVE overriding peer dependency
#9 2.210 npm WARN While resolving: @radix-ui/react-use-layout-effect@1.0.0
#9 2.210 npm WARN Found: react@19.2.3
#9 2.210 npm WARN node_modules/react
#9 2.210 npm WARN   react@"^19.2.1" from the root project
#9 2.210 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 2.210 npm WARN 
#9 2.210 npm WARN Could not resolve dependency:
#9 2.210 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-layout-effect@1.0.0
#9 2.210 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-id/node_modules/@radix-ui/react-use-layout-effect
#9 2.210 npm WARN   @radix-ui/react-use-layout-effect@"1.0.0" from @radix-ui/react-id@1.0.0
#9 2.210 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-id
#9 2.210 npm WARN 
#9 2.210 npm WARN Conflicting peer dependency: react@18.3.1
#9 2.210 npm WARN node_modules/react
#9 2.210 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-layout-effect@1.0.0
#9 2.210 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-id/node_modules/@radix-ui/react-use-layout-effect
#9 2.210 npm WARN     @radix-ui/react-use-layout-effect@"1.0.0" from @radix-ui/react-id@1.0.0
#9 2.210 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-id
#9 2.219 npm WARN ERESOLVE overriding peer dependency
#9 2.219 npm WARN While resolving: @radix-ui/react-use-layout-effect@1.0.0
#9 2.219 npm WARN Found: react@19.2.3
#9 2.219 npm WARN node_modules/react
#9 2.219 npm WARN   react@"^19.2.1" from the root project
#9 2.219 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 2.219 npm WARN 
#9 2.219 npm WARN Could not resolve dependency:
#9 2.219 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-layout-effect@1.0.0
#9 2.219 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-presence/node_modules/@radix-ui/react-use-layout-effect
#9 2.219 npm WARN   @radix-ui/react-use-layout-effect@"1.0.0" from @radix-ui/react-presence@1.0.0
#9 2.219 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-presence
#9 2.219 npm WARN 
#9 2.219 npm WARN Conflicting peer dependency: react@18.3.1
#9 2.219 npm WARN node_modules/react
#9 2.219 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-layout-effect@1.0.0
#9 2.219 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-presence/node_modules/@radix-ui/react-use-layout-effect
#9 2.219 npm WARN     @radix-ui/react-use-layout-effect@"1.0.0" from @radix-ui/react-presence@1.0.0
#9 2.219 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-presence
#9 2.232 npm WARN ERESOLVE overriding peer dependency
#9 2.232 npm WARN While resolving: @radix-ui/react-use-callback-ref@1.0.0
#9 2.232 npm WARN Found: react@19.2.3
#9 2.232 npm WARN node_modules/react
#9 2.232 npm WARN   react@"^19.2.1" from the root project
#9 2.232 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 2.232 npm WARN 
#9 2.232 npm WARN Could not resolve dependency:
#9 2.232 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-callback-ref@1.0.0
#9 2.232 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-use-controllable-state/node_modules/@radix-ui/react-use-callback-ref
#9 2.232 npm WARN   @radix-ui/react-use-callback-ref@"1.0.0" from @radix-ui/react-use-controllable-state@1.0.0
#9 2.232 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-use-controllable-state
#9 2.232 npm WARN 
#9 2.232 npm WARN Conflicting peer dependency: react@18.3.1
#9 2.232 npm WARN node_modules/react
#9 2.232 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-callback-ref@1.0.0
#9 2.232 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-use-controllable-state/node_modules/@radix-ui/react-use-callback-ref
#9 2.232 npm WARN     @radix-ui/react-use-callback-ref@"1.0.0" from @radix-ui/react-use-controllable-state@1.0.0
#9 2.232 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-use-controllable-state
#9 2.240 npm WARN EBADENGINE Unsupported engine {
#9 2.240 npm WARN EBADENGINE   package: 'eslint-visitor-keys@5.0.1',
#9 2.240 npm WARN EBADENGINE   required: { node: '^20.19.0 || ^22.13.0 || >=24' },
#9 2.240 npm WARN EBADENGINE   current: { node: 'v20.12.0', npm: '10.5.0' }
#9 2.241 npm WARN EBADENGINE }
#9 2.243 npm notice 
#9 2.243 npm notice New major version of npm available! 10.5.0 -> 11.12.0
#9 2.243 npm notice Changelog: <https://github.com/npm/cli/releases/tag/v11.12.0>
#9 2.243 npm notice Run `npm install -g npm@11.12.0` to update!
#9 2.243 npm notice 
#9 2.243 npm ERR! code EUSAGE
#9 2.244 npm ERR! 
#9 2.244 npm ERR! `npm ci` can only install packages when your package.json and package-lock.json or npm-shrinkwrap.json are in sync. Please update your lock file with `npm install` before continuing.
#9 2.244 npm ERR! 
#9 2.244 npm ERR! Missing: @types/react@18.3.28 from lock file
#9 2.244 npm ERR! 
#9 2.244 npm ERR! Clean install a project
#9 2.244 npm ERR! 
#9 2.244 npm ERR! Usage:
#9 2.244 npm ERR! npm ci
#9 2.244 npm ERR! 
#9 2.244 npm ERR! Options:
#9 2.244 npm ERR! [--install-strategy <hoisted|nested|shallow|linked>] [--legacy-bundling]
#9 2.244 npm ERR! [--global-style] [--omit <dev|optional|peer> [--omit <dev|optional|peer> ...]]
#9 2.244 npm ERR! [--include <prod|dev|optional|peer> [--include <prod|dev|optional|peer> ...]]
#9 2.244 npm ERR! [--strict-peer-deps] [--foreground-scripts] [--ignore-scripts] [--no-audit]
#9 2.244 npm ERR! [--no-bin-links] [--no-fund] [--dry-run]
#9 2.244 npm ERR! [-w|--workspace <workspace-name> [-w|--workspace <workspace-name> ...]]
#9 2.244 npm ERR! [-ws|--workspaces] [--include-workspace-root] [--install-links]
#9 2.244 npm ERR! 
#9 2.244 npm ERR! aliases: clean-install, ic, install-clean, isntall-clean
#9 2.244 npm ERR! 
#9 2.244 npm ERR! Run "npm help ci" for more info
#9 2.245 
#9 2.245 npm ERR! A complete log of this run can be found in: /root/.npm/_logs/2026-03-24T15_30_22_816Z-debug-0.log
#9 2.259 ⚠️  WARNING: npm ci failed - lock files are out of sync
#9 2.259 🔄 FALLING BACK to npm install to continue build...
#9 2.259 ℹ️  NOTE: This allows deployment but reduces build reproducibility
#9 2.259 🔧 FIX: Run 'npm install' locally and commit updated package-lock.json
#9 2.903 npm WARN ERESOLVE overriding peer dependency
#9 2.903 npm WARN While resolving: cmdk@0.2.1
#9 2.903 npm WARN Found: react@19.2.3
#9 2.904 npm WARN node_modules/react
#9 2.904 npm WARN   react@"^19.2.1" from the root project
#9 2.904 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 2.904 npm WARN 
#9 2.904 npm WARN Could not resolve dependency:
#9 2.904 npm WARN peer react@"^18.0.0" from cmdk@0.2.1
#9 2.904 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk
#9 2.904 npm WARN   cmdk@"^0.2.0" from @copilotkit/react-textarea@1.54.0
#9 2.904 npm WARN   node_modules/@copilotkit/react-textarea
#9 2.904 npm WARN 
#9 2.904 npm WARN Conflicting peer dependency: react@18.3.1
#9 2.904 npm WARN node_modules/react
#9 2.904 npm WARN   peer react@"^18.0.0" from cmdk@0.2.1
#9 2.904 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk
#9 2.904 npm WARN     cmdk@"^0.2.0" from @copilotkit/react-textarea@1.54.0
#9 2.904 npm WARN     node_modules/@copilotkit/react-textarea
#9 2.912 npm WARN ERESOLVE overriding peer dependency
#9 2.912 npm WARN While resolving: cmdk@0.2.1
#9 2.912 npm WARN Found: react-dom@19.2.3
#9 2.912 npm WARN node_modules/react-dom
#9 2.912 npm WARN   react-dom@"^19.2.1" from the root project
#9 2.912 npm WARN   34 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 2.912 npm WARN 
#9 2.912 npm WARN Could not resolve dependency:
#9 2.912 npm WARN peer react-dom@"^18.0.0" from cmdk@0.2.1
#9 2.912 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk
#9 2.912 npm WARN   cmdk@"^0.2.0" from @copilotkit/react-textarea@1.54.0
#9 2.912 npm WARN   node_modules/@copilotkit/react-textarea
#9 2.912 npm WARN 
#9 2.912 npm WARN Conflicting peer dependency: react-dom@18.3.1
#9 2.912 npm WARN node_modules/react-dom
#9 2.912 npm WARN   peer react-dom@"^18.0.0" from cmdk@0.2.1
#9 2.912 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk
#9 2.912 npm WARN     cmdk@"^0.2.0" from @copilotkit/react-textarea@1.54.0
#9 2.912 npm WARN     node_modules/@copilotkit/react-textarea
#9 2.935 npm WARN ERESOLVE overriding peer dependency
#9 2.935 npm WARN While resolving: lucide-react@0.274.0
#9 2.935 npm WARN Found: react@19.2.3
#9 2.935 npm WARN node_modules/react
#9 2.935 npm WARN   react@"^19.2.1" from the root project
#9 2.935 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 2.935 npm WARN 
#9 2.935 npm WARN Could not resolve dependency:
#9 2.935 npm WARN peer react@"^16.5.1 || ^17.0.0 || ^18.0.0" from lucide-react@0.274.0
#9 2.935 npm WARN node_modules/@copilotkit/react-textarea/node_modules/lucide-react
#9 2.935 npm WARN   lucide-react@"^0.274.0" from @copilotkit/react-textarea@1.54.0
#9 2.935 npm WARN   node_modules/@copilotkit/react-textarea
#9 2.935 npm WARN 
#9 2.935 npm WARN Conflicting peer dependency: react@18.3.1
#9 2.935 npm WARN node_modules/react
#9 2.935 npm WARN   peer react@"^16.5.1 || ^17.0.0 || ^18.0.0" from lucide-react@0.274.0
#9 2.935 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/lucide-react
#9 2.935 npm WARN     lucide-react@"^0.274.0" from @copilotkit/react-textarea@1.54.0
#9 2.935 npm WARN     node_modules/@copilotkit/react-textarea
#9 2.962 npm WARN ERESOLVE overriding peer dependency
#9 2.962 npm WARN While resolving: @radix-ui/react-dialog@1.0.0
#9 2.962 npm WARN Found: react@19.2.3
#9 2.962 npm WARN node_modules/react
#9 2.962 npm WARN   react@"^19.2.1" from the root project
#9 2.962 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 2.962 npm WARN 
#9 2.962 npm WARN Could not resolve dependency:
#9 2.962 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-dialog@1.0.0
#9 2.962 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 2.962 npm WARN   @radix-ui/react-dialog@"1.0.0" from cmdk@0.2.1
#9 2.962 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk
#9 2.962 npm WARN 
#9 2.962 npm WARN Conflicting peer dependency: react@18.3.1
#9 2.962 npm WARN node_modules/react
#9 2.962 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-dialog@1.0.0
#9 2.963 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 2.963 npm WARN     @radix-ui/react-dialog@"1.0.0" from cmdk@0.2.1
#9 2.963 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk
#9 2.968 npm WARN ERESOLVE overriding peer dependency
#9 2.968 npm WARN While resolving: @radix-ui/react-dialog@1.0.0
#9 2.968 npm WARN Found: react-dom@19.2.3
#9 2.968 npm WARN node_modules/react-dom
#9 2.968 npm WARN   react-dom@"^19.2.1" from the root project
#9 2.968 npm WARN   34 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 2.968 npm WARN 
#9 2.968 npm WARN Could not resolve dependency:
#9 2.968 npm WARN peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-dialog@1.0.0
#9 2.968 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 2.968 npm WARN   @radix-ui/react-dialog@"1.0.0" from cmdk@0.2.1
#9 2.968 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk
#9 2.968 npm WARN 
#9 2.968 npm WARN Conflicting peer dependency: react-dom@18.3.1
#9 2.968 npm WARN node_modules/react-dom
#9 2.968 npm WARN   peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-dialog@1.0.0
#9 2.968 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 2.968 npm WARN     @radix-ui/react-dialog@"1.0.0" from cmdk@0.2.1
#9 2.968 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk
#9 2.978 npm WARN ERESOLVE overriding peer dependency
#9 2.978 npm WARN While resolving: @radix-ui/react-compose-refs@1.0.0
#9 2.978 npm WARN Found: react@19.2.3
#9 2.978 npm WARN node_modules/react
#9 2.978 npm WARN   react@"^19.2.1" from the root project
#9 2.978 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 2.978 npm WARN 
#9 2.978 npm WARN Could not resolve dependency:
#9 2.978 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-compose-refs@1.0.0
#9 2.978 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-compose-refs
#9 2.978 npm WARN   @radix-ui/react-compose-refs@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 2.978 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 2.978 npm WARN   4 more (@radix-ui/react-dismissable-layer, ...)
#9 2.978 npm WARN 
#9 2.978 npm WARN Conflicting peer dependency: react@18.3.1
#9 2.978 npm WARN node_modules/react
#9 2.978 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-compose-refs@1.0.0
#9 2.978 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-compose-refs
#9 2.978 npm WARN     @radix-ui/react-compose-refs@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 2.978 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 2.978 npm WARN     4 more (@radix-ui/react-dismissable-layer, ...)
#9 2.987 npm WARN ERESOLVE overriding peer dependency
#9 2.987 npm WARN While resolving: @radix-ui/react-context@1.0.0
#9 2.987 npm WARN Found: react@19.2.3
#9 2.987 npm WARN node_modules/react
#9 2.987 npm WARN   react@"^19.2.1" from the root project
#9 2.987 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 2.987 npm WARN 
#9 2.987 npm WARN Could not resolve dependency:
#9 2.987 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-context@1.0.0
#9 2.987 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-context
#9 2.987 npm WARN   @radix-ui/react-context@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 2.987 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 2.987 npm WARN 
#9 2.987 npm WARN Conflicting peer dependency: react@18.3.1
#9 2.987 npm WARN node_modules/react
#9 2.987 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-context@1.0.0
#9 2.987 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-context
#9 2.987 npm WARN     @radix-ui/react-context@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 2.987 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 2.997 npm WARN ERESOLVE overriding peer dependency
#9 2.997 npm WARN While resolving: @radix-ui/react-dismissable-layer@1.0.0
#9 2.997 npm WARN Found: react@19.2.3
#9 2.997 npm WARN node_modules/react
#9 2.997 npm WARN   react@"^19.2.1" from the root project
#9 2.997 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 2.997 npm WARN 
#9 2.997 npm WARN Could not resolve dependency:
#9 2.997 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-dismissable-layer@1.0.0
#9 2.997 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer
#9 2.997 npm WARN   @radix-ui/react-dismissable-layer@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 2.997 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 2.997 npm WARN 
#9 2.997 npm WARN Conflicting peer dependency: react@18.3.1
#9 2.997 npm WARN node_modules/react
#9 2.997 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-dismissable-layer@1.0.0
#9 2.997 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer
#9 2.997 npm WARN     @radix-ui/react-dismissable-layer@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 2.997 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.002 npm WARN ERESOLVE overriding peer dependency
#9 3.002 npm WARN While resolving: @radix-ui/react-dismissable-layer@1.0.0
#9 3.002 npm WARN Found: react-dom@19.2.3
#9 3.002 npm WARN node_modules/react-dom
#9 3.002 npm WARN   react-dom@"^19.2.1" from the root project
#9 3.002 npm WARN   34 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.002 npm WARN 
#9 3.002 npm WARN Could not resolve dependency:
#9 3.002 npm WARN peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-dismissable-layer@1.0.0
#9 3.002 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer
#9 3.002 npm WARN   @radix-ui/react-dismissable-layer@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.002 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.002 npm WARN 
#9 3.002 npm WARN Conflicting peer dependency: react-dom@18.3.1
#9 3.002 npm WARN node_modules/react-dom
#9 3.002 npm WARN   peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-dismissable-layer@1.0.0
#9 3.002 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer
#9 3.002 npm WARN     @radix-ui/react-dismissable-layer@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.002 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.011 npm WARN ERESOLVE overriding peer dependency
#9 3.011 npm WARN While resolving: @radix-ui/react-focus-guards@1.0.0
#9 3.011 npm WARN Found: react@19.2.3
#9 3.011 npm WARN node_modules/react
#9 3.011 npm WARN   react@"^19.2.1" from the root project
#9 3.011 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.011 npm WARN 
#9 3.011 npm WARN Could not resolve dependency:
#9 3.011 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-focus-guards@1.0.0
#9 3.011 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-guards
#9 3.011 npm WARN   @radix-ui/react-focus-guards@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.011 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.011 npm WARN 
#9 3.011 npm WARN Conflicting peer dependency: react@18.3.1
#9 3.011 npm WARN node_modules/react
#9 3.011 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-focus-guards@1.0.0
#9 3.011 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-guards
#9 3.011 npm WARN     @radix-ui/react-focus-guards@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.011 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.019 npm WARN ERESOLVE overriding peer dependency
#9 3.019 npm WARN While resolving: @radix-ui/react-focus-scope@1.0.0
#9 3.019 npm WARN Found: react@19.2.3
#9 3.019 npm WARN node_modules/react
#9 3.019 npm WARN   react@"^19.2.1" from the root project
#9 3.019 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.019 npm WARN 
#9 3.019 npm WARN Could not resolve dependency:
#9 3.019 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-focus-scope@1.0.0
#9 3.019 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-scope
#9 3.019 npm WARN   @radix-ui/react-focus-scope@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.019 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.019 npm WARN 
#9 3.019 npm WARN Conflicting peer dependency: react@18.3.1
#9 3.019 npm WARN node_modules/react
#9 3.019 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-focus-scope@1.0.0
#9 3.019 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-scope
#9 3.019 npm WARN     @radix-ui/react-focus-scope@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.019 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.023 npm WARN ERESOLVE overriding peer dependency
#9 3.023 npm WARN While resolving: @radix-ui/react-focus-scope@1.0.0
#9 3.023 npm WARN Found: react-dom@19.2.3
#9 3.023 npm WARN node_modules/react-dom
#9 3.023 npm WARN   react-dom@"^19.2.1" from the root project
#9 3.023 npm WARN   34 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.023 npm WARN 
#9 3.023 npm WARN Could not resolve dependency:
#9 3.023 npm WARN peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-focus-scope@1.0.0
#9 3.023 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-scope
#9 3.023 npm WARN   @radix-ui/react-focus-scope@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.023 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.023 npm WARN 
#9 3.023 npm WARN Conflicting peer dependency: react-dom@18.3.1
#9 3.023 npm WARN node_modules/react-dom
#9 3.023 npm WARN   peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-focus-scope@1.0.0
#9 3.023 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-scope
#9 3.023 npm WARN     @radix-ui/react-focus-scope@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.023 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.031 npm WARN ERESOLVE overriding peer dependency
#9 3.031 npm WARN While resolving: @radix-ui/react-id@1.0.0
#9 3.031 npm WARN Found: react@19.2.3
#9 3.031 npm WARN node_modules/react
#9 3.031 npm WARN   react@"^19.2.1" from the root project
#9 3.031 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.031 npm WARN 
#9 3.031 npm WARN Could not resolve dependency:
#9 3.031 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-id@1.0.0
#9 3.031 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-id
#9 3.031 npm WARN   @radix-ui/react-id@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.031 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.031 npm WARN 
#9 3.031 npm WARN Conflicting peer dependency: react@18.3.1
#9 3.031 npm WARN node_modules/react
#9 3.031 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-id@1.0.0
#9 3.031 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-id
#9 3.031 npm WARN     @radix-ui/react-id@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.031 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.041 npm WARN ERESOLVE overriding peer dependency
#9 3.041 npm WARN While resolving: @radix-ui/react-portal@1.0.0
#9 3.041 npm WARN Found: react@19.2.3
#9 3.041 npm WARN node_modules/react
#9 3.041 npm WARN   react@"^19.2.1" from the root project
#9 3.041 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.041 npm WARN 
#9 3.041 npm WARN Could not resolve dependency:
#9 3.041 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-portal@1.0.0
#9 3.041 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-portal
#9 3.041 npm WARN   @radix-ui/react-portal@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.041 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.041 npm WARN 
#9 3.041 npm WARN Conflicting peer dependency: react@18.3.1
#9 3.041 npm WARN node_modules/react
#9 3.041 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-portal@1.0.0
#9 3.041 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-portal
#9 3.041 npm WARN     @radix-ui/react-portal@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.041 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.045 npm WARN ERESOLVE overriding peer dependency
#9 3.045 npm WARN While resolving: @radix-ui/react-portal@1.0.0
#9 3.045 npm WARN Found: react-dom@19.2.3
#9 3.045 npm WARN node_modules/react-dom
#9 3.045 npm WARN   react-dom@"^19.2.1" from the root project
#9 3.045 npm WARN   34 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.045 npm WARN 
#9 3.045 npm WARN Could not resolve dependency:
#9 3.045 npm WARN peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-portal@1.0.0
#9 3.045 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-portal
#9 3.045 npm WARN   @radix-ui/react-portal@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.045 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.045 npm WARN 
#9 3.045 npm WARN Conflicting peer dependency: react-dom@18.3.1
#9 3.045 npm WARN node_modules/react-dom
#9 3.045 npm WARN   peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-portal@1.0.0
#9 3.045 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-portal
#9 3.045 npm WARN     @radix-ui/react-portal@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.045 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.054 npm WARN ERESOLVE overriding peer dependency
#9 3.054 npm WARN While resolving: @radix-ui/react-presence@1.0.0
#9 3.054 npm WARN Found: react@19.2.3
#9 3.054 npm WARN node_modules/react
#9 3.054 npm WARN   react@"^19.2.1" from the root project
#9 3.054 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.054 npm WARN 
#9 3.054 npm WARN Could not resolve dependency:
#9 3.054 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-presence@1.0.0
#9 3.054 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-presence
#9 3.054 npm WARN   @radix-ui/react-presence@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.054 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.054 npm WARN 
#9 3.054 npm WARN Conflicting peer dependency: react@18.3.1
#9 3.054 npm WARN node_modules/react
#9 3.054 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-presence@1.0.0
#9 3.054 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-presence
#9 3.054 npm WARN     @radix-ui/react-presence@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.054 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.058 npm WARN ERESOLVE overriding peer dependency
#9 3.058 npm WARN While resolving: @radix-ui/react-presence@1.0.0
#9 3.058 npm WARN Found: react-dom@19.2.3
#9 3.058 npm WARN node_modules/react-dom
#9 3.058 npm WARN   react-dom@"^19.2.1" from the root project
#9 3.058 npm WARN   34 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.058 npm WARN 
#9 3.058 npm WARN Could not resolve dependency:
#9 3.058 npm WARN peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-presence@1.0.0
#9 3.058 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-presence
#9 3.058 npm WARN   @radix-ui/react-presence@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.058 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.058 npm WARN 
#9 3.058 npm WARN Conflicting peer dependency: react-dom@18.3.1
#9 3.058 npm WARN node_modules/react-dom
#9 3.058 npm WARN   peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-presence@1.0.0
#9 3.058 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-presence
#9 3.058 npm WARN     @radix-ui/react-presence@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.058 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.067 npm WARN ERESOLVE overriding peer dependency
#9 3.067 npm WARN While resolving: @radix-ui/react-primitive@1.0.0
#9 3.067 npm WARN Found: react@19.2.3
#9 3.067 npm WARN node_modules/react
#9 3.067 npm WARN   react@"^19.2.1" from the root project
#9 3.067 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.067 npm WARN 
#9 3.067 npm WARN Could not resolve dependency:
#9 3.067 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-primitive@1.0.0
#9 3.067 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-primitive
#9 3.067 npm WARN   @radix-ui/react-primitive@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.067 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.067 npm WARN   3 more (@radix-ui/react-dismissable-layer, ...)
#9 3.067 npm WARN 
#9 3.067 npm WARN Conflicting peer dependency: react@18.3.1
#9 3.067 npm WARN node_modules/react
#9 3.067 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-primitive@1.0.0
#9 3.067 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-primitive
#9 3.067 npm WARN     @radix-ui/react-primitive@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.067 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.067 npm WARN     3 more (@radix-ui/react-dismissable-layer, ...)
#9 3.071 npm WARN ERESOLVE overriding peer dependency
#9 3.071 npm WARN While resolving: @radix-ui/react-primitive@1.0.0
#9 3.071 npm WARN Found: react-dom@19.2.3
#9 3.072 npm WARN node_modules/react-dom
#9 3.072 npm WARN   react-dom@"^19.2.1" from the root project
#9 3.072 npm WARN   34 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.072 npm WARN 
#9 3.072 npm WARN Could not resolve dependency:
#9 3.072 npm WARN peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-primitive@1.0.0
#9 3.072 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-primitive
#9 3.072 npm WARN   @radix-ui/react-primitive@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.072 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.072 npm WARN   3 more (@radix-ui/react-dismissable-layer, ...)
#9 3.072 npm WARN 
#9 3.072 npm WARN Conflicting peer dependency: react-dom@18.3.1
#9 3.072 npm WARN node_modules/react-dom
#9 3.072 npm WARN   peer react-dom@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-primitive@1.0.0
#9 3.072 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-primitive
#9 3.072 npm WARN     @radix-ui/react-primitive@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.072 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.072 npm WARN     3 more (@radix-ui/react-dismissable-layer, ...)
#9 3.081 npm WARN ERESOLVE overriding peer dependency
#9 3.081 npm WARN While resolving: @radix-ui/react-slot@1.0.0
#9 3.081 npm WARN Found: react@19.2.3
#9 3.081 npm WARN node_modules/react
#9 3.081 npm WARN   react@"^19.2.1" from the root project
#9 3.081 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.081 npm WARN 
#9 3.081 npm WARN Could not resolve dependency:
#9 3.081 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-slot@1.0.0
#9 3.081 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-slot
#9 3.081 npm WARN   @radix-ui/react-slot@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.081 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.081 npm WARN   1 more (@radix-ui/react-primitive)
#9 3.081 npm WARN 
#9 3.081 npm WARN Conflicting peer dependency: react@18.3.1
#9 3.081 npm WARN node_modules/react
#9 3.081 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-slot@1.0.0
#9 3.081 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-slot
#9 3.081 npm WARN     @radix-ui/react-slot@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.081 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.081 npm WARN     1 more (@radix-ui/react-primitive)
#9 3.090 npm WARN ERESOLVE overriding peer dependency
#9 3.090 npm WARN While resolving: @radix-ui/react-use-controllable-state@1.0.0
#9 3.090 npm WARN Found: react@19.2.3
#9 3.090 npm WARN node_modules/react
#9 3.090 npm WARN   react@"^19.2.1" from the root project
#9 3.090 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.090 npm WARN 
#9 3.090 npm WARN Could not resolve dependency:
#9 3.090 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-controllable-state@1.0.0
#9 3.090 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-use-controllable-state
#9 3.090 npm WARN   @radix-ui/react-use-controllable-state@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.090 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.090 npm WARN 
#9 3.090 npm WARN Conflicting peer dependency: react@18.3.1
#9 3.090 npm WARN node_modules/react
#9 3.090 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-controllable-state@1.0.0
#9 3.090 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-use-controllable-state
#9 3.090 npm WARN     @radix-ui/react-use-controllable-state@"1.0.0" from @radix-ui/react-dialog@1.0.0
#9 3.090 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.132 npm WARN ERESOLVE overriding peer dependency
#9 3.132 npm WARN While resolving: react-remove-scroll@2.5.4
#9 3.132 npm WARN Found: react@19.2.3
#9 3.132 npm WARN node_modules/react
#9 3.132 npm WARN   react@"^19.2.1" from the root project
#9 3.132 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.132 npm WARN 
#9 3.132 npm WARN Could not resolve dependency:
#9 3.132 npm WARN peer react@"^16.8.0 || ^17.0.0 || ^18.0.0" from react-remove-scroll@2.5.4
#9 3.132 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/react-remove-scroll
#9 3.132 npm WARN   react-remove-scroll@"2.5.4" from @radix-ui/react-dialog@1.0.0
#9 3.132 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.132 npm WARN 
#9 3.132 npm WARN Conflicting peer dependency: react@18.3.1
#9 3.132 npm WARN node_modules/react
#9 3.132 npm WARN   peer react@"^16.8.0 || ^17.0.0 || ^18.0.0" from react-remove-scroll@2.5.4
#9 3.132 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/react-remove-scroll
#9 3.132 npm WARN     react-remove-scroll@"2.5.4" from @radix-ui/react-dialog@1.0.0
#9 3.132 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog
#9 3.142 npm WARN ERESOLVE overriding peer dependency
#9 3.142 npm WARN While resolving: @radix-ui/react-use-callback-ref@1.0.0
#9 3.142 npm WARN Found: react@19.2.3
#9 3.142 npm WARN node_modules/react
#9 3.142 npm WARN   react@"^19.2.1" from the root project
#9 3.142 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.142 npm WARN 
#9 3.142 npm WARN Could not resolve dependency:
#9 3.142 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-callback-ref@1.0.0
#9 3.142 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer/node_modules/@radix-ui/react-use-callback-ref
#9 3.142 npm WARN   @radix-ui/react-use-callback-ref@"1.0.0" from @radix-ui/react-dismissable-layer@1.0.0
#9 3.142 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer
#9 3.142 npm WARN   1 more (@radix-ui/react-use-escape-keydown)
#9 3.142 npm WARN 
#9 3.142 npm WARN Conflicting peer dependency: react@18.3.1
#9 3.142 npm WARN node_modules/react
#9 3.142 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-callback-ref@1.0.0
#9 3.142 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer/node_modules/@radix-ui/react-use-callback-ref
#9 3.142 npm WARN     @radix-ui/react-use-callback-ref@"1.0.0" from @radix-ui/react-dismissable-layer@1.0.0
#9 3.142 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer
#9 3.142 npm WARN     1 more (@radix-ui/react-use-escape-keydown)
#9 3.154 npm WARN ERESOLVE overriding peer dependency
#9 3.154 npm WARN While resolving: @radix-ui/react-use-escape-keydown@1.0.0
#9 3.154 npm WARN Found: react@19.2.3
#9 3.154 npm WARN node_modules/react
#9 3.154 npm WARN   react@"^19.2.1" from the root project
#9 3.154 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.154 npm WARN 
#9 3.154 npm WARN Could not resolve dependency:
#9 3.154 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-escape-keydown@1.0.0
#9 3.154 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer/node_modules/@radix-ui/react-use-escape-keydown
#9 3.154 npm WARN   @radix-ui/react-use-escape-keydown@"1.0.0" from @radix-ui/react-dismissable-layer@1.0.0
#9 3.154 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer
#9 3.154 npm WARN 
#9 3.154 npm WARN Conflicting peer dependency: react@18.3.1
#9 3.154 npm WARN node_modules/react
#9 3.154 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-escape-keydown@1.0.0
#9 3.154 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer/node_modules/@radix-ui/react-use-escape-keydown
#9 3.154 npm WARN     @radix-ui/react-use-escape-keydown@"1.0.0" from @radix-ui/react-dismissable-layer@1.0.0
#9 3.154 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-dismissable-layer
#9 3.164 npm WARN ERESOLVE overriding peer dependency
#9 3.164 npm WARN While resolving: @radix-ui/react-use-callback-ref@1.0.0
#9 3.164 npm WARN Found: react@19.2.3
#9 3.164 npm WARN node_modules/react
#9 3.164 npm WARN   react@"^19.2.1" from the root project
#9 3.164 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.164 npm WARN 
#9 3.164 npm WARN Could not resolve dependency:
#9 3.164 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-callback-ref@1.0.0
#9 3.164 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-scope/node_modules/@radix-ui/react-use-callback-ref
#9 3.164 npm WARN   @radix-ui/react-use-callback-ref@"1.0.0" from @radix-ui/react-focus-scope@1.0.0
#9 3.164 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-scope
#9 3.164 npm WARN 
#9 3.164 npm WARN Conflicting peer dependency: react@18.3.1
#9 3.164 npm WARN node_modules/react
#9 3.164 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-callback-ref@1.0.0
#9 3.164 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-scope/node_modules/@radix-ui/react-use-callback-ref
#9 3.164 npm WARN     @radix-ui/react-use-callback-ref@"1.0.0" from @radix-ui/react-focus-scope@1.0.0
#9 3.164 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-focus-scope
#9 3.174 npm WARN ERESOLVE overriding peer dependency
#9 3.174 npm WARN While resolving: @radix-ui/react-use-layout-effect@1.0.0
#9 3.174 npm WARN Found: react@19.2.3
#9 3.174 npm WARN node_modules/react
#9 3.174 npm WARN   react@"^19.2.1" from the root project
#9 3.174 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.174 npm WARN 
#9 3.174 npm WARN Could not resolve dependency:
#9 3.174 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-layout-effect@1.0.0
#9 3.174 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-id/node_modules/@radix-ui/react-use-layout-effect
#9 3.174 npm WARN   @radix-ui/react-use-layout-effect@"1.0.0" from @radix-ui/react-id@1.0.0
#9 3.174 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-id
#9 3.174 npm WARN 
#9 3.174 npm WARN Conflicting peer dependency: react@18.3.1
#9 3.174 npm WARN node_modules/react
#9 3.174 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-layout-effect@1.0.0
#9 3.174 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-id/node_modules/@radix-ui/react-use-layout-effect
#9 3.174 npm WARN     @radix-ui/react-use-layout-effect@"1.0.0" from @radix-ui/react-id@1.0.0
#9 3.174 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-id
#9 3.183 npm WARN ERESOLVE overriding peer dependency
#9 3.183 npm WARN While resolving: @radix-ui/react-use-layout-effect@1.0.0
#9 3.183 npm WARN Found: react@19.2.3
#9 3.183 npm WARN node_modules/react
#9 3.183 npm WARN   react@"^19.2.1" from the root project
#9 3.183 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.183 npm WARN 
#9 3.183 npm WARN Could not resolve dependency:
#9 3.183 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-layout-effect@1.0.0
#9 3.183 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-presence/node_modules/@radix-ui/react-use-layout-effect
#9 3.183 npm WARN   @radix-ui/react-use-layout-effect@"1.0.0" from @radix-ui/react-presence@1.0.0
#9 3.183 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-presence
#9 3.183 npm WARN 
#9 3.183 npm WARN Conflicting peer dependency: react@18.3.1
#9 3.183 npm WARN node_modules/react
#9 3.183 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-layout-effect@1.0.0
#9 3.183 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-presence/node_modules/@radix-ui/react-use-layout-effect
#9 3.183 npm WARN     @radix-ui/react-use-layout-effect@"1.0.0" from @radix-ui/react-presence@1.0.0
#9 3.183 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-presence
#9 3.195 npm WARN ERESOLVE overriding peer dependency
#9 3.195 npm WARN While resolving: @radix-ui/react-use-callback-ref@1.0.0
#9 3.195 npm WARN Found: react@19.2.3
#9 3.195 npm WARN node_modules/react
#9 3.195 npm WARN   react@"^19.2.1" from the root project
#9 3.195 npm WARN   80 more (@copilotkit/a2ui-renderer, @copilotkit/react-core, ...)
#9 3.195 npm WARN 
#9 3.195 npm WARN Could not resolve dependency:
#9 3.195 npm WARN peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-callback-ref@1.0.0
#9 3.195 npm WARN node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-use-controllable-state/node_modules/@radix-ui/react-use-callback-ref
#9 3.195 npm WARN   @radix-ui/react-use-callback-ref@"1.0.0" from @radix-ui/react-use-controllable-state@1.0.0
#9 3.195 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-use-controllable-state
#9 3.195 npm WARN 
#9 3.195 npm WARN Conflicting peer dependency: react@18.3.1
#9 3.195 npm WARN node_modules/react
#9 3.195 npm WARN   peer react@"^16.8 || ^17.0 || ^18.0" from @radix-ui/react-use-callback-ref@1.0.0
#9 3.195 npm WARN   node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-use-controllable-state/node_modules/@radix-ui/react-use-callback-ref
#9 3.195 npm WARN     @radix-ui/react-use-callback-ref@"1.0.0" from @radix-ui/react-use-controllable-state@1.0.0
#9 3.195 npm WARN     node_modules/@copilotkit/react-textarea/node_modules/cmdk/node_modules/@radix-ui/react-dialog/node_modules/@radix-ui/react-use-controllable-state
#9 3.202 npm WARN EBADENGINE Unsupported engine {
#9 3.202 npm WARN EBADENGINE   package: 'eslint-visitor-keys@5.0.1',
#9 3.202 npm WARN EBADENGINE   required: { node: '^20.19.0 || ^22.13.0 || >=24' },
#9 3.202 npm WARN EBADENGINE   current: { node: 'v20.12.0', npm: '10.5.0' }
#9 3.202 npm WARN EBADENGINE }
#9 9.150 npm WARN deprecated hast@1.0.0: Renamed to rehype
#9 9.302 npm WARN deprecated lodash.get@4.4.2: This package is deprecated. Use the optional chaining (?.) operator instead.
#9 10.13 npm WARN deprecated node-domexception@1.0.0: Use your platform's native DOMException instead
#9 10.68 npm WARN deprecated @copilotkitnext/shared@1.54.0: This package is deprecated. Use @copilotkit/shared instead. V2 features are being integrated into the main @copilotkit exports and will be available under the /v2 subpath.
#9 10.85 npm WARN deprecated @copilotkitnext/agent@1.54.0: This package is deprecated. Use @copilotkit/agent instead. V2 features are being integrated into the main @copilotkit exports and will be available under the /v2 subpath.
#9 10.95 npm WARN deprecated @copilotkitnext/core@1.54.0: This package is deprecated. Use @copilotkit/core instead. V2 features are being integrated into the main @copilotkit exports and will be available under the /v2 subpath.
#9 11.67 npm WARN deprecated @copilotkitnext/web-inspector@1.54.0: This package is deprecated. Use @copilotkit/web-inspector instead. V2 features are being integrated into the main @copilotkit exports and will be available under the /v2 subpath.
#9 11.74 npm WARN deprecated @copilotkitnext/runtime@1.54.0: This package is deprecated. Use @copilotkit/runtime instead. V2 features are being integrated into the main @copilotkit exports and will be available under the /v2 subpath.
#9 13.17 npm WARN deprecated @copilotkitnext/react@1.54.0: This package is deprecated. Use @copilotkit/react instead. V2 features are being integrated into the main @copilotkit exports and will be available under the /v2 subpath.
#9 17.56 
#9 17.56 added 1283 packages, and audited 1284 packages in 15s
#9 17.56 
#9 17.56 371 packages are looking for funding
#9 17.56   run `npm fund` for details
#9 17.60 
#9 17.60 14 vulnerabilities (10 moderate, 4 high)
#9 17.60 
#9 17.60 To address issues that do not require attention, run:
#9 17.60   npm audit fix
#9 17.60 
#9 17.60 To address all issues possible (including breaking changes), run:
#9 17.60   npm audit fix --force
#9 17.60 
#9 17.60 Some issues need review, and may require choosing
#9 17.60 a different dependency.
#9 17.60 
#9 17.60 Run `npm audit` for details.
#9 17.65 ✅ SUCCESS: npm install completed - build continuing with fallback dependencies
#9 17.65 === DEPENDENCY INSTALLATION COMPLETED ===
#9 17.77 npm WARN using --force Recommended protections disabled.
#9 DONE 19.6s

#10 [builder 5/6] COPY . .
#10 DONE 0.3s

#11 [builder 6/6] RUN npm run build
#11 0.454 
#11 0.454 > pydantic-ai-starter@0.1.0 build
#11 0.454 > next build
#11 0.454 
#11 1.036 Attention: Next.js now collects completely anonymous telemetry regarding usage.
#11 1.036 This information is used to shape Next.js' roadmap and prioritize features.
#11 1.036 You can learn more, including how to opt-out if you'd not like to participate in this anonymous program, by visiting the following URL:
#11 1.036 https://nextjs.org/telemetry
#11 1.036 
#11 1.052 ▲ Next.js 16.1.0 (Turbopack)
#11 1.052 
#11 1.109   Creating an optimized production build ...
#11 30.68 ✓ Compiled successfully in 29.2s
#11 30.68   Running TypeScript ...
#11 33.88   Collecting page data using 11 workers ...
#11 34.96   Generating static pages using 11 workers (0/5) ...
#11 35.63   Generating static pages using 11 workers (1/5) 
#11 35.65   Generating static pages using 11 workers (2/5) 
#11 35.65   Generating static pages using 11 workers (3/5) 
#11 36.23 ✓ Generating static pages using 11 workers (5/5) in 1262.3ms
#11 36.23   Finalizing page optimization ...
#11 36.41 
#11 36.41 Route (app)
#11 36.41 ┌ ○ /
#11 36.41 ├ ○ /_not-found
#11 36.41 └ ƒ /api/copilotkit
#11 36.41 
#11 36.41 
#11 36.41 ○  (Static)   prerendered as static content
#11 36.41 ƒ  (Dynamic)  server-rendered on demand
#11 36.41 
#11 DONE 37.0s

#12 [runner 4/6] COPY --from=builder /app/public ./public
#12 DONE 0.2s

#13 [runner 5/6] COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
#13 DONE 0.6s

#14 [runner 6/6] COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
#14 DONE 0.3s

#15 exporting to image
#15 exporting layers
#15 exporting layers 1.7s done
#15 writing image sha256:f544d5a3caafd9a64a10506770616de9310713501c83a7fc10751413d0639d35 done
#15 naming to docker.io/library/my-ag-ui-app:latest done
#15 DONE 1.7s

View build details: docker-desktop://dashboard/build/default/default/26k8324nlduvn2pydhajuj7ir
[2026-03-24 11:31:24] Docker image 'my-ag-ui-app:latest' built successfully
[2026-03-24 11:31:24] ✅ END: DOCKER_IMAGE_BUILD (took 69.857843076s)
[2026-03-24 11:31:24] Verifying Docker image was built successfully...
[2026-03-24 11:31:24] Docker image 'my-ag-ui-app:latest' verified successfully
[2026-03-24 11:31:24] 🔶 START: DOCKER_IMAGE_TAGGING
[2026-03-24 11:31:24] Starting Docker image tagging for local registry...
[2026-03-24 11:31:24] Using comprehensive tagging function with validation and error handling...
[2026-03-24 11:31:24] Starting Docker image tagging for local registry (executing within VM)...
[2026-03-24 11:31:24] ⏱️  Tagging operation started at: 2026-03-24 11:31:24
[2026-03-24 11:31:24] Validating VM accessibility before Docker operations...
[2026-03-24 11:31:25] ✅ VM is accessible for Docker operations
[2026-03-24 11:31:25] Validating Docker daemon availability within VM before image existence check...
[2026-03-24 11:31:26] ✅ Docker daemon is accessible for image validation within VM
[2026-03-24 11:31:26] Performing comprehensive validation of source image my-ag-ui-app:latest within VM...
[2026-03-24 11:31:26] Method 1: Checking exact tag match for my-ag-ui-app:latest within VM...
[2026-03-24 11:31:26] ✅ Source image found with exact tag match within VM: my-ag-ui-app:latest
[2026-03-24 11:31:26] ✅ Comprehensive validation passed: Source image my-ag-ui-app:latest exists within VM
[2026-03-24 11:31:26] Source image details within VM:
REPOSITORY     TAG       SIZE      CREATED AT
my-ag-ui-app   latest    546MB     2026-03-23 11:05:10 -0400 EDT
[2026-03-24 11:31:26] Target registry image tag: localhost:32000/my-ag-ui-app:latest
[2026-03-24 11:31:26]    This tag will be created within VM where localhost:32000 resolves to microk8s registry
[2026-03-24 11:31:26] Checking if target tag already exists within VM...
[2026-03-24 11:31:26] ⚠️  WARNING: Target tag localhost:32000/my-ag-ui-app:latest already exists within VM
[2026-03-24 11:31:26]    Removing existing tag to avoid conflicts...
Untagged: localhost:32000/my-ag-ui-app:latest
[2026-03-24 11:31:27] ✅ Existing tag localhost:32000/my-ag-ui-app:latest removed successfully within VM
[2026-03-24 11:31:27] Tagging image with local registry endpoint within VM...
[2026-03-24 11:31:27]    Command: multipass exec my-ag-ui-app-k8s -- docker tag my-ag-ui-app:latest localhost:32000/my-ag-ui-app:latest
[2026-03-24 11:31:27]    This makes the image addressable by the microk8s local registry within VM
[2026-03-24 11:31:27]    Note: localhost:32000 will resolve to VM's microk8s registry (not host's)
[2026-03-24 11:31:27] Performing pre-flight check: Docker daemon accessibility within VM before tagging...
[2026-03-24 11:31:27] ✅ Docker daemon is accessible for tagging operation within VM
[2026-03-24 11:31:27] ✅ Docker image tagging command completed successfully within VM
[2026-03-24 11:31:27]    Tagging operation: COMPLETED (within VM)
[2026-03-24 11:31:27] Verifying image tagging was successful within VM...
[2026-03-24 11:31:27] ✅ Image tagging verification successful within VM
[2026-03-24 11:31:27]    Target tag localhost:32000/my-ag-ui-app:latest exists and is accessible within VM
[2026-03-24 11:31:28] Tagged image details within VM:
REPOSITORY                     TAG       SIZE      CREATED AT
localhost:32000/my-ag-ui-app   latest    546MB     2026-03-23 11:05:10 -0400 EDT
[2026-03-24 11:31:28] ✅ Image ID verification successful - both images reference the same underlying image within VM
[2026-03-24 11:31:28]    Source image ID: 9bb7f1915756
[2026-03-24 11:31:28]    Tagged image ID: 9bb7f1915756
[2026-03-24 11:31:28] ✅ Docker image tagging for local registry completed successfully within VM
[2026-03-24 11:31:28]    Image tagged as: localhost:32000/my-ag-ui-app:latest
[2026-03-24 11:31:28]    Ready for: Push to microk8s local registry at localhost:32000 (within VM)
[2026-03-24 11:31:28]    Next step: Use the registry push function to push this tagged image from within VM
[2026-03-24 11:31:28] ⏱️  Tagging operation completed at: 2026-03-24 11:31:28
[2026-03-24 11:31:28] ⏱️  Total tagging operation duration: 4 seconds
[2026-03-24 11:31:28] Docker image tagging for registry completed with comprehensive validation
[2026-03-24 11:31:28] ✅ END: DOCKER_IMAGE_TAGGING (took 3.622426308s)
[2026-03-24 11:31:28] 🔶 START: MICROK8S_REGISTRY_SETUP
[2026-03-24 11:31:28] Starting microk8s registry setup...
[2026-03-24 11:31:28] Starting microk8s registry setup...
[2026-03-24 11:31:28] Checking microk8s availability...
[2026-03-24 11:31:28] ✅ microk8s is available in VM
[2026-03-24 11:31:28] Enabling microk8s registry...
[2026-03-24 11:31:28]    Command: microk8s enable registry
[2026-03-24 11:31:28]    Timeout: 30 seconds
[2026-03-24 11:31:28]    This enables the built-in microk8s registry for local image distribution
[2026-03-24 11:31:28]    Executing: timeout 30 multipass exec 'my-ag-ui-app-k8s' -- microk8s enable registry
[2026-03-24 11:31:29] ✅ microk8s registry enable command completed successfully
[2026-03-24 11:31:29]    Registry enablement process: COMPLETED
[2026-03-24 11:31:29]    Execution time: < 30 seconds (within timeout)
[2026-03-24 11:31:29] Registry enablement output:
Infer repository core for addon registry
Addon core/registry is already enabled
[2026-03-24 11:31:29] Waiting 5 seconds for registry to fully start...
[2026-03-24 11:31:34] Verifying registry is running and accessible at localhost:32000...
[2026-03-24 11:31:34]    Registry endpoint: http://localhost:32000
[2026-03-24 11:31:34]    Connection timeout: 5 seconds
[2026-03-24 11:31:34]    Overall timeout: 10 seconds
[2026-03-24 11:31:34]    Executing: timeout 10 multipass exec 'my-ag-ui-app-k8s' -- curl -s --connect-timeout 5 http://localhost:32000/v2/_catalog
[2026-03-24 11:31:34] ✅ Registry is accessible at localhost:32000
[2026-03-24 11:31:34]    Registry connection test: PASSED
[2026-03-24 11:31:34]    Response time: < 5 seconds (within timeout)
[2026-03-24 11:31:34] Registry response:
{"repositories":["my-ag-ui-app"]}
[2026-03-24 11:31:34] Getting detailed registry status...
[2026-03-24 11:31:35] Registry pod status:
NAME                       READY   STATUS    RESTARTS   AGE   IP            NODE               NOMINATED NODE   READINESS GATES
registry-6cf7b9fcc-4kfg7   1/1     Running   1          18h   10.1.217.23   my-ag-ui-app-k8s   <none>           <none>
[2026-03-24 11:31:35] Registry service info:
NAME       TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
registry   NodePort   10.152.183.199   <none>        5000:32000/TCP   18h
[2026-03-24 11:31:35] ✅ Registry verification completed successfully
[2026-03-24 11:31:35]    Registry is accessible at: localhost:32000
[2026-03-24 11:31:35]    Registry can be used for local image distribution
[2026-03-24 11:31:35]    Registry endpoint: http://localhost:32000/v2/_catalog
[2026-03-24 11:31:35]    Status: VERIFIED and READY
[2026-03-24 11:31:35] ✅ microk8s registry setup completed successfully
[2026-03-24 11:31:35]    Registry status: ENABLED and VERIFIED
[2026-03-24 11:31:35]    Registry endpoint: localhost:32000
[2026-03-24 11:31:35]    Ready for: Local image tagging and pushing
[2026-03-24 11:31:35] microk8s registry setup completed successfully
[2026-03-24 11:31:35] ✅ END: MICROK8S_REGISTRY_SETUP (took 6.632825950s)
[2026-03-24 11:31:35] 🔶 START: DOCKER_REGISTRY_PUSH
[2026-03-24 11:31:35] Starting Docker image push to microk8s registry...
[2026-03-24 11:31:35] Using comprehensive push function with validation, error handling, and verification...
[2026-03-24 11:31:35] Starting Docker image push to microk8s registry (executing within VM)...
[2026-03-24 11:31:35] ⏱️  Push operation started at: 2026-03-24 11:31:35
[2026-03-24 11:31:35] Target registry image: localhost:32000/my-ag-ui-app:latest
[2026-03-24 11:31:35]    Note: This references the VM's microk8s registry at localhost:32000
[2026-03-24 11:31:35] Performing pre-flight check: VM accessibility...
[2026-03-24 11:31:35] ✅ VM is accessible for image push
[2026-03-24 11:31:35] Performing pre-flight check: Docker daemon accessibility within VM...
[2026-03-24 11:31:35] ✅ Docker daemon is accessible for image push within VM
[2026-03-24 11:31:35] Performing pre-flight check: Verifying tagged image exists within VM...
[2026-03-24 11:31:35] Local image to be pushed (from within VM):
REPOSITORY                     TAG       SIZE      CREATED AT
localhost:32000/my-ag-ui-app   latest    546MB     2026-03-23 11:05:10 -0400 EDT
[2026-03-24 11:31:35] ✅ Tagged image exists within VM and is ready for push
[2026-03-24 11:31:35] Performing pre-flight check: Verifying microk8s registry is accessible...
[2026-03-24 11:31:35] Verifying registry is running and accessible at localhost:32000...
[2026-03-24 11:31:35]    Registry endpoint: http://localhost:32000
[2026-03-24 11:31:35]    Connection timeout: 5 seconds
[2026-03-24 11:31:35]    Overall timeout: 10 seconds
[2026-03-24 11:31:35]    Executing: timeout 10 multipass exec 'my-ag-ui-app-k8s' -- curl -s --connect-timeout 5 http://localhost:32000/v2/_catalog
[2026-03-24 11:31:36] ✅ Registry is accessible at localhost:32000
[2026-03-24 11:31:36]    Registry connection test: PASSED
[2026-03-24 11:31:36]    Response time: < 5 seconds (within timeout)
[2026-03-24 11:31:36] Registry response:
{"repositories":["my-ag-ui-app"]}
[2026-03-24 11:31:36] Getting detailed registry status...
[2026-03-24 11:31:36] Registry pod status:
NAME                       READY   STATUS    RESTARTS   AGE   IP            NODE               NOMINATED NODE   READINESS GATES
registry-6cf7b9fcc-4kfg7   1/1     Running   1          18h   10.1.217.23   my-ag-ui-app-k8s   <none>           <none>
[2026-03-24 11:31:36] Registry service info:
NAME       TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
registry   NodePort   10.152.183.199   <none>        5000:32000/TCP   18h
[2026-03-24 11:31:36] ✅ Registry verification completed successfully
[2026-03-24 11:31:36]    Registry is accessible at: localhost:32000
[2026-03-24 11:31:36]    Registry can be used for local image distribution
[2026-03-24 11:31:36]    Registry endpoint: http://localhost:32000/v2/_catalog
[2026-03-24 11:31:36]    Status: VERIFIED and READY
[2026-03-24 11:31:36] ✅ microk8s registry is accessible and ready for push
[2026-03-24 11:31:36] Performing pre-flight check: Verifying disk space for push operation...
[2026-03-24 11:31:36] CHECKING DISK SPACE FOR: Docker image push
[2026-03-24 11:31:36] Minimum required: 2GB
[2026-03-24 11:31:36] Available disk space: 368.0GB at .
[2026-03-24 11:31:36] ✅ SUFFICIENT DISK SPACE FOR: Docker image push (366.0GB available above minimum)
[2026-03-24 11:31:36] ✅ Sufficient disk space available for push operation
[2026-03-24 11:31:36] Pushing image to microk8s registry with enhanced retry logic (within VM)...
[2026-03-24 11:31:36]    Command: multipass exec my-ag-ui-app-k8s -- timeout 60 docker push localhost:32000/my-ag-ui-app:latest
[2026-03-24 11:31:36]    This distributes the image to the local microk8s registry for Kubernetes deployment
[2026-03-24 11:31:36]    Using exponential backoff with jitter for transient network issues
[2026-03-24 11:31:36]    Note: localhost:32000 resolves to VM's microk8s registry (not host's)
[2026-03-24 11:31:36] Push attempt 1/3 (initial attempt)...
[2026-03-24 11:31:36]    Executing: multipass exec my-ag-ui-app-k8s -- timeout 60 docker push localhost:32000/my-ag-ui-app:latest
[2026-03-24 11:31:37] ✅ Docker push command completed successfully within VM (attempt 1)
[2026-03-24 11:31:37] ✅ Image push completed successfully within VM
[2026-03-24 11:31:37]    Push command output summary:
The push refers to repository [localhost:32000/my-ag-ui-app]
52a51099bdef: Layer already exists
413c136dedcf: Layer already exists
f82bfb71098a: Layer already exists
82fb5a2278a7: Layer already exists
abc5b1d00820: Layer already exists
75136c45e7ab: Layer already exists
8e1fab8d9171: Layer already exists
d4fc045c9e3a: Layer already exists
a2cffe5fe30b: Layer already exists
latest: digest: sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f size: 1620
[2026-03-24 11:31:37] Verifying image was successfully pushed to registry...
[2026-03-24 11:31:37] Registry verification attempt 1/5...
[2026-03-24 11:31:37] ⚠️  Image not immediately found in registry catalog (attempt 1)
[2026-03-24 11:31:37] Waiting 2s for registry to update...
[2026-03-24 11:31:39] Registry verification attempt 2/5...
[2026-03-24 11:31:39] ⚠️  Image not immediately found in registry catalog (attempt 2)
[2026-03-24 11:31:39] Waiting 2s for registry to update...
[2026-03-24 11:31:41] Registry verification attempt 3/5...
[2026-03-24 11:31:41] ⚠️  Image not immediately found in registry catalog (attempt 3)
[2026-03-24 11:31:41] Waiting 2s for registry to update...
[2026-03-24 11:31:43] Registry verification attempt 4/5...
[2026-03-24 11:31:43] ⚠️  Image not immediately found in registry catalog (attempt 4)
[2026-03-24 11:31:43] Waiting 2s for registry to update...
[2026-03-24 11:31:45] Registry verification attempt 5/5...
[2026-03-24 11:31:45] ⚠️  Image not immediately found in registry catalog (attempt 5)
[2026-03-24 11:31:45] ⚠️  WARNING: Image verification failed - image not found in registry catalog
[2026-03-24 11:31:45]    This may be a temporary issue - the registry may need additional time to update
[2026-03-24 11:31:45]    The push operation completed successfully, but verification could not confirm registry availability
[2026-03-24 11:31:45] 
[2026-03-24 11:31:45] MANUAL VERIFICATION STEPS:
[2026-03-24 11:31:45] 1. Check registry catalog: curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list
[2026-03-24 11:31:45] 2. Check registry status: verify_microk8s_registry
[2026-03-24 11:31:45] 3. List images in registry: curl -s http://localhost:32000/v2/_catalog
[2026-03-24 11:31:45] 4. The image should be available despite verification failure
[2026-03-24 11:31:45] ⏱️  Push operation completed at: 2026-03-24 11:31:45
[2026-03-24 11:31:45] ⏱️  Total push operation duration: 10 seconds
[2026-03-24 11:31:45] ✅ Docker image push to microk8s registry completed successfully within VM
[2026-03-24 11:31:45]    Image: localhost:32000/my-ag-ui-app:latest
[2026-03-24 11:31:45]    Status: PUSHED and VERIFIED (or verification pending)
[2026-03-24 11:31:45]    Registry: http://localhost:32000 (within VM)
[2026-03-24 11:31:45]    Ready for: Kubernetes deployment using registry image reference
[2026-03-24 11:31:45] Docker image push to registry completed with comprehensive validation
[2026-03-24 11:31:45] ✅ END: DOCKER_REGISTRY_PUSH (took 9.998118544s)
[2026-03-24 11:31:45] Verifying microk8s registry is ready for deployment...
[2026-03-24 11:31:45] Verifying registry is running and accessible at localhost:32000...
[2026-03-24 11:31:45]    Registry endpoint: http://localhost:32000
[2026-03-24 11:31:45]    Connection timeout: 5 seconds
[2026-03-24 11:31:45]    Overall timeout: 10 seconds
[2026-03-24 11:31:45]    Executing: timeout 10 multipass exec 'my-ag-ui-app-k8s' -- curl -s --connect-timeout 5 http://localhost:32000/v2/_catalog
[2026-03-24 11:31:45] ✅ Registry is accessible at localhost:32000
[2026-03-24 11:31:45]    Registry connection test: PASSED
[2026-03-24 11:31:45]    Response time: < 5 seconds (within timeout)
[2026-03-24 11:31:45] Registry response:
{"repositories":["my-ag-ui-app"]}
[2026-03-24 11:31:45] Getting detailed registry status...
[2026-03-24 11:31:46] Registry pod status:
NAME                       READY   STATUS    RESTARTS   AGE   IP            NODE               NOMINATED NODE   READINESS GATES
registry-6cf7b9fcc-4kfg7   1/1     Running   1          18h   10.1.217.23   my-ag-ui-app-k8s   <none>           <none>
[2026-03-24 11:31:46] Registry service info:
NAME       TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
registry   NodePort   10.152.183.199   <none>        5000:32000/TCP   18h
[2026-03-24 11:31:46] ✅ Registry verification completed successfully
[2026-03-24 11:31:46]    Registry is accessible at: localhost:32000
[2026-03-24 11:31:46]    Registry can be used for local image distribution
[2026-03-24 11:31:46]    Registry endpoint: http://localhost:32000/v2/_catalog
[2026-03-24 11:31:46]    Status: VERIFIED and READY
[2026-03-24 11:31:46] 🔶 START: KUBERNETES_DEPLOYMENT
[2026-03-24 11:31:46] 🚀 STARTING KUBERNETES DEPLOYMENT PHASE
[2026-03-24 11:31:46] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-24 11:31:46] 📋 DEPLOYMENT DETAILS:
[2026-03-24 11:31:46]    • Manifest: k8s/deployment.yaml
[2026-03-24 11:31:46]    • Image: localhost:32000/my-ag-ui-app:latest (from local registry)
[2026-03-24 11:31:46]    • Strategy: Rolling update with pod restart
[2026-03-24 11:31:46]    • Registry: microk8s local registry
[2026-03-24 11:31:46] 
[2026-03-24 11:31:46] 🔄 STEP 1: Applying deployment manifest...
deployment.apps/my-ag-ui-app unchanged
[2026-03-24 11:31:46] ✅ Deployment manifest applied successfully
[2026-03-24 11:31:46]    • Kubernetes deployment resource created/updated
[2026-03-24 11:31:46]    • Deployment configured to use local registry image
[2026-03-24 11:31:46] 
[2026-03-24 11:31:46] 🔄 STEP 2: Restarting deployment to trigger pod recreation...
[2026-03-24 11:31:46]    • This will create new pods using the updated registry image
[2026-03-24 11:31:46]    • Pods will pull image from localhost:32000/my-ag-ui-app:latest
deployment.apps/my-ag-ui-app restarted
[2026-03-24 11:31:46] ✅ Deployment restarted successfully
[2026-03-24 11:31:46]    • Rolling update initiated
[2026-03-24 11:31:46]    • New pods will be created using registry image
[2026-03-24 11:31:46]    • Expected: Direct pod startup (no ImagePullBackOff with registry approach)
[2026-03-24 11:31:46] 
[2026-03-24 11:31:46] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-24 11:31:46] 🎯 KUBERNETES DEPLOYMENT PHASE COMPLETED
[2026-03-24 11:31:46] 
[2026-03-24 11:31:46] 📊 DEPLOYMENT PROGRESS SUMMARY:
[2026-03-24 11:31:46] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-24 11:31:46] ✅ DEPENDENCY_VALIDATION: Package dependencies validated
[2026-03-24 11:31:46] ✅ DOCKER_IMAGE_BUILD: Image built successfully (localhost:32000/my-ag-ui-app:latest)
[2026-03-24 11:31:46] ✅ MICROK8S_REGISTRY_SETUP: Local registry enabled and accessible
[2026-03-24 11:31:46] ✅ DOCKER_REGISTRY_PUSH: Image pushed to registry with verification
[2026-03-24 11:31:46] ✅ KUBERNETES_DEPLOYMENT: Manifest applied and deployment restarted
[2026-03-24 11:31:46] 🔄 KUBERNETES_VERIFICATION: In progress - verifying pods are ready
[2026-03-24 11:31:46] ⏳ INGRESS_SETUP: Pending - will verify external access
[2026-03-24 11:31:46] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-24 11:31:46] Verifying pod status reaches Running state...
[2026-03-24 11:31:46] Checking pod status after deployment restart... (attempt 1/20)
[2026-03-24 11:31:47] Pod not yet running. Current status:
NAME                            READY   STATUS              RESTARTS   AGE
my-ag-ui-app-5f68759cd-vtqt6    0/1     Terminating         0          13h
my-ag-ui-app-64568b4968-h85n8   1/1     Running             2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ContainerCreating   0          1s
[2026-03-24 11:31:47] Waiting for pod status change from ImagePullBackOff to Running...
[2026-03-24 11:31:50] Checking pod status after deployment restart... (attempt 2/20)
[2026-03-24 11:31:50] Pod not yet running. Current status:
NAME                            READY   STATUS         RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running        2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ErrImagePull   0          5s
[2026-03-24 11:31:54] Checking pod status after deployment restart... (attempt 3/20)
[2026-03-24 11:31:54] Pod not yet running. Current status:
NAME                            READY   STATUS         RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running        2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ErrImagePull   0          8s
[2026-03-24 11:31:57] Checking pod status after deployment restart... (attempt 4/20)
[2026-03-24 11:31:57] Pod not yet running. Current status:
NAME                            READY   STATUS         RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running        2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ErrImagePull   0          12s
[2026-03-24 11:32:01] Checking pod status after deployment restart... (attempt 5/20)
[2026-03-24 11:32:01] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running            2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ImagePullBackOff   0          15s
[2026-03-24 11:32:04] Checking pod status after deployment restart... (attempt 6/20)
[2026-03-24 11:32:05] Pod status: ImagePullBackOff detected (expected before pod starts running)
[2026-03-24 11:32:05] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running            2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ImagePullBackOff   0          19s
[2026-03-24 11:32:08] Checking pod status after deployment restart... (attempt 7/20)
[2026-03-24 11:32:08] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running            2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ImagePullBackOff   0          23s
[2026-03-24 11:32:12] Checking pod status after deployment restart... (attempt 8/20)
[2026-03-24 11:32:12] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running            2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ImagePullBackOff   0          26s
[2026-03-24 11:32:15] Checking pod status after deployment restart... (attempt 9/20)
[2026-03-24 11:32:16] Pod not yet running. Current status:
NAME                            READY   STATUS         RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running        2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ErrImagePull   0          30s
[2026-03-24 11:32:19] Checking pod status after deployment restart... (attempt 10/20)
[2026-03-24 11:32:19] Pod not yet running. Current status:
NAME                            READY   STATUS         RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running        2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ErrImagePull   0          34s
[2026-03-24 11:32:23] Checking pod status after deployment restart... (attempt 11/20)
[2026-03-24 11:32:23] Pod not yet running. Current status:
NAME                            READY   STATUS         RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running        2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ErrImagePull   0          37s
[2026-03-24 11:32:28] Checking pod status after deployment restart... (attempt 12/20)
[2026-03-24 11:32:29] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running            2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ImagePullBackOff   0          43s
[2026-03-24 11:32:34] Checking pod status after deployment restart... (attempt 13/20)
[2026-03-24 11:32:34] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running            2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ImagePullBackOff   0          49s
[2026-03-24 11:32:40] Checking pod status after deployment restart... (attempt 14/20)
[2026-03-24 11:32:40] Pod not yet running. Current status:
NAME                            READY   STATUS         RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running        2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ErrImagePull   0          55s
[2026-03-24 11:32:46] Checking pod status after deployment restart... (attempt 15/20)
[2026-03-24 11:32:46] Pod not yet running. Current status:
NAME                            READY   STATUS         RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running        2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ErrImagePull   0          60s
[2026-03-24 11:32:51] Checking pod status after deployment restart... (attempt 16/20)
[2026-03-24 11:32:51] Pod not yet running. Current status:
NAME                            READY   STATUS         RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running        2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ErrImagePull   0          66s
[2026-03-24 11:32:57] Checking pod status after deployment restart... (attempt 17/20)
[2026-03-24 11:32:57] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running            2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ImagePullBackOff   0          71s
[2026-03-24 11:33:02] Checking pod status after deployment restart... (attempt 18/20)
[2026-03-24 11:33:03] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running            2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ImagePullBackOff   0          77s
[2026-03-24 11:33:08] Checking pod status after deployment restart... (attempt 19/20)
[2026-03-24 11:33:08] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running            2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ImagePullBackOff   0          83s
[2026-03-24 11:33:14] Checking pod status after deployment restart... (attempt 20/20)
[2026-03-24 11:33:14] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running            2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ImagePullBackOff   0          88s
[2026-03-24 11:33:14] ERROR: Pod did not reach Running status after deployment restart
[2026-03-24 11:33:14] Final pod status:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running            2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ImagePullBackOff   0          89s
[2026-03-24 11:33:15] Pod details for debugging:
Name:             my-ag-ui-app-64568b4968-h85n8
Namespace:        default
Priority:         0
Service Account:  default
Node:             my-ag-ui-app-k8s/10.237.212.68
Start Time:       Sat, 21 Mar 2026 21:09:17 -0400
Labels:           app=my-ag-ui-app
                  pod-template-hash=64568b4968
Annotations:      cni.projectcalico.org/containerID: cf9bfbf2389c4316741b8dcd78d4148c9f32e4c896ce0e0308f5a896090b1c75
                  cni.projectcalico.org/podIP: 10.1.217.26/32
                  cni.projectcalico.org/podIPs: 10.1.217.26/32
Status:           Running
IP:               10.1.217.26
IPs:
  IP:           10.1.217.26
Controlled By:  ReplicaSet/my-ag-ui-app-64568b4968
Containers:
  my-ag-ui-app:
    Container ID:   containerd://ad783d6954cd6572ea96346d51ff28aa92f6fa1b8cc41d8d4bf884016ce5e4cd
    Image:          nginx:latest
    Image ID:       docker.io/library/nginx@sha256:dec7a90bd0973b076832dc56933fe876bc014929e14b4ec49923951405370112
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Mon, 23 Mar 2026 16:45:04 -0400
    Ready:          True
    Restart Count:  2
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


Name:             my-ag-ui-app-647f57cd44-zh68d
Namespace:        default
Priority:         0
Service Account:  default
Node:             my-ag-ui-app-k8s/10.237.212.68
Start Time:       Tue, 24 Mar 2026 11:31:46 -0400
Labels:           app=my-ag-ui-app
                  pod-template-hash=647f57cd44
Annotations:      cni.projectcalico.org/containerID: ebd974fb01277b07a771fe78a3a9861bbef38fee6e8bcea7a51e1152eaca2b8e
                  cni.projectcalico.org/podIP: 10.1.217.31/32
                  cni.projectcalico.org/podIPs: 10.1.217.31/32
                  kubectl.kubernetes.io/restartedAt: 2026-03-24T11:31:46-04:00
Status:           Pending
IP:               10.1.217.31
IPs:
  IP:           10.1.217.31
Controlled By:  ReplicaSet/my-ag-ui-app-647f57cd44
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
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-7g9sd (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  kube-api-access-7g9sd:
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
  Normal   Scheduled  88s                default-scheduler  Successfully assigned default/my-ag-ui-app-647f57cd44-zh68d to my-ag-ui-app-k8s
  Normal   Pulling    48s (x3 over 87s)  kubelet            Pulling image "my-ag-ui-app:latest"
  Warning  Failed     47s (x3 over 87s)  kubelet            Failed to pull image "my-ag-ui-app:latest": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/my-ag-ui-app:latest": failed to unpack image on snapshotter overlayfs: unexpected media type text/html for sha256:7f6974f679f1db42eb537f52680afa9f1841e9f51ddfd4d1bd3658ab8d6535db: not found
  Warning  Failed     47s (x3 over 87s)  kubelet            Error: ErrImagePull
  Normal   BackOff    8s (x5 over 86s)   kubelet            Back-off pulling image "my-ag-ui-app:latest"
  Warning  Failed     8s (x5 over 86s)   kubelet            Error: ImagePullBackOff
[2026-03-24 11:33:15] DEPLOYMENT ERROR [Code: 126]: Pod did not reach Running status after deployment restart
[2026-03-24 11:33:15] RECOVERY SUGGESTION: Check pod logs: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl logs -l app=my-ag-ui-app. Verify registry is accessible: microk8s kubectl get pods -n container-registry.
[2026-03-24 11:33:15] ESSENTIAL DIAGNOSTIC INFO:
[2026-03-24 11:33:15] Current directory: /home/ncheaz/git/my-ag-ui-app
[2026-03-24 11:33:15] k8s directory exists: yes
[2026-03-24 11:33:15] POD STATUS DIAGNOSTICS:
NAME                            READY   STATUS             RESTARTS   AGE
my-ag-ui-app-64568b4968-h85n8   1/1     Running            2          2d14h
my-ag-ui-app-647f57cd44-zh68d   0/1     ImagePullBackOff   0          89s
[2026-03-24 11:33:15] Docker images in VM:
IMAGE                 ID             DISK USAGE   CONTENT SIZE   EXTRA
my-ag-ui-app:latest   9bb7f1915756        546MB          263MB        
[2026-03-24 11:33:16] Recovery: Check pod logs: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl logs -l app=my-ag-ui-app
[2026-03-24 11:33:16] Manual: Delete pod to recreate: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl delete pods -l app=my-ag-ui-app
