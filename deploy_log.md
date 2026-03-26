Starting deployment pipeline...
Step 1: Setting up Kubernetes secrets...
[2026-03-26 14:11:56] Starting Kubernetes secrets setup...
[2026-03-26 14:11:56] k8s directory found: /home/ncheaz/git/my-ag-ui-app/k8s/
[2026-03-26 14:11:56] setup-secrets.sh script found: /home/ncheaz/git/my-ag-ui-app/k8s/setup-secrets.sh
[2026-03-26 14:11:56] Setting up environment variables for secrets creation...
[2026-03-26 14:11:56] Loading environment variables from .env file...
[2026-03-26 14:11:56] Set environment variable: OPENAI_API_KEY
[2026-03-26 14:11:56] Set environment variable: OPENAI_BASE_URL
[2026-03-26 14:11:56] Set environment variable: OPENAI_MODEL
[2026-03-26 14:11:56] Set environment variable: LLM_MAX_TOKENS
[2026-03-26 14:11:56] Set environment variable: LLM_CONTEXT_WINDOW
[2026-03-26 14:11:56] Set environment variable: EMBEDDING_MODEL
[2026-03-26 14:11:56] All required environment variables are set
[2026-03-26 14:11:56] Running secrets setup script...
[2026-03-26 14:11:56] Setting up Kubernetes secrets...
[2026-03-26 14:11:56] Reading environment variables...
[2026-03-26 14:11:56] Encoding values to base64...
[2026-03-26 14:11:56] Generating Kubernetes secrets file...
[2026-03-26 14:11:56] Validating generated YAML file...
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
[2026-03-26 14:11:56] Kubernetes secrets setup completed successfully
Step 2: Building Docker image...
[2026-03-26 14:11:56] Starting dependency validation...
[2026-03-26 14:11:56] Checking if package.json and package-lock.json are in sync...
[2026-03-26 14:11:57] ✅ SUCCESS: package.json and package-lock.json are synchronized
[2026-03-26 14:11:57]    Dependencies are ready for reproducible Docker builds.
[2026-03-26 14:11:57] Building Docker image 'my-ag-ui-app:latest'...
[2026-03-26 14:12:42] Docker image 'my-ag-ui-app:latest' built successfully
[2026-03-26 14:12:42] Docker image 'my-ag-ui-app:latest' verified successfully
Step 3: Tagging Docker image...
[2026-03-26 14:12:42] Starting Docker image tagging for local registry...
[2026-03-26 14:12:42] Using comprehensive tagging function with validation and error handling...
Untagged: localhost:32000/my-ag-ui-app:latest
[2026-03-26 14:12:44] ✅ Docker image tagging for registry completed with comprehensive validation
[2026-03-26 14:12:44]    Image successfully tagged as: localhost:32000/my-ag-ui-app:latest
Step 4: Setting up Microk8s registry...
[2026-03-26 14:12:44] Starting microk8s registry setup...
[2026-03-26 14:12:44] Starting microk8s registry setup...
[2026-03-26 14:12:44] ✅ microk8s is available in VM
[2026-03-26 14:12:44] ✅ microk8s registry enable command completed successfully
[2026-03-26 14:12:50] ✅ REGISTRY CONNECTIVITY: SUCCESS
[2026-03-26 14:12:50] ✅ REGISTRY RESPONSE FORMAT: VALID JSON
[2026-03-26 14:12:50] ✅ Registry verification completed successfully
[2026-03-26 14:12:50] ✅ microk8s registry setup completed successfully
[2026-03-26 14:12:50] ✅ END: MICROK8S_REGISTRY_SETUP (duration: 5.965350467s)
Step 5: Pushing Docker image...
[2026-03-26 14:12:50] === DOCKER IMAGE PUSH TO MICROK8S REGISTRY ===
[2026-03-26 14:12:50] Starting Docker image push to microk8s registry (executing within VM)...
[2026-03-26 14:12:50] Target registry image: localhost:32000/my-ag-ui-app:latest
[2026-03-26 14:12:50] ✅ Registry verification completed successfully
[2026-03-26 14:12:50]    Registry is accessible at: localhost:32000
[2026-03-26 14:12:50] Pushing image to microk8s registry with enhanced retry logic (within VM)...
[2026-03-26 14:12:50]    Command: multipass exec my-ag-ui-app-k8s -- timeout 60 docker push localhost:32000/my-ag-ui-app:latest
[2026-03-26 14:12:51] ✅ Docker push command completed successfully within VM (attempt 1)
[2026-03-26 14:12:51] ✅ Image push completed successfully within VM
[2026-03-26 14:12:51]    Push command output summary:
The push refers to repository [localhost:32000/my-ag-ui-app]
52a51099bdef: Layer already exists
f82bfb71098a: Layer already exists
a2cffe5fe30b: Layer already exists
75136c45e7ab: Layer already exists
82fb5a2278a7: Layer already exists
d4fc045c9e3a: Layer already exists
413c136dedcf: Layer already exists
abc5b1d00820: Layer already exists
8e1fab8d9171: Layer already exists
[2026-03-26 14:12:51]    ... (output truncated, full output logged to file)
[2026-03-26 14:12:51] Verifying image was successfully pushed to registry...
[2026-03-26 14:12:59] ⚠️  WARNING: Image verification failed - image not found in registry catalog
[2026-03-26 14:12:59]    This may be a temporary issue - the registry may need additional time to update
[2026-03-26 14:12:59]    The push operation completed successfully, but verification could not confirm registry availability
[2026-03-26 14:12:59] 
[2026-03-26 14:12:59] MANUAL VERIFICATION STEPS:
[2026-03-26 14:12:59] 1. Check registry catalog: curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list
[2026-03-26 14:12:59] 2. Check registry status: verify_microk8s_registry
[2026-03-26 14:12:59] 3. List images in registry: curl -s http://localhost:32000/v2/_catalog
[2026-03-26 14:12:59] 4. The image should be available despite verification failure
[2026-03-26 14:12:59] ✅ Docker image push to microk8s registry completed successfully within VM
[2026-03-26 14:12:59]    Image: localhost:32000/my-ag-ui-app:latest
[2026-03-26 14:12:59]    Status: PUSHED and VERIFIED (or verification pending)
[2026-03-26 14:12:59]    Registry: http://localhost:32000 (within VM)
[2026-03-26 14:12:59]    Ready for: Kubernetes deployment using registry image reference
[2026-03-26 14:12:59] ✅ Docker image push to microk8s registry completed successfully
Step 6: Deploying to Kubernetes...
2026-03-26 14:12:59 - DEBUG: Running with full verbose output (critical failure phase)
2026-03-26 14:12:59 - DEBUG: Set DEBUG=all for explicit debugging if needed
[2026-03-26 14:12:59] Starting phase: KUBERNETES_DEPLOYMENT
[2026-03-26 14:12:59] 🚀 STARTING KUBERNETES DEPLOYMENT PHASE
[2026-03-26 14:12:59] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-26 14:12:59] 📋 DEPLOYMENT DETAILS:
[2026-03-26 14:12:59]    • Manifest: k8s/deployment.yaml
[2026-03-26 14:12:59]    • Image: localhost:32000/my-ag-ui-app:latest (from local registry)
[2026-03-26 14:12:59]    • Strategy: Rolling update with pod restart
[2026-03-26 14:12:59]    • Registry: microk8s local registry
[2026-03-26 14:12:59] 
[2026-03-26 14:12:59] 🔄 STEP 1: Applying deployment manifest...
[2026-03-26 14:12:59]    • Manifest: k8s/deployment.yaml
[2026-03-26 14:12:59]    • Image: localhost:32000/my-ag-ui-app:latest (from local registry)
[2026-03-26 14:12:59]    • Strategy: Rolling update with pod restart
[2026-03-26 14:12:59]    • Registry: microk8s local registry
[2026-03-26 14:12:59] 
[2026-03-26 14:12:59] 📊 PRE-APPLOY VERIFICATION: Checking current deployment state...
[2026-03-26 14:13:00]    • Current deployment state: EXISTS
[2026-03-26 14:13:00]    • Current replicas: 1
[2026-03-26 14:13:00]    • Ready replicas: 
[2026-03-26 14:13:00]    • Updated replicas: 1
[2026-03-26 14:13:00]    • Action: UPDATE existing deployment
[2026-03-26 14:13:00] 📋 MANIFEST VALIDATION: Checking deployment.yaml file...
[2026-03-26 14:13:00] 🔍 REGISTRY PORT VALIDATION: Checking for registry port mismatches...
[2026-03-26 14:13:00]    ✓ Registry port validation: PASSED (using port 32000)
[2026-03-26 14:13:00]    • Manifest file size: 123 lines
[2026-03-26 14:13:00]    • Manifest validation: PASSED
[2026-03-26 14:13:00] 🔌 KUBERNETES CONNECTION: Verifying cluster access...
[2026-03-26 14:13:00]    • Kubernetes cluster: ACCESSIBLE
[2026-03-26 14:13:00] 🏷️  NAMESPACE VERIFICATION: Checking target namespace...
[2026-03-26 14:13:00]    • Target namespace: default
[2026-03-26 14:13:01]    • Namespace status: EXISTS and ACTIVE
[2026-03-26 14:13:01] 🚀 APPLYING DEPLOYMENT MANIFEST with detailed logging...
[2026-03-26 14:13:01]    • Command: multipass exec 'my-ag-ui-app-k8s' -- microk8s kubectl apply -f k8s/deployment.yaml
[2026-03-26 14:13:01]    • Expected: Deployment resource creation/update
[2026-03-26 14:13:01]    • Output will be captured and analyzed below...
[2026-03-26 14:13:01] 📤 KUBECTL APPLY OUTPUT (first 1000 chars):
deployment.apps/my-ag-ui-app unchanged
[2026-03-26 14:13:01] ✅ KUBECTL APPLY: Command completed successfully (exit code: 0)
[2026-03-26 14:13:01]    • Result: Deployment unchanged (no changes detected)
[2026-03-26 14:13:01]    • Action: No update needed - configuration identical
[2026-03-26 14:13:01] 🔍 POST-APPLY VERIFICATION: Checking deployment status after apply...
[2026-03-26 14:13:01]    ✅ Deployment verification: PASSED
[2026-03-26 14:13:01]       • Deployment resource exists: my-ag-ui-app
[2026-03-26 14:13:02]       • Deployment spec: {"progressDeadlineSeconds":600,"replicas":1,"revisionHistoryLimit":10,"selector":{"matchLabels":{"app":"my-ag-ui-app"}},"strategy":{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"},"template":{"metadata":{"annotations":{"kubectl.kubernetes.io/restartedAt":"2026-03-25T22:43:36-04:00"},"creationTimestamp":null,"labels":{"app":"my-ag-ui-app"}},"spec":{"containers":[{"env":[{"name":"OPENAI_API_KEY","valueFrom":{"secretKeyRef":{"key":"openai-api-key","name":"my-ag-ui-app-secrets"}}},{"name":"OPENAI_BASE_URL","valueFrom":{"secretKeyRef":{"key":"openai-base-url","name":"my-ag-ui-app-secrets"}}},{"name":"OPENAI_MODEL","valueFrom":{"secretKeyRef":{"key":"openai-model","name":"my-ag-ui-app-secrets"}}},{"name":"EMBEDDING_MODEL","valueFrom":{"secretKeyRef":{"key":"embedding-model","name":"my-ag-ui-app-secrets"}}},{"name":"LOGFIRE_TOKEN","valueFrom":{"secretKeyRef":{"key":"logfire-token","name":"my-ag-ui-app-secrets"}}},{"name":"LLM_MAX_TOKENS","valueFrom":{"configMapKeyRef":{"key":"llm-max-tokens","name":"my-ag-ui-app-config"}}},{"name":"LLM_CONTEXT_WINDOW","valueFrom":{"configMapKeyRef":{"key":"llm-context-window","name":"my-ag-ui-app-config"}}}],"image":"localhost:32000/my-ag-ui-app:latest","imagePullPolicy":"Always","livenessProbe":{"failureThreshold":3,"httpGet":{"path":"/api/health","port":3000,"scheme":"HTTP"},"initialDelaySeconds":30,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5},"name":"my-ag-ui-app","ports":[{"containerPort":3000,"name":"http","protocol":"TCP"}],"readinessProbe":{"failureThreshold":3,"httpGet":{"path":"/api/health","port":3000,"scheme":"HTTP"},"initialDelaySeconds":5,"periodSeconds":5,"successThreshold":1,"timeoutSeconds":3},"resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}},"terminationMessagePath":"/dev/termination-log","terminationMessagePolicy":"File"}],"dnsPolicy":"ClusterFirst","restartPolicy":"Always","schedulerName":"default-scheduler","securityContext":{},"terminationGracePeriodSeconds":30}}}
[2026-03-26 14:13:02]       • Deployment status: {"conditions":[{"lastTransitionTime":"2026-03-25T20:53:24Z","lastUpdateTime":"2026-03-25T20:53:24Z","message":"Deployment does not have minimum availability.","reason":"MinimumReplicasUnavailable","status":"False","type":"Available"},{"lastTransitionTime":"2026-03-26T02:53:38Z","lastUpdateTime":"2026-03-26T02:53:38Z","message":"ReplicaSet \"my-ag-ui-app-65c69d78c4\" has timed out progressing.","reason":"ProgressDeadlineExceeded","status":"False","type":"Progressing"}],"observedGeneration":16,"replicas":2,"unavailableReplicas":2,"updatedReplicas":1}
[2026-03-26 14:13:02]       ✅ Image reference verification: PASSED
[2026-03-26 14:13:02]          • Expected: localhost:32000/my-ag-ui-app:latest
[2026-03-26 14:13:02]          • Actual: localhost:32000/my-ag-ui-app:latest
[2026-03-26 14:13:02] ✅ Deployment manifest application process completed
[2026-03-26 14:13:02]    • Kubernetes deployment resource processed
[2026-03-26 14:13:02]    • Next step: Deployment restart to trigger pod creation
[2026-03-26 14:13:02] 
[2026-03-26 14:13:02] 🔄 STEP 2: Restarting deployment to trigger pod recreation...
[2026-03-26 14:13:02]    • This will create new pods using the updated registry image
[2026-03-26 14:13:02]    • Pods will pull image from localhost:32000/my-ag-ui-app:latest
deployment.apps/my-ag-ui-app restarted
[2026-03-26 14:13:03] ✅ Deployment restarted successfully
[2026-03-26 14:13:03]    • Rolling update initiated
[2026-03-26 14:13:03]    • New pods will be created using registry image
[2026-03-26 14:13:03]    • Expected: Direct pod startup (no ImagePullBackOff with registry approach)
[2026-03-26 14:13:03] 
[2026-03-26 14:13:03] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-26 14:13:03] 🎯 KUBERNETES DEPLOYMENT PHASE COMPLETED
[2026-03-26 14:13:03] 
[2026-03-26 14:13:03] 📊 DEPLOYMENT PROGRESS SUMMARY:
[2026-03-26 14:13:03] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-26 14:13:03] ✅ DEPENDENCY_VALIDATION: Package dependencies validated
[2026-03-26 14:13:03] ✅ DOCKER_IMAGE_BUILD: Image built successfully (localhost:32000/my-ag-ui-app:latest)
[2026-03-26 14:13:03] ✅ MICROK8S_REGISTRY_SETUP: Local registry enabled and accessible
[2026-03-26 14:13:03] ✅ DOCKER_REGISTRY_PUSH: Image pushed to registry with verification
[2026-03-26 14:13:03] ✅ KUBERNETES_DEPLOYMENT: Manifest applied and deployment restarted
[2026-03-26 14:13:03] 🔄 KUBERNETES_VERIFICATION: In progress - verifying pods are ready
[2026-03-26 14:13:03] ⏳ INGRESS_SETUP: Pending - will verify external access
[2026-03-26 14:13:03] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-26 14:13:03] Verifying pod status reaches Running state...
[2026-03-26 14:13:03] Checking pod status after deployment restart... (attempt 1/20)
[2026-03-26 14:13:03] Pod not yet running. Current status:
NAME                            READY   STATUS              RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     CrashLoopBackOff    49 (4m23s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     ContainerCreating   0                0s
my-ag-ui-app-6dc4754dd5-6xztp   0/1     Completed           51               15h
[2026-03-26 14:13:03] Waiting for pod status change from ImagePullBackOff to Running...
[2026-03-26 14:13:06] Checking pod status after deployment restart... (attempt 2/20)
[2026-03-26 14:13:07] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     CrashLoopBackOff   49 (4m27s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running            0                4s
[2026-03-26 14:13:10] Checking pod status after deployment restart... (attempt 3/20)
[2026-03-26 14:13:10] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     CrashLoopBackOff   49 (4m31s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running            0                8s
[2026-03-26 14:13:14] Checking pod status after deployment restart... (attempt 4/20)
[2026-03-26 14:13:14] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     CrashLoopBackOff   49 (4m34s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running            0                11s
[2026-03-26 14:13:17] Checking pod status after deployment restart... (attempt 5/20)
[2026-03-26 14:13:18] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     CrashLoopBackOff   49 (4m38s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running            0                15s
[2026-03-26 14:13:21] Checking pod status after deployment restart... (attempt 6/20)
[2026-03-26 14:13:21] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     CrashLoopBackOff   49 (4m41s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running            0                18s
[2026-03-26 14:13:25] Checking pod status after deployment restart... (attempt 7/20)
[2026-03-26 14:13:25] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     CrashLoopBackOff   49 (4m45s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running            0                22s
[2026-03-26 14:13:28] Checking pod status after deployment restart... (attempt 8/20)
[2026-03-26 14:13:29] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     CrashLoopBackOff   49 (4m49s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running            0                26s
[2026-03-26 14:13:32] Checking pod status after deployment restart... (attempt 9/20)
[2026-03-26 14:13:32] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     CrashLoopBackOff   49 (4m53s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running            0                30s
[2026-03-26 14:13:36] Checking pod status after deployment restart... (attempt 10/20)
[2026-03-26 14:13:36] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     CrashLoopBackOff   49 (4m56s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running            0                33s
[2026-03-26 14:13:39] Checking pod status after deployment restart... (attempt 11/20)
[2026-03-26 14:13:40] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS      AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     CrashLoopBackOff   49 (5m ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running            0             37s
[2026-03-26 14:13:45] Checking pod status after deployment restart... (attempt 12/20)
[2026-03-26 14:13:45] Pod not yet running. Current status:
NAME                            READY   STATUS             RESTARTS        AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     CrashLoopBackOff   49 (5m6s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running            0               43s
[2026-03-26 14:13:51] Checking pod status after deployment restart... (attempt 13/20)
[2026-03-26 14:13:51] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     Running   50 (5m11s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running   0                48s
[2026-03-26 14:13:56] Checking pod status after deployment restart... (attempt 14/20)
[2026-03-26 14:13:57] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     Running   50 (5m17s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running   0                54s
[2026-03-26 14:14:02] Checking pod status after deployment restart... (attempt 15/20)
[2026-03-26 14:14:02] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     Running   50 (5m23s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running   0                60s
[2026-03-26 14:14:08] Checking pod status after deployment restart... (attempt 16/20)
[2026-03-26 14:14:08] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     Running   50 (5m28s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running   1 (5s ago)       65s
[2026-03-26 14:14:13] Checking pod status after deployment restart... (attempt 17/20)
[2026-03-26 14:14:14] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     Running   50 (5m34s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running   1 (11s ago)      71s
[2026-03-26 14:14:19] Checking pod status after deployment restart... (attempt 18/20)
[2026-03-26 14:14:19] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     Running   50 (5m40s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running   1 (17s ago)      77s
[2026-03-26 14:14:25] Checking pod status after deployment restart... (attempt 19/20)
[2026-03-26 14:14:25] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     Running   50 (5m45s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running   1 (22s ago)      82s
[2026-03-26 14:14:30] Checking pod status after deployment restart... (attempt 20/20)
[2026-03-26 14:14:31] Pod not yet running. Current status:
NAME                            READY   STATUS    RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     Running   50 (5m51s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running   1 (28s ago)      88s
[2026-03-26 14:14:31] INFO: Never observed ImagePullBackOff status (normal for registry-based deployments)
[2026-03-26 14:14:31]        With registry approach, images are readily available so pods may start directly
[2026-03-26 14:14:31] ERROR: Pod did not reach Running status after deployment restart
[2026-03-26 14:14:31] Final pod status:
NAME                            READY   STATUS    RESTARTS         AGE
my-ag-ui-app-65c69d78c4-j97bz   0/1     Running   50 (5m51s ago)   15h
my-ag-ui-app-6b6b8bf7c7-zmkdh   0/1     Running   1 (28s ago)      88s
[2026-03-26 14:14:31] Pod details for debugging:
Name:             my-ag-ui-app-65c69d78c4-j97bz
Namespace:        default
Priority:         0
Service Account:  default
Node:             my-ag-ui-app-k8s/10.237.212.68
Start Time:       Wed, 25 Mar 2026 22:43:37 -0400
Labels:           app=my-ag-ui-app
                  pod-template-hash=65c69d78c4
Annotations:      cni.projectcalico.org/containerID: e4e5fc4729d2971d847cacda73dc9d60c8ec7e63d8bf50b3f63b2863254f11b9
                  cni.projectcalico.org/podIP: 10.1.217.11/32
                  cni.projectcalico.org/podIPs: 10.1.217.11/32
                  kubectl.kubernetes.io/restartedAt: 2026-03-25T22:43:36-04:00
Status:           Running
IP:               10.1.217.11
IPs:
  IP:           10.1.217.11
Controlled By:  ReplicaSet/my-ag-ui-app-65c69d78c4
Containers:
  my-ag-ui-app:
    Container ID:   containerd://142dc4177e0965b5710ff85be328f82b437018783ff4d7045831dc61eb3b8485
    Image:          localhost:32000/my-ag-ui-app:latest
    Image ID:       localhost:32000/my-ag-ui-app@sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f
    Port:           3000/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Thu, 26 Mar 2026 14:13:50 -0400
    Last State:     Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Thu, 26 Mar 2026 14:07:50 -0400
      Finished:     Thu, 26 Mar 2026 14:08:40 -0400
    Ready:          False
    Restart Count:  50
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
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-xqz9j (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  kube-api-access-xqz9j:
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
  Type     Reason   Age                  From     Message
  ----     ------   ----                 ----     -------
  Warning  BackOff  81s (x555 over 15h)  kubelet  Back-off restarting failed container my-ag-ui-app in pod my-ag-ui-app-65c69d78c4-j97bz_default(c07be89b-5dfd-4ade-ab20-42f70df76f37)
  Normal   Pulling  41s (x51 over 15h)   kubelet  Pulling image "localhost:32000/my-ag-ui-app:latest"


Name:             my-ag-ui-app-6b6b8bf7c7-zmkdh
Namespace:        default
Priority:         0
Service Account:  default
Node:             my-ag-ui-app-k8s/10.237.212.68
Start Time:       Thu, 26 Mar 2026 14:13:03 -0400
Labels:           app=my-ag-ui-app
                  pod-template-hash=6b6b8bf7c7
Annotations:      cni.projectcalico.org/containerID: 294f2bb356f44360a45049b1d463f969e9fe5c7b7f98909c42e7aeee6cb68e5d
                  cni.projectcalico.org/podIP: 10.1.217.20/32
                  cni.projectcalico.org/podIPs: 10.1.217.20/32
                  kubectl.kubernetes.io/restartedAt: 2026-03-26T14:13:03-04:00
Status:           Running
IP:               10.1.217.20
IPs:
  IP:           10.1.217.20
Controlled By:  ReplicaSet/my-ag-ui-app-6b6b8bf7c7
Containers:
  my-ag-ui-app:
    Container ID:   containerd://d9891c4aa66344644dff67736cb169bc0e31d6933a0607164b7c18a8834dcf2f
    Image:          localhost:32000/my-ag-ui-app:latest
    Image ID:       localhost:32000/my-ag-ui-app@sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f
    Port:           3000/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Thu, 26 Mar 2026 14:14:03 -0400
    Last State:     Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Thu, 26 Mar 2026 14:13:04 -0400
      Finished:     Thu, 26 Mar 2026 14:14:03 -0400
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
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-k6h2x (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  kube-api-access-k6h2x:
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
  Normal   Scheduled  88s                default-scheduler  Successfully assigned default/my-ag-ui-app-6b6b8bf7c7-zmkdh to my-ag-ui-app-k8s
  Normal   Pulled     88s                kubelet            Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 95ms (95ms including waiting). Image size: 263041608 bytes.
  Normal   Pulling    28s (x2 over 88s)  kubelet            Pulling image "localhost:32000/my-ag-ui-app:latest"
  Normal   Created    28s (x2 over 88s)  kubelet            Created container: my-ag-ui-app
  Normal   Started    28s (x2 over 87s)  kubelet            Started container my-ag-ui-app
  Warning  Unhealthy  28s (x3 over 48s)  kubelet            Liveness probe failed: HTTP probe failed with statuscode: 404
  Normal   Killing    28s                kubelet            Container my-ag-ui-app failed liveness probe, will be restarted
  Normal   Pulled     28s                kubelet            Successfully pulled image "localhost:32000/my-ag-ui-app:latest" in 93ms (93ms including waiting). Image size: 263041608 bytes.
  Warning  Unhealthy  1s (x17 over 80s)  kubelet            Readiness probe failed: HTTP probe failed with statuscode: 404
[2026-03-26 14:14:32] ERROR TYPE: General pod startup failure - using generic error handling
[2026-03-26 14:14:32] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-26 14:14:32]                           KUBERNETES ERROR
[2026-03-26 14:14:32] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-26 14:14:32] ERROR CODE: 203
[2026-03-26 14:14:32] ERROR SUMMARY: 126
[2026-03-26 14:14:32] ═══════════════════════════════════════════════════════════════════════════════
[2026-03-26 14:14:32] QUICK FIX: Pod did not reach Running status after deployment restart
[2026-03-26 14:14:32] ═══════════════════════════════════════════════════════════════════════════════
ERROR: Failed to deploy to Kubernetes (Step 6)
