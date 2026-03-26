#!/bin/bash

# Test script to verify secrets validation with valid YAML
# This script tests the secrets validation functionality with valid environment variables
# to ensure successful application to Kubernetes cluster.

# Enable strict error handling
set -euo pipefail

# Source common error handling functions
source "deploy_scripts/common.sh"

# Initialize log file
setup_log_file

# Cleanup function to restore .env file
cleanup_test_env() {
    log_info "Cleaning up test environment..."
    # Clean up test secrets
    kubectl delete secret my-ag-ui-app-secrets 2>/dev/null || true
    kubectl delete configmap my-ag-ui-app-config 2>/dev/null || true
    
    # Restore original .env file if it existed
    if [ -f ".env.tmp" ]; then
        mv .env.tmp .env
    else
        rm -f .env
    fi
}

# Test function to verify secrets validation with valid YAML
test_secrets_validation_valid_yaml() {
    log_info "Testing secrets validation with valid YAML..."
    
    # Set up cleanup trap
    trap cleanup_test_env EXIT
    
    # Backup existing .env file if it exists
    if [ -f ".env" ]; then
        log_info "Backing up existing .env file..."
        cp .env .env.backup
        mv .env .env.tmp
    fi
    
    # Create test .env file with known values
    log_info "Creating test .env file with known values..."
    cat > .env << EOF
OPENAI_API_KEY=test-api-key-for-validation
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-4
LLM_MAX_TOKENS=4096
LLM_CONTEXT_WINDOW=8192
EMBEDDING_MODEL=text-embedding-ada-002
LOGFIRE_TOKEN=test-logfire-token
EOF
    
    # Set environment variables for testing
    log_info "Setting test environment variables..."
    export OPENAI_API_KEY="test-api-key-for-validation"
    export OPENAI_BASE_URL="https://api.openai.com/v1"
    export OPENAI_MODEL="gpt-4"
    export EMBEDDING_MODEL="text-embedding-ada-002"
    
    # Clean up any existing secrets file to ensure fresh test
    if [ -f "k8s/secrets.yaml" ]; then
        log_info "Cleaning up existing secrets file..."
        rm -f k8s/secrets.yaml
    fi
    
    # Run the secrets setup script
    log_info "Running secrets setup script with valid environment variables..."
    if ! bash deploy_scripts/setup-k8s-secrets.sh 2>&1 | tee -a "$LOG_FILE"; then
        log_error "Secrets setup script failed with valid environment variables"
        return 1
    fi
    
    # Verify secrets YAML file was created
    if [ ! -f "k8s/secrets.yaml" ]; then
        log_error "Secrets YAML file was not created"
        return 1
    fi
    
    log_info "Secrets YAML file created successfully"
    
    # Verify secrets YAML file is valid by checking its content
    log_info "Validating secrets YAML file content..."
    if ! grep -q "apiVersion: v1" k8s/secrets.yaml; then
        log_error "Secrets YAML file does not contain valid Kubernetes API version"
        return 1
    fi
    
    if ! grep -q "kind: Secret" k8s/secrets.yaml; then
        log_error "Secrets YAML file does not contain Secret kind"
        return 1
    fi
    
    if ! grep -q "name: my-ag-ui-app-secrets" k8s/secrets.yaml; then
        log_error "Secrets YAML file does not contain correct secret name"
        return 1
    fi
    
    log_info "Secrets YAML file content validation passed"
    
    # Test Kubernetes API server validation
    log_info "Testing Kubernetes API server validation..."
    if ! kubectl apply --dry-run=server -f k8s/secrets.yaml 2>&1 | tee -a "$LOG_FILE"; then
        log_error "Kubernetes API server validation failed"
        return 1
    fi
    
    log_info "Kubernetes API server validation passed"
    
    # Test actual application to Kubernetes cluster
    log_info "Testing secrets application to Kubernetes cluster..."
    if ! kubectl apply -f k8s/secrets.yaml 2>&1 | tee -a "$LOG_FILE"; then
        log_error "Failed to apply secrets to Kubernetes cluster"
        return 1
    fi
    
    log_info "Secrets applied to Kubernetes cluster successfully"
    
    # Verify secrets exist in Kubernetes cluster
    log_info "Verifying secrets exist in Kubernetes cluster..."
    if ! kubectl get secret my-ag-ui-app-secrets 2>&1 | tee -a "$LOG_FILE"; then
        log_error "Secrets do not exist in Kubernetes cluster"
        return 1
    fi
    
    log_info "Secrets verification in Kubernetes cluster passed"
    
    # Verify ConfigMap exists in Kubernetes cluster
    log_info "Verifying ConfigMap exists in Kubernetes cluster..."
    if ! kubectl get configmap my-ag-ui-app-config 2>&1 | tee -a "$LOG_FILE"; then
        log_error "ConfigMap does not exist in Kubernetes cluster"
        return 1
    fi
    
    log_info "ConfigMap verification in Kubernetes cluster passed"
    
    # Test secrets data decoding
    log_info "Testing secrets data decoding..."
    local decoded_api_key
    decoded_api_key=$(kubectl get secret my-ag-ui-app-secrets -o jsonpath='{.data.openai-api-key}' | base64 --decode 2>/dev/null || echo "")
    
    if [ "$decoded_api_key" != "$OPENAI_API_KEY" ]; then
        log_error "Secrets data decoding failed - API keys do not match"
        log_error "Expected: $OPENAI_API_KEY"
        log_error "Got: $decoded_api_key"
        return 1
    fi
    
    log_info "Secrets data decoding verification passed"
    
    log_info "Test secrets validation with valid YAML completed successfully"
    return 0
}

# Main test execution
log_info "Starting secrets validation test with valid YAML..."

# Check if kubectl is available
if ! command -v kubectl >/dev/null 2>&1; then
    log_error "kubectl command not found. Please install kubectl to run this test."
    exit 1
fi

# Check if Kubernetes cluster is accessible
if ! kubectl cluster-info >/dev/null 2>&1; then
    log_error "Kubernetes cluster is not accessible. Please ensure cluster is running."
    exit 1
fi

# Run the test
if test_secrets_validation_valid_yaml; then
    log_info "✅ Secrets validation test with valid YAML PASSED"
    echo ""
    echo "✅ TEST RESULT: Secrets validation with valid YAML works correctly"
    echo "   - Secrets YAML file generation: PASSED"
    echo "   - Kubernetes API server validation: PASSED"
    echo "   - Secrets application to cluster: PASSED"
    echo "   - Secrets verification in cluster: PASSED"
    echo "   - ConfigMap verification in cluster: PASSED"
    echo "   - Secrets data decoding: PASSED"
    echo ""
    exit 0
else
    log_error "❌ Secrets validation test with valid YAML FAILED"
    echo ""
    echo "❌ TEST RESULT: Secrets validation with valid YAML failed"
    echo "   Check the logs above for detailed failure information"
    echo ""
    exit 1
fi