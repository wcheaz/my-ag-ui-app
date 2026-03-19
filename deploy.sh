
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
log "Verifying application accessibility via ingress..."

# Get ingress details
INGRESS_DETAILS=$(multipass exec "$VM_NAME" -- microk8s kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "Unknown")
log "Ingress host: $INGRESS_DETAILS"

# Check if ingress has an address assigned
INGRESS_IP=$(multipass exec "$VM_NAME" -- microk8s kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
INGRESS_HOSTNAME=$(multipass exec "$VM_NAME" -- microk8s kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -n "$INGRESS_IP" ]; then
    log "Ingress IP address: $INGRESS_IP"
    log "Application should be accessible at: http://$INGRESS_IP"
elif [ -n "$INGRESS_HOSTNAME" ]; then
    log "Ingress hostname: $INGRESS_HOSTNAME"
    log "Application should be accessible at: http://$INGRESS_HOSTNAME"
else
    log "Ingress address not yet assigned. This may take a few minutes."
    log "To check ingress status, run: microk8s kubectl get ingress my-ag-ui-app-ingress"
fi

# Test application accessibility (basic check)
log "Testing application accessibility..."
if multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].status.podIP}' 2>/dev/null | grep -q "."; then
    POD_IP=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].status.podIP}' 2>/dev/null)
    log "Application pod IP: $POD_IP"
    
    # Try to access the application from within the cluster
    if multipass exec "$VM_NAME" -- microk8s kubectl run temp-curl --image=curlimages/curl --rm -it --restart=Never -- curl -s --connect-timeout 5 "http://$POD_IP:3000/health" >/dev/null 2>&1; then
        log "Application health check passed"
    else
        log "WARNING: Application health check failed"
    fi
else
    log "Unable to determine pod IP for accessibility test"
fi

log "Kubernetes deployment phase completed successfully"
log "Application should be accessible via ingress (may take a few minutes for ingress to be fully ready)"

# Provide access instructions
log "=== APPLICATION ACCESS INFORMATION ==="
log "To access the application:"
log "1. Check ingress status: microk8s kubectl get ingress my-ag-ui-app-ingress"
log "2. If ingress has an IP address: http://<ingress-ip>"
log "3. If using local testing: add '127.0.0.1 my-ag-ui-app.local' to your /etc/hosts file"
log "4. Then access: http://my-ag-ui-app.local"
log "=== END ACCESS INFORMATION ==="

log "Kubernetes secrets setup and deployment completed successfully"
