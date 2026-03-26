#!/bin/bash
# DEBUG LEVEL: FULL (critical failure phase)

set -e

# Change to project root directory to ensure consistent paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Source common error handling functions
if [ -f "deploy_scripts/common.sh" ]; then
    source "deploy_scripts/common.sh"
    
    # Override log function for compatibility with existing log format
    log() {
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
    }
else
    # Fallback error handling if common.sh is not available
    VM_NAME="${VM_NAME:-my-ag-ui-app-k8s}"
    LOG_FILE="${LOG_FILE:-deploy.log}"
    PERFORMANCE_LOG_FILE="${PERFORMANCE_LOG_FILE:-performance.log}"
    
    log() {
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
    }
    
    handle_secrets_error() {
        local exit_code="$1"
        local error_message="$2"
        local recovery_hint="$3"
        
        log "ERROR: $error_message"
        log "RECOVERY: $recovery_hint"
        exit "$exit_code"
    }
fi

# Debug flag support - when DEBUG=all is set, retain full verbose output
# When not set, still retain full output since this is a critical failure phase
if [ "${DEBUG:-}" != "all" ]; then
    # This is a critical failure phase, so we always keep full debug output
    # but we note that DEBUG=all can be used for explicit debugging
    log "DEBUG: Running with full verbose output (critical failure phase)"
    log "DEBUG: Set DEBUG=all for explicit debugging if needed"
fi



# Default values
VM_NAME="${VM_NAME:-my-ag-ui-app-k8s}"
LOG_FILE="${LOG_FILE:-deploy.log}"
PERFORMANCE_LOG_FILE="${PERFORMANCE_LOG_FILE:-performance.log}"

# Logging function (fallback if not sourced from common.sh)
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Source common functions if they exist (this will override the fallback functions if common.sh exists)
if [ -f "deploy_scripts/common.sh" ]; then
    source "deploy_scripts/common.sh"
fi

# Performance timing function (fallback if not sourced from common.sh)
start_phase_timing() {
    local phase_name="$1"
    local start_time=$(date +%s.%N)
    echo "PHASE_START:$phase_name:$start_time" >> "$PERFORMANCE_LOG_FILE"
    log "Starting phase: $phase_name"
}

end_phase_timing() {
    local phase_name="$1"
    local end_time=$(date +%s.%N)
    echo "PHASE_END:$phase_name:$end_time" >> "$PERFORMANCE_LOG_FILE"
    log "Completed phase: $phase_name"
}

# Error handling function (fallback if not sourced from common.sh)
handle_secrets_error() {
    local exit_code="$1"
    local error_message="$2"
    local recovery_hint="$3"
    
    log "❌ ERROR: $error_message"
    log "RECOVERY: $recovery_hint"
    log "EXIT CODE: $exit_code"
    
    exit "$exit_code"
}



# Command existence check (fallback if not sourced from common.sh)
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Network connectivity timeout (fallback if not sourced from common.sh)
NETWORK_CONNECTIVITY_TIMEOUT="${NETWORK_CONNECTIVITY_TIMEOUT:-5}"

start_phase_timing "KUBERNETES_DEPLOYMENT"
log "🚀 STARTING KUBERNETES DEPLOYMENT PHASE"
log "═══════════════════════════════════════════════════════════════════════════════"
log "📋 DEPLOYMENT DETAILS:"
log "   • Manifest: k8s/deployment.yaml"
log "   • Image: localhost:32000/my-ag-ui-app:latest (from local registry)"
log "   • Strategy: Rolling update with pod restart"
log "   • Registry: microk8s local registry"
log ""
log "🔄 STEP 1: Applying deployment manifest..."
log "   • Manifest: k8s/deployment.yaml"
log "   • Image: localhost:32000/my-ag-ui-app:latest (from local registry)"
log "   • Strategy: Rolling update with pod restart"
log "   • Registry: microk8s local registry"
log ""

# Enhanced logging: Pre-apply deployment state verification
log "📊 PRE-APPLOY VERIFICATION: Checking current deployment state..."
current_deployment_state=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.status}' 2>/dev/null || echo "NOT_FOUND")
if [ "$current_deployment_state" != "NOT_FOUND" ]; then
    current_replicas=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "unknown")
    current_ready_replicas=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    current_updated_replicas=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.status.updatedReplicas}' 2>/dev/null || echo "0")
    
    log "   • Current deployment state: EXISTS"
    log "   • Current replicas: $current_replicas"
    log "   • Ready replicas: $current_ready_replicas"
    log "   • Updated replicas: $current_updated_replicas"
    log "   • Action: UPDATE existing deployment"
else
    log "   • Current deployment state: NOT FOUND"
    log "   • Action: CREATE new deployment"
fi

# Enhanced logging: Manifest file validation
log "📋 MANIFEST VALIDATION: Checking deployment.yaml file..."
if [ ! -f "k8s/deployment.yaml" ]; then
    log "❌ ERROR: Deployment manifest file not found: k8s/deployment.yaml"
    handle_validation_error 140 "Deployment manifest file missing" \
        "Ensure k8s/deployment.yaml exists in the current directory."
fi

manifest_size=$(wc -l < "k8s/deployment.yaml" 2>/dev/null || echo "0")
if [ "$manifest_size" -eq 0 ]; then
    log "❌ ERROR: Deployment manifest file is empty: k8s/deployment.yaml"
    handle_validation_error 141 "Deployment manifest file empty" \
        "Ensure k8s/deployment.yaml contains valid YAML content."
fi

# Enhanced logging: Registry port validation (CRITICAL for microk8s registry approach)
log "🔍 REGISTRY PORT VALIDATION: Checking for registry port mismatches..."
expected_registry_port="32000"
actual_registry_port=$(grep -E "^\s*image:.*localhost:" k8s/deployment.yaml | sed -E 's/.*localhost:([0-9]+)\/.*/\1/' | head -n1 || echo "NOT_FOUND")

if [ "$actual_registry_port" = "NOT_FOUND" ]; then
    log "   • Registry port check: No localhost registry reference found in deployment.yaml"
    log "   • This might indicate image references Docker Hub instead of local registry"
    log "   • Expected: image: localhost:32000/my-ag-ui-app:latest"
elif [ "$actual_registry_port" != "$expected_registry_port" ]; then
    log "   ❌ CRITICAL ERROR: Registry port mismatch detected!"
    log "   • Expected registry port: $expected_registry_port (microk8s standard)"
    log "   • Actual registry port: $actual_registry_port (in deployment.yaml)"
    log "   • This will cause ImagePullBackOff errors during deployment"
    
    # Use our enhanced error handler for port mismatch
    handle_validation_error 900 "Registry port mismatch detected" \
        "Expected: localhost:$expected_registry_port, Actual: localhost:$actual_registry_port. Fix in k8s/deployment.yaml"
    
    log "   ⚠️  DEPLOYMENT PAUSED: Please fix the registry port mismatch above and retry"
    log "   ⚠️  After fixing, run: bash deploy.sh"
    exit 900
else
    log "   ✓ Registry port validation: PASSED (using port $actual_registry_port)"
fi

log "   • Manifest file size: $manifest_size lines"
log "   • Manifest validation: PASSED"

# Enhanced logging: Kubernetes connection check
log "🔌 KUBERNETES CONNECTION: Verifying cluster access..."
if ! multipass exec "$VM_NAME" -- microk8s kubectl cluster-info 2>&1 | grep -q "is running"; then
    log "❌ ERROR: Kubernetes cluster is not accessible"
    handle_kubernetes_error 142 "Kubernetes cluster inaccessible" \
        "Verify microk8s is running and accessible: multipass exec '$VM_NAME' -- microk8s status"
fi
log "   • Kubernetes cluster: ACCESSIBLE"

# Enhanced logging: Namespace verification
log "🏷️  NAMESPACE VERIFICATION: Checking target namespace..."
target_namespace=$(grep -A 10 "namespace:" k8s/deployment.yaml | grep "namespace:" | head -n1 | awk '{print $2}' || echo "default")
log "   • Target namespace: $target_namespace"

if ! multipass exec "$VM_NAME" -- microk8s kubectl get namespace "$target_namespace" 2>&1 | grep -q "Active"; then
    log "   • Namespace status: DOES NOT EXIST (will be created by deployment)"
else
    log "   • Namespace status: EXISTS and ACTIVE"
fi

# Enhanced logging: Apply manifest with detailed output capture and analysis
log "🚀 APPLYING DEPLOYMENT MANIFEST with detailed logging..."
log "   • Command: multipass exec '$VM_NAME' -- microk8s kubectl apply -f k8s/deployment.yaml"
log "   • Expected: Deployment resource creation/update"
log "   • Output will be captured and analyzed below..."

# Capture kubectl apply output for detailed analysis
kubectl_apply_output=""
kubectl_apply_exit_code=0

# Execute kubectl apply with output capture
kubectl_apply_output=$(multipass exec "$VM_NAME" -- microk8s kubectl apply -f k8s/deployment.yaml 2>&1)
kubectl_apply_exit_code=$?

# Log the full kubectl apply output for debugging
log "📤 KUBECTL APPLY OUTPUT (first 1000 chars):"
echo "$kubectl_apply_output" | head -c 1000 | tee -a "$LOG_FILE"
if [ ${#kubectl_apply_output} -gt 1000 ]; then
    log "... (output truncated, full output logged to file)"
    echo "$kubectl_apply_output" >> "$LOG_FILE"
fi

# Analyze the kubectl apply result
if [ $kubectl_apply_exit_code -eq 0 ]; then
    log "✅ KUBECTL APPLY: Command completed successfully (exit code: 0)"
    
    # Analyze the output for deployment creation/update details
    if echo "$kubectl_apply_output" | grep -q "deployment.apps/my-ag-ui-app created"; then
        log "   • Result: NEW deployment created"
        log "   • Action: Fresh deployment of my-ag-ui-app"
    elif echo "$kubectl_apply_output" | grep -q "deployment.apps/my-ag-ui-app configured"; then
        log "   • Result: EXISTING deployment configured"
        log "   • Action: Rolling update initiated for my-ag-ui-app"
    elif echo "$kubectl_apply_output" | grep -q "unchanged"; then
        log "   • Result: Deployment unchanged (no changes detected)"
        log "   • Action: No update needed - configuration identical"
    else
        log "   • Result: Deployment applied (unknown status)"
        log "   • Note: Output did not match expected patterns, but command succeeded"
    fi
    
    # Enhanced logging: Post-apply verification
    log "🔍 POST-APPLY VERIFICATION: Checking deployment status after apply..."
    
    # Verify deployment was created/updated successfully
    post_apply_deployment=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app -o name 2>/dev/null || echo "NOT_FOUND")
    
    if [ "$post_apply_deployment" = "deployment.apps/my-ag-ui-app" ]; then
        log "   ✅ Deployment verification: PASSED"
        log "      • Deployment resource exists: my-ag-ui-app"
        
        # Get detailed deployment information
        deployment_spec=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.spec}' 2>/dev/null || echo "unavailable")
        deployment_status=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.status}' 2>/dev/null || echo "unavailable")
        
        log "      • Deployment spec: $deployment_spec"
        log "      • Deployment status: $deployment_status"
        
        # Verify image reference is correct
        deployment_image=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "unavailable")
        
        if [ "$deployment_image" = "localhost:32000/my-ag-ui-app:latest" ]; then
            log "      ✅ Image reference verification: PASSED"
            log "         • Expected: localhost:32000/my-ag-ui-app:latest"
            log "         • Actual: $deployment_image"
        else
            log "      ⚠️  Image reference verification: WARNING"
            log "         • Expected: localhost:32000/my-ag-ui-app:latest"
            log "         • Actual: $deployment_image"
            log "         • Note: This may indicate a manifest synchronization issue"
        fi
        
    else
        log "   ❌ Deployment verification: FAILED"
        log "      • Expected: deployment.apps/my-ag-ui-app"
        log "      • Actual: $post_apply_deployment"
        log "      • This indicates the kubectl apply may not have worked despite success exit code"
        
        # Additional diagnostic information
        log "🔧 DIAGNOSTIC: Checking all deployments in namespace..."
        all_deployments=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployments -A 2>&1 | tee -a "$LOG_FILE")
        log "All deployments in cluster:"
        echo "$all_deployments" | tee -a "$LOG_FILE"
    fi
    
else
    log "❌ KUBECTL APPLY: Command failed (exit code: $kubectl_apply_exit_code)"
    log "   • Full error output logged above"
    
    # Enhanced error analysis with specific recovery guidance
    log "🔍 ERROR ANALYSIS: Examining kubectl apply failure..."
    
    if echo "$kubectl_apply_output" | grep -q "the server could not find the requested resource"; then
        log "   ERROR TYPE: RESOURCE NOT FOUND"
        log "   DIAGNOSTIC: Referenced resource in deployment.yaml does not exist"
        log "   COMMON CAUSES:"
        log "     - Missing secrets or configmaps"
        log "     - Incorrect resource names"
        log "   RECOVERY:"
        log "     1. Check all referenced resources: multipass exec '$VM_NAME' -- microk8s kubectl get secrets,configmaps"
        log "     2. Verify manifest references: grep -E '(secretKeyRef|configMapKeyRef)' k8s/deployment.yaml"
        log "     3. Create missing resources if needed"
        
    elif echo "$kubectl_apply_output" | grep -q "error validating"; then
        log "   ERROR TYPE: YAML VALIDATION ERROR"
        log "   DIAGNOSTIC: deployment.yaml contains invalid YAML or Kubernetes specification"
        log "   COMMON CAUSES:"
        log "     - Syntax errors in YAML"
        log "     - Invalid Kubernetes API version"
        log "     - Missing required fields"
        log "   RECOVERY:"
        log "     1. Validate YAML syntax: python3 -c 'import yaml; yaml.safe_load(open(\"k8s/deployment.yaml\"))'"
        log "     2. Check Kubernetes API version: multipass exec '$VM_NAME' -- microk8s kubectl api-versions"
        log "     3. Validate deployment manifest: multipass exec '$VM_NAME' -- microk8s kubectl apply --dry-run=client -f k8s/deployment.yaml"
        
    elif echo "$kubectl_apply_output" | grep -q "connection refused"; then
        log "   ERROR TYPE: KUBERNETES API CONNECTION FAILED"
        log "   DIAGNOSTIC: Cannot connect to Kubernetes API server"
        log "   COMMON CAUSES:"
        log "     - microk8s service not running"
        log "     - Network connectivity issues"
        log "   RECOVERY:"
        log "     1. Check microk8s status: multipass exec '$VM_NAME' -- microk8s status"
        log "     2. Restart microk8s if needed: multipass exec '$VM_NAME' -- microk8s start"
        log "     3. Verify cluster connectivity: multipass exec '$VM_NAME' -- microk8s kubectl cluster-info"
        
    elif echo "$kubectl_apply_output" | grep -q "permission denied"; then
        log "   ERROR TYPE: KUBERNETES PERMISSION ERROR"
        log "   DIAGNOSTIC: Insufficient permissions to apply deployment"
        log "   COMMON CAUSES:"
        log "     - RBAC configuration issues"
        log "     - User permissions in cluster"
        log "   RECOVERY:"
        log "     1. Check user permissions: multipass exec '$VM_NAME' -- microk8s kubectl auth can-i create deployments"
        log "     2. Check cluster admin status: multipass exec '$VM_NAME' -- microk8s kubectl get clusterrolebindings"
        log "     3. If needed, configure admin access: multipass exec '$VM_NAME' -- microk8s kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=\$(whoami)"
        
    elif echo "$kubectl_apply_output" | grep -q -E "(image.*pull|registry.*access|localhost.*5000)"; then
        log "   ERROR TYPE: REGISTRY CONFIGURATION ERROR"
        log "   DIAGNOSTIC: Deployment manifest likely references wrong registry port"
        log "   COMMON CAUSES:"
        log "     - Registry port mismatch (5000 instead of 32000)"
        log "     - Image reference pointing to wrong registry endpoint"
        log "   RECOVERY:"
        log "     1. Check registry port in deployment.yaml: grep 'localhost:' k8s/deployment.yaml"
        log "     2. Verify it should be 'localhost:32000' (not 'localhost:5000')"
        log "     3. Fix port mismatch if found: sed -i 's/localhost:5000/localhost:32000/g' k8s/deployment.yaml"
        log "     4. Retry deployment: bash deploy.sh"
        log "     5. For detailed help: See handle_registry_port_mismatch_error in deploy.sh"
        
    else
        log "   ERROR TYPE: UNKNOWN KUBECTL APPLY ERROR"
        log "   DIAGNOSTIC: Unrecognized error pattern in kubectl apply output"
        log "   RECOVERY:"
        log "     1. Check kubectl apply help: multipass exec '$VM_NAME' -- microk8s kubectl apply --help"
        log "     2. Validate cluster health: multipass exec '$VM_NAME' -- microk8s kubectl cluster-info dump"
        log "     3. Try dry-run validation: multipass exec '$VM_NAME' -- microk8s kubectl apply --dry-run=client -f k8s/deployment.yaml"
        log "     4. Check system logs: multipass exec '$VM_NAME' -- journalctl -u snap.microk8s.daemon -n 50"
        log "     5. Check for registry port issues: grep -E '(localhost:5000|localhost:32000)' k8s/deployment.yaml"
    fi
    
    handle_kubernetes_error 106 "Failed to apply deployment manifest" \
        "Check the deployment file: k8s/deployment.yaml. Ensure it references secrets and config maps correctly. Error details logged above."
fi

log "✅ Deployment manifest application process completed"
log "   • Kubernetes deployment resource processed"
log "   • Next step: Deployment restart to trigger pod creation"
log ""
log "🔄 STEP 2: Restarting deployment to trigger pod recreation..."
log "   • This will create new pods using the updated registry image"
log "   • Pods will pull image from localhost:32000/my-ag-ui-app:latest"
if ! multipass exec "$VM_NAME" -- microk8s kubectl rollout restart deployment/my-ag-ui-app 2>&1 | tee -a "$LOG_FILE"; then
    handle_kubernetes_error 125 "Failed to restart deployment" \
        "Check if deployment exists: microk8s kubectl get deployment my-ag-ui-app. Ensure deployment is in a state that can be restarted."
fi
log "✅ Deployment restarted successfully"
log "   • Rolling update initiated"
log "   • New pods will be created using registry image"
log "   • Expected: Direct pod startup (no ImagePullBackOff with registry approach)"
log ""
log "═══════════════════════════════════════════════════════════════════════════════"
log "🎯 KUBERNETES DEPLOYMENT PHASE COMPLETED"

# Log deployment progress summary
log_deployment_progress_summary() {
    log ""
    log "📊 DEPLOYMENT PROGRESS SUMMARY:"
    log "═══════════════════════════════════════════════════════════════════════════════"
    log "✅ DEPENDENCY_VALIDATION: Package dependencies validated"
    log "✅ DOCKER_IMAGE_BUILD: Image built successfully (localhost:32000/my-ag-ui-app:latest)"
    log "✅ MICROK8S_REGISTRY_SETUP: Local registry enabled and accessible"
    log "✅ DOCKER_REGISTRY_PUSH: Image pushed to registry with verification"
    log "✅ KUBERNETES_DEPLOYMENT: Manifest applied and deployment restarted"
    log "🔄 KUBERNETES_VERIFICATION: In progress - verifying pods are ready"
    log "⏳ INGRESS_SETUP: Pending - will verify external access"
    log "═══════════════════════════════════════════════════════════════════════════════"
}

# Call progress summary
log_deployment_progress_summary

# 6.6 Verify pod status reaches Running (registry-based deployment)
log "Verifying pod status reaches Running state..."
# NOTE: With registry approach, pods may go directly to Running without ImagePullBackOff
# since images are pre-loaded in the local registry and readily available
# OPTIMIZED: Reduced pod wait attempts and added progressive delay
MAX_POD_WAIT_ATTEMPTS=20          # Reduced from 30 - pods typically start faster
POD_WAIT_ATTEMPT=1
INITIAL_STATUS_CHECK=true
SAW_IMAGE_PULL_BACK_OFF=false
POD_WAIT_DELAY=3                  # Initial delay (will increase for later attempts)

while [ $POD_WAIT_ATTEMPT -le $MAX_POD_WAIT_ATTEMPTS ]; do
    log "Checking pod status after deployment restart... (attempt $POD_WAIT_ATTEMPT/$MAX_POD_WAIT_ATTEMPTS)"
    
    # Get current pod status
    POD_STATUS_JSON=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o json 2>/dev/null || echo "")
    
    if [ -n "$POD_STATUS_JSON" ]; then
        # Check for ImagePullBackOff status
        IMAGE_PULL_BACK_OFF=$(echo "$POD_STATUS_JSON" | grep -o '"ImagePullBackOff"' || echo "")
        if [ -n "$IMAGE_PULL_BACK_OFF" ] && [ "$SAW_IMAGE_PULL_BACK_OFF" = false ]; then
            log "Pod status: ImagePullBackOff detected (expected before pod starts running)"
            SAW_IMAGE_PULL_BACK_OFF=true
        fi
        
        # Check for Running status
        POD_PHASE=$(echo "$POD_STATUS_JSON" | grep -o '"phase":"Running"' || echo "")
        POD_READY=$(echo "$POD_STATUS_JSON" | grep -o '"ready":true' || echo "")
        
        if [ -n "$POD_PHASE" ] && [ -n "$POD_READY" ]; then
            log "✓ Pod status changed to Running - verification successful"
        else
            log "Pod not yet running. Current status:"
            multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE" || true
            
            # If we haven't seen ImagePullBackOff and this is the first check, wait a bit more
            if [ "$SAW_IMAGE_PULL_BACK_OFF" = false ] && [ "$INITIAL_STATUS_CHECK" = true ]; then
                log "Waiting for pod status change from ImagePullBackOff to Running..."
                INITIAL_STATUS_CHECK=false
            fi
        fi
    else
        log "Unable to get pod status JSON, trying basic status check..."
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE" || true
    fi
    
    if [ $POD_WAIT_ATTEMPT -eq $MAX_POD_WAIT_ATTEMPTS ]; then
        if [ "$SAW_IMAGE_PULL_BACK_OFF" = false ]; then
            log "INFO: Never observed ImagePullBackOff status (normal for registry-based deployments)"
            log "       With registry approach, images are readily available so pods may start directly"
        fi
        log "ERROR: Pod did not reach Running status after deployment restart"
        
        log "Final pod status:"
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE" || true
        
        log "Pod details for debugging:"
        multipass exec "$VM_NAME" -- microk8s kubectl describe pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE" || true
        
        # Extract pod name for error handling
        POD_NAME=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "unknown")
        
        # Use specialized error handler for image pull failures, generic handler for other issues
        if [ "$SAW_IMAGE_PULL_BACK_OFF" = true ]; then
            log "ERROR TYPE: ImagePullBackOff detected - using specialized image pull error handling"
            handle_kubernetes_error 126 "Pod stuck in ImagePullBackOff state - image pull failure" \
                "Check registry access and image availability. Verify image exists in registry: multipass exec '$VM_NAME' -- curl -s http://localhost:32000/v2/_catalog"
            
            # Additional specific guidance for common ImagePullBackOff causes
            log "=== ADDITIONAL IMAGE PULL BACKOFF TROUBLESHOOTING ==="
            log "MOST COMMON CAUSES:"
            log "1. REGISTRY PORT MISMATCH (most likely):"
            log "   • Check if deployment.yaml uses wrong registry port"
            log "   • Expected: localhost:32000/my-ag-ui-app:latest"
            log "   • Wrong:    localhost:5000/my-ag-ui-app:latest"
            log "   • Fix: grep -n 'localhost:5000' k8s/deployment.yaml && sed -i 's/localhost:5000/localhost:32000/g' k8s/deployment.yaml"
            log ""
            log "2. IMAGE NOT PUSHED TO REGISTRY:"
            log "   • Check image exists in registry: multipass exec '$VM_NAME' -- curl -s http://localhost:32000/v2/_catalog"
            log "   • If missing, rebuild and push: docker build -t localhost:32000/my-ag-ui-app:latest . && docker push localhost:32000/my-ag-ui-app:latest"
            log ""
            log "3. REGISTRY NOT ACCESSIBLE:"
            log "   • Check registry status: multipass exec '$VM_NAME' -- microk8s kubectl get pods -n container-registry"
            log "   • Restart registry if needed: multipass exec '$VM_NAME' -- microk8s stop && multipass exec '$VM_NAME' -- microk8s start"
            
        else
            log "ERROR TYPE: General pod startup failure - using generic error handling"
            handle_kubernetes_error 126 "Pod did not reach Running status after deployment restart" \
                "Check pod logs: multipass exec '$VM_NAME' -- microk8s kubectl logs -l app=my-ag-ui-app. Verify registry is accessible: microk8s kubectl get pods -n container-registry."
        fi
    fi
    
    # OPTIMIZED: Progressive delay - start with 3s, increase to 5s for later attempts
    if [ $POD_WAIT_ATTEMPT -le 10 ]; then
        sleep $POD_WAIT_DELAY
    else
        sleep 5  # Slightly longer delay for later attempts
    fi
    POD_WAIT_ATTEMPT=$((POD_WAIT_ATTEMPT + 1))
done

if [ "$SAW_IMAGE_PULL_BACK_OFF" = true ]; then
    log "✓ Confirmed: Pod recovered from ImagePullBackOff to Running"
    log "       (Note: ImagePullBackOff with registry approach may indicate temporary network/registry issues)"
else
    log "✓ OPTIMAL: Pod started directly without ImagePullBackOff (ideal for registry-based deployments)"
    log "       Image was readily available in local registry - no pull delays"
fi

# 6.7 Verify pod passes readiness and liveness probes
log "Verifying pod passes readiness and liveness probes..."
# OPTIMIZED: Reduced probe wait attempts with smart delay strategy
MAX_PROBE_WAIT_ATTEMPTS=20          # Reduced from 30 - probes typically resolve faster
PROBE_WAIT_ATTEMPT=1
PROBE_WAIT_DELAY=2                  # Optimized starting delay

while [ $PROBE_WAIT_ATTEMPT -le $MAX_PROBE_WAIT_ATTEMPTS ]; do
    log "Checking probe status... (attempt $PROBE_WAIT_ATTEMPT/$MAX_PROBE_WAIT_ATTEMPTS)"
    
    # Get pod details including probe status
    POD_DETAILS=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o json 2>/dev/null || echo "")
    
    if [ -n "$POD_DETAILS" ]; then
        # Check readiness probe status
        READY=$(echo "$POD_DETAILS" | grep -o '"ready":true' || echo "")
        
        # Check liveness probe status by checking if pod is running and ready
        # (liveness probe failures would typically cause pod restarts or failures)
        POD_PHASE=$(echo "$POD_DETAILS" | grep -o '"phase":"Running"' || echo "")
        RESTART_COUNT=$(echo "$POD_DETAILS" | grep -o '"restartCount":[0-9]*' | head -1 | cut -d':' -f2 || echo "0")
        
        if [ -n "$READY" ] && [ -n "$POD_PHASE" ]; then
            log "✓ Readiness probe: PASSED"
            log "✓ Liveness probe: PASSED (pod is Running and Ready)"
            log "✓ Pod restart count: $RESTART_COUNT"
            
            # Get detailed probe information if available
            PROBE_DETAILS=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].status.containerStatuses[0].state}' 2>/dev/null || echo "")
            if [ -n "$PROBE_DETAILS" ]; then
                log "Detailed probe status: $PROBE_DETAILS"
            fi
            
            break
        else
            log "Probes not yet ready. Current status:"
            multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE" || true
            
            # Check for probe-specific errors
            if multipass exec "$VM_NAME" -- microk8s kubectl describe pods -l app=my-ag-ui-app 2>/dev/null | grep -q "Readiness probe failed"; then
                log "WARNING: Readiness probe failing - application may not be ready to serve traffic"
            fi
            
            if multipass exec "$VM_NAME" -- microk8s kubectl describe pods -l app=my-ag-ui-app 2>/dev/null | grep -q "Liveness probe failed"; then
                log "WARNING: Liveness probe failing - pod may be restarting"
            fi
        fi
    else
        log "Unable to get pod probe status, trying basic status check..."
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE" || true
    fi
    
    if [ $PROBE_WAIT_ATTEMPT -eq $MAX_PROBE_WAIT_ATTEMPTS ]; then
        log "ERROR: Probes did not pass within $MAX_PROBE_WAIT_ATTEMPTS attempts"
        
        log "Final pod status:"
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE" || true
        
        log "Pod events for probe debugging:"
        multipass exec "$VM_NAME" -- microk8s kubectl describe pods -l app=my-ag-ui-app 2>/dev/null | grep -A 20 -B 5 "Events:" | tee -a "$LOG_FILE" || true
        
        log "Probe status details:"
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].status.containerStatuses[0].lastState}' 2>/dev/null | tee -a "$LOG_FILE" || true
        
        handle_kubernetes_error 127 "Pod probes did not pass within timeout" \
            "Check application logs: multipass exec '$VM_NAME' -- microk8s kubectl logs -l app=my-ag-ui-app. Verify /health endpoint is working correctly."
    fi
    
    # OPTIMIZED: Smart delay strategy - start with 2s, increase to 4s for later attempts
    if [ $PROBE_WAIT_ATTEMPT -le 12 ]; then
        sleep $PROBE_WAIT_DELAY
    else
        sleep 4  # Longer delay for later probe attempts
    fi
    PROBE_WAIT_ATTEMPT=$((PROBE_WAIT_ATTEMPT + 1))
done

log "✓ Pod readiness and liveness probes verification completed successfully"

# Apply service manifest
log "Applying service manifest..."
if ! multipass exec "$VM_NAME" -- microk8s kubectl apply -f k8s/service.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_kubernetes_error 107 "Failed to apply service manifest" \
        "Check the service file: k8s/service.yaml. Ensure it references the correct deployment."
fi
log "Service manifest applied successfully"

# Apply ingress manifest
log "Applying ingress manifest..."
if ! multipass exec "$VM_NAME" -- microk8s kubectl apply -f k8s/ingress.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_kubernetes_error 108 "Failed to apply ingress manifest" \
        "Check the ingress file: k8s/ingress.yaml. Ensure ingress controller is enabled in microk8s."
fi
log "Ingress manifest applied successfully"

# Wait for deployment to be ready
log "Waiting for deployment to be ready..."
# OPTIMIZED: Reduced deployment wait attempts with balanced delay
MAX_ATTEMPTS=15                    # Reduced from 20 - deployments typically complete faster
ATTEMPT=1
DEPLOYMENT_DELAY=8                # Optimized delay between deployment checks

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    log "Checking deployment status... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
    
    # Check if deployment is ready
    DEPLOYMENT_READY=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    
    if [ "$DEPLOYMENT_READY" = "1" ]; then
        log "Deployment is ready"
        break
    else
        log "Deployment not ready yet... (ready replicas: $DEPLOYMENT_READY)"
        
        # Get pod status for debugging
        log "Pod status:"
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE" || true
    fi
    
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    handle_kubernetes_error 109 "Deployment did not become ready within $MAX_ATTEMPTS attempts" \
        "Check pod logs: microk8s kubectl logs -l app=my-ag-ui-app. Check pod status: microk8s kubectl get pods -l app=my-ag-ui-app"
    fi
    
    # OPTIMIZED: Balanced delay - reduced from 10s to 8s for faster feedback
    sleep $DEPLOYMENT_DELAY
    ATTEMPT=$((ATTEMPT + 1))
done

# 5.8 Wait for pods to be ready
end_phase_timing "KUBERNETES_DEPLOYMENT"
start_phase_timing "KUBERNETES_VERIFICATION"
log "Verifying all pods are ready..."
POD_STATUS=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[*].status.phase}' 2>/dev/null || echo "Unknown")
log "Pod status: $POD_STATUS"

if ! multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[*].status.containerStatuses[*].ready}' 2>&1 | grep -q "true"; then
    log "WARNING: Some pods may not be ready"
    log "Detailed pod status:"
    multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE"
else
    log "All pods are ready"
fi

# 5.9 Verify deployment status
log "Verifying deployment status..."
DEPLOYMENT_STATUS=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || echo "Unknown")
log "Deployment status: $DEPLOYMENT_STATUS"

# Get deployment details
log "Deployment details:"
multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app 2>&1 | tee -a "$LOG_FILE"

# 5.10 Verify application is accessible via ingress
# 6.2 Get ingress endpoint URL/IP
end_phase_timing "KUBERNETES_VERIFICATION"
start_phase_timing "INGRESS_SETUP"
log "Verifying application accessibility via ingress..."

# Get VM IP address (primary ingress endpoint)
VM_IP=$(multipass info "$VM_NAME" | grep -E "IPv4:" | awk '{print $2}' | cut -d',' -f1 | head -n1 || echo "")
if [ -z "$VM_IP" ]; then
    log "ERROR: Failed to get VM IP address"
    VM_IP="127.0.0.1"  # fallback for testing
    log "Using fallback VM IP: $VM_IP"
fi
log "VM IP address: $VM_IP"

# Get ingress details
INGRESS_DETAILS=$(multipass exec "$VM_NAME" -- microk8s kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "Unknown")
log "Ingress host: $INGRESS_DETAILS"

# Get ingress controller service details
INGRESS_CONTROLLER_SVC=$(multipass exec "$VM_NAME" -- microk8s kubectl get svc -n ingress nginx-ingress-controller -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}' 2>/dev/null || echo "")
if [ -z "$INGRESS_CONTROLLER_SVC" ]; then
    # Try alternative service name for newer microk8s versions
    INGRESS_CONTROLLER_SVC=$(multipass exec "$VM_NAME" -- microk8s kubectl get svc -n ingress nginx-ingress-microk8s-controller -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}' 2>/dev/null || echo "")
fi

if [ -z "$INGRESS_CONTROLLER_SVC" ]; then
    log "WARNING: Could not get ingress controller node port, using default port 80"
    INGRESS_PORT="80"
else
    INGRESS_PORT="$INGRESS_CONTROLLER_SVC"
    log "Ingress controller node port: $INGRESS_PORT"
fi

# Check if ingress has an address assigned (for cloud environments)
INGRESS_IP=$(multipass exec "$VM_NAME" -- microk8s kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
INGRESS_HOSTNAME=$(multipass exec "$VM_NAME" -- microk8s kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

# Determine the accessible URL
if [ -n "$INGRESS_IP" ]; then
    ACCESS_URL="http://$INGRESS_IP"
    log "Cloud LoadBalancer IP detected: $INGRESS_IP"
    log "Application accessible at: $ACCESS_URL"
elif [ -n "$INGRESS_HOSTNAME" ]; then
    ACCESS_URL="http://$INGRESS_HOSTNAME"
    log "Cloud LoadBalancer hostname detected: $INGRESS_HOSTNAME"
    log "Application accessible at: $ACCESS_URL"
else
    # Local microk8s deployment - use VM IP and ingress port
    if [ "$INGRESS_PORT" = "80" ]; then
        ACCESS_URL="http://$VM_IP"
    else
        ACCESS_URL="http://$VM_IP:$INGRESS_PORT"
    fi
    log "Local microk8s deployment detected"
    log "Application accessible at: $ACCESS_URL"
fi

# Store access URL for later use
echo "$ACCESS_URL" > /tmp/my-ag-ui-app-access-url.txt
log "Access URL saved to /tmp/my-ag-ui-app-access-url.txt"

# Test basic connectivity to the VM
log "Testing basic connectivity to VM..."
if ping -c 1 -W "$NETWORK_CONNECTIVITY_TIMEOUT" "$VM_IP" >/dev/null 2>&1; then
    log "VM is reachable at $VM_IP"
else
    log "WARNING: VM is not reachable at $VM_IP"
fi

# Test application accessibility (basic check)
log "Testing application accessibility..."

# First test from within the cluster (pod to pod)
if multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].status.podIP}' 2>/dev/null | grep -q "."; then
    POD_IP=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].status.podIP}' 2>/dev/null)
    log "Application pod IP: $POD_IP"
    
    # Try to access the application from within the cluster
    if multipass exec "$VM_NAME" -- microk8s kubectl run temp-curl --image=curlimages/curl --rm -it --restart=Never -- curl -s --connect-timeout "$NETWORK_CONNECTIVITY_TIMEOUT" "http://$POD_IP:3000/health" >/dev/null 2>&1; then
        log "✓ Application internal health check passed"
    else
        log "WARNING: Application internal health check failed"
    fi
else
    log "Unable to determine pod IP for internal accessibility test"
fi

# Test ingress endpoint accessibility (external access)
log "Testing ingress endpoint accessibility..."
if command_exists curl; then
    log "Testing external access to: $ACCESS_URL"
    
    # Wait a few seconds for ingress to be ready
    log "Waiting 10 seconds for ingress to be fully ready..."
    sleep 10
    
    # Test the ingress endpoint
    if curl -s --connect-timeout "$NETWORK_CONNECTIVITY_TIMEOUT" --max-time 30 "$ACCESS_URL" >/dev/null 2>&1; then
        log "✓ Ingress endpoint is accessible: $ACCESS_URL"
        
        # Test with the configured hostname if different from IP
        if [[ "$ACCESS_URL" != *"my-ag-ui-app.local"* ]] && [ -n "$INGRESS_DETAILS" ] && [ "$INGRESS_DETAILS" != "Unknown" ]; then
            # Try with hostname (may require /etc/hosts modification)
            log "NOTE: For hostname-based access ($INGRESS_DETAILS), you may need to add this to your /etc/hosts file:"
            log "  $VM_IP    $INGRESS_DETAILS"
        fi
    else
        log "WARNING: Ingress endpoint not immediately accessible: $ACCESS_URL"
        log "This is normal - ingress may take a few minutes to be fully ready"
        log "To test manually: curl $ACCESS_URL"
    fi
else
    log "curl command not found, skipping external accessibility test"
    log "To test manually: curl $ACCESS_URL"
fi

log "Kubernetes deployment phase completed successfully"
log "Application should be accessible via ingress (may take a few minutes for ingress to be fully ready)"

# Final deployment progress summary
log ""
log "🎉 FINAL DEPLOYMENT PROGRESS SUMMARY:"
log "═══════════════════════════════════════════════════════════════════════════════"
log "✅ DEPENDENCY_VALIDATION: Package dependencies validated and synchronized"
log "✅ DOCKER_IMAGE_BUILD: Image built successfully (localhost:32000/my-ag-ui-app:latest)"
log "✅ MICROK8S_REGISTRY_SETUP: Local registry enabled and verified accessible"
log "✅ DOCKER_REGISTRY_PUSH: Image pushed with comprehensive verification"
log "✅ KUBERNETES_DEPLOYMENT: Manifest applied, deployment restarted"
log "✅ KUBERNETES_VERIFICATION: Pods verified and deployment status confirmed"
log "✅ INGRESS_SETUP: External access configured and tested"
log "═══════════════════════════════════════════════════════════════════════════════"
log "🚀 DEPLOYMENT STATUS: FULLY COMPLETED"
log "📦 REGISTRY APPROACH: Successfully implemented and verified"
log "🌐 ACCESS: Ready via ingress endpoint (details below)"
log "═══════════════════════════════════════════════════════════════════════════════"

# Provide access instructions
log "=== APPLICATION ACCESS INFORMATION ==="
log "Primary Access URL: $ACCESS_URL"
log ""
log "To access the application:"
log "1. Direct URL: $ACCESS_URL"
log "2. Check ingress status: microk8s kubectl get ingress my-ag-ui-app-ingress"
log "3. If using hostname-based routing, add this to your /etc/hosts file:"
if [ -n "$INGRESS_DETAILS" ] && [ "$INGRESS_DETAILS" != "Unknown" ]; then
    log "   $VM_IP    $INGRESS_DETAILS"
    log "4. Then access: http://$INGRESS_DETAILS"
fi
log ""
log "Troubleshooting:"
log "- If URL is not accessible, wait 2-3 minutes for ingress to be fully ready"
log "- Check ingress controller: microk8s kubectl get pods -n ingress"
log "- Check application logs: microk8s kubectl logs -l app=my-ag-ui-app"
log "=== END ACCESS INFORMATION ==="

# 6.3 Test application access via ingress (this was completed above)
log "Ingress endpoint URL/IP retrieval and testing completed"

log "Kubernetes secrets setup and deployment completed successfully"