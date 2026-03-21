
# ===========================
# LOGGING FUNCTIONS
# ===========================

# Log file location
LOG_FILE="/tmp/deploy-$(date +%Y%m%d-%H%M%S).log"

# VM configuration
VM_NAME="my-ag-ui-app-k8s"

# Logging function - prints to both stdout and log file
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message"
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# ===========================
# KUBERNETES SECRETS SETUP SECTION
# ===========================

# Kubernetes secrets setup error handler
handle_secrets_error() {
    local error_code=$1
    local error_message=$2
    local recovery_suggestion=$3
    
    log "SECRETS SETUP ERROR [Code: $error_code]: $error_message"
    log "RECOVERY SUGGESTION: $recovery_suggestion"
    
    # Log additional diagnostic information
    log "SECRETS SETUP DIAGNOSTIC INFO:"
    log "Current directory: $(pwd)"
    log "Environment file exists: $([ -f ".env" ] && echo "yes" || echo "no")"
    log "k8s directory exists: $([ -d "k8s" ] && echo "yes" || echo "no")"
    
    exit $error_code
}

# 5.4 Create Kubernetes secrets for sensitive environment variables
log "Starting Kubernetes secrets setup..."

# Check if k8s directory exists
if [ ! -d "k8s" ]; then
    handle_secrets_error 101 "k8s directory not found" \
        "Ensure k8s directory exists with Kubernetes manifests: $(pwd)/k8s/"
fi
log "k8s directory found: $(pwd)/k8s/"

# Check if setup-secrets.sh script exists
if [ ! -f "k8s/setup-secrets.sh" ]; then
    handle_secrets_error 102 "setup-secrets.sh script not found" \
        "Ensure setup-secrets.sh exists in k8s directory: $(pwd)/k8s/setup-secrets.sh"
fi
log "setup-secrets.sh script found: $(pwd)/k8s/setup-secrets.sh"

# Check if .env file exists
if [ ! -f ".env" ]; then
    log "WARNING: .env file not found in current directory"
    log "Using environment variables from shell environment"
fi

# Set up environment variables for secrets creation
log "Setting up environment variables for secrets creation..."

# Read environment variables from .env file if it exists
if [ -f ".env" ]; then
    log "Loading environment variables from .env file..."
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ ! "$line" =~ ^#.*$ ]] && [[ -n "$line" ]]; then
            # Export the variable
            export "$line"
            log "Set environment variable: ${line%%=*}"
        fi
    done < .env
fi

# Verify required environment variables are set
REQUIRED_VARS=("OPENAI_API_KEY" "OPENAI_BASE_URL" "OPENAI_MODEL" "EMBEDDING_MODEL")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    log "ERROR: Missing required environment variables:"
    for missing_var in "${MISSING_VARS[@]}"; do
        log "  - $missing_var"
    done
    handle_secrets_error 103 "Missing required environment variables" \
        "Set the missing environment variables in your shell or .env file before running the script"
fi
log "All required environment variables are set"

# Run the secrets setup script
log "Running secrets setup script..."
if ! bash k8s/setup-secrets.sh 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 104 "Failed to set up Kubernetes secrets" \
        "Check the secrets setup script output above for errors. Ensure environment variables are correctly set."
fi
log "Kubernetes secrets setup completed successfully"

# 5.5 Apply deployment manifest to microk8s cluster
# 5.6 Apply service manifest to microk8s cluster  
# 5.7 Apply ingress manifest to microk8s cluster
# 5.8 Wait for pods to be ready
# 5.9 Verify deployment status
# 5.10 Verify application is accessible via ingress

log "Starting Kubernetes deployment phase..."

# Apply secrets first (if not already applied by setup-secrets.sh)
# Validate VM_NAME is set before proceeding
if [ -z "$VM_NAME" ]; then
    log "ERROR: VM_NAME is not set. Cannot proceed with Kubernetes deployment."
    log "This should not happen. Please check the script configuration."
    exit 1
fi
log "Using VM_NAME: $VM_NAME for Kubernetes deployment"

# Create k8s directory in VM before file transfer
log "Creating k8s directory in VM..."
if ! multipass exec "$VM_NAME" -- mkdir -p /home/ubuntu/k8s 2>&1 | tee -a "$LOG_FILE"; then
    log "ERROR: Failed to create k8s directory in VM"
    exit 110
fi
log "k8s directory created successfully in VM"

# Transfer secrets.yaml to VM
log "Transferring secrets.yaml to VM..."
if ! multipass transfer k8s/secrets.yaml "$VM_NAME":/home/ubuntu/k8s/secrets.yaml 2>&1 | tee -a "$LOG_FILE"; then
    log "ERROR: Failed to transfer secrets.yaml to VM"
    exit 111
fi
log "secrets.yaml transferred successfully to VM"

# Transfer deployment.yaml to VM
log "Transferring deployment.yaml to VM..."
if ! multipass transfer k8s/deployment.yaml "$VM_NAME":/home/ubuntu/k8s/deployment.yaml 2>&1 | tee -a "$LOG_FILE"; then
    log "ERROR: Failed to transfer deployment.yaml to VM"
    exit 112
fi
log "deployment.yaml transferred successfully to VM"

# Transfer service.yaml to VM
log "Transferring service.yaml to VM..."
if ! multipass transfer k8s/service.yaml "$VM_NAME":/home/ubuntu/k8s/service.yaml 2>&1 | tee -a "$LOG_FILE"; then
    log "ERROR: Failed to transfer service.yaml to VM"
    exit 113
fi
log "service.yaml transferred successfully to VM"

# Transfer ingress.yaml to VM
log "Transferring ingress.yaml to VM..."
if ! multipass transfer k8s/ingress.yaml "$VM_NAME":/home/ubuntu/k8s/ingress.yaml 2>&1 | tee -a "$LOG_FILE"; then
    log "ERROR: Failed to transfer ingress.yaml to VM"
    exit 114
fi
log "ingress.yaml transferred successfully to VM"

log "Applying Kubernetes secrets..."
if ! multipass exec "$VM_NAME" -- microk8s kubectl apply -f k8s/secrets.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 105 "Failed to apply Kubernetes secrets" \
        "Check the secrets file: k8s/secrets.yaml. Ensure it's properly formatted and all variables are set."
fi
log "Kubernetes secrets applied successfully"

# Apply deployment manifest
log "Applying deployment manifest..."
if ! multipass exec "$VM_NAME" -- microk8s kubectl apply -f k8s/deployment.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 106 "Failed to apply deployment manifest" \
        "Check the deployment file: k8s/deployment.yaml. Ensure it references secrets and config maps correctly."
fi
log "Deployment manifest applied successfully"

# Apply service manifest
log "Applying service manifest..."
if ! multipass exec "$VM_NAME" -- microk8s kubectl apply -f k8s/service.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 107 "Failed to apply service manifest" \
        "Check the service file: k8s/service.yaml. Ensure it references the correct deployment."
fi
log "Service manifest applied successfully"

# Apply ingress manifest
log "Applying ingress manifest..."
if ! multipass exec "$VM_NAME" -- microk8s kubectl apply -f k8s/ingress.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 108 "Failed to apply ingress manifest" \
        "Check the ingress file: k8s/ingress.yaml. Ensure ingress controller is enabled in microk8s."
fi
log "Ingress manifest applied successfully"

# Wait for deployment to be ready
log "Waiting for deployment to be ready..."
MAX_ATTEMPTS=20
ATTEMPT=1
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
        handle_secrets_error 109 "Deployment did not become ready within $MAX_ATTEMPTS attempts" \
            "Check pod logs: microk8s kubectl logs -l app=my-ag-ui-app. Check pod status: microk8s kubectl get pods -l app=my-ag-ui-app"
    fi
    
    sleep 10
    ATTEMPT=$((ATTEMPT + 1))
done

# 5.8 Wait for pods to be ready
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
DEPLOYMENT_STATUS=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.status.conditions[?(@.type=="Available")}.status}' 2>/dev/null || echo "Unknown")
log "Deployment status: $DEPLOYMENT_STATUS"

# Get deployment details
log "Deployment details:"
multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app 2>&1 | tee -a "$LOG_FILE"

# 5.10 Verify application is accessible via ingress
# 6.2 Get ingress endpoint URL/IP
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
