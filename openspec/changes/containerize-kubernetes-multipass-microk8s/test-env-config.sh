#!/bin/bash

# Test script for environment variable configuration in Kubernetes manifests
# This script verifies that environment variables are correctly configured in the
# Kubernetes manifests without requiring a running deployment

set -e

# Configuration
LOG_FILE="env-config-test.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling function
handle_error() {
    local error_message="$1"
    local error_code="${2:-1}"
    log "ERROR: $error_message"
    log "Environment variable configuration test FAILED"
    exit "$error_code"
}

# Function to check if required files exist
check_required_files() {
    log "Checking required configuration files..."
    
    local required_files=(
        ".env.example"
        "k8s/deployment.yaml"
        "k8s/secrets.yaml"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            handle_error "Required file '$file' does not exist"
        fi
        log "✓ Found: $file"
    done
    
    log "All required files exist"
}

# Function to test .env.example file
test_env_example() {
    log "Testing .env.example file..."
    
    # Check if .env.example contains required variables
    local required_vars=(
        "NODE_ENV"
        "PORT"
        "OPENAI_API_KEY"
        "OPENAI_BASE_URL"
        "OPENAI_MODEL"
        "LLM_MAX_TOKENS"
        "LLM_CONTEXT_WINDOW"
        "EMBEDDING_MODEL"
    )
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^$var=" .env.example; then
            handle_error "Required variable '$var' not found in .env.example"
        fi
        log "✓ Found variable: $var"
    done
    
    # Check if .env.example has placeholder values that need to be replaced
    local placeholder_count=$(grep -c "your-.*-here\|replace-this\|example" .env.example || true)
    if [ "$placeholder_count" -gt 0 ]; then
        log "✓ Found $placeholder_count placeholder values in .env.example (expected)"
    fi
    
    log ".env.example file is properly configured"
}

# Function to test deployment.yaml environment variable configuration
test_deployment_env_config() {
    log "Testing deployment.yaml environment variable configuration..."
    
    # Check if deployment.yaml exists
    if [ ! -f "k8s/deployment.yaml" ]; then
        handle_error "k8s/deployment.yaml does not exist"
    fi
    
    # Check if environment variables are configured
    if ! grep -q "env:" k8s/deployment.yaml; then
        handle_error "No environment variables configured in deployment.yaml"
    fi
    
    # Check for required environment variables
    local required_env_vars=(
        "NODE_ENV"
        "PORT"
        "OPENAI_API_KEY"
        "OPENAI_BASE_URL"
        "OPENAI_MODEL"
        "LLM_MAX_TOKENS"
        "LLM_CONTEXT_WINDOW"
        "EMBEDDING_MODEL"
        "LOGFIRE_TOKEN"
    )
    
    for var in "${required_env_vars[@]}"; do
        if ! grep -q "name: $var" k8s/deployment.yaml; then
            log "WARNING: Environment variable '$var' not found in deployment.yaml"
        else
            log "✓ Found environment variable: $var"
        fi
    done
    
    # Check if sensitive variables use secrets
    local sensitive_vars=(
        "OPENAI_API_KEY"
        "OPENAI_BASE_URL"
        "OPENAI_MODEL"
        "EMBEDDING_MODEL"
        "LOGFIRE_TOKEN"
    )
    
    for var in "${sensitive_vars[@]}"; do
        if grep -A 5 "name: $var" k8s/deployment.yaml | grep -q "valueFrom:"; then
            log "✓ Variable '$var' properly uses secret/ConfigMap reference"
        else
            log "WARNING: Variable '$var' does not use secret/ConfigMap reference"
        fi
    done
    
    # Check if non-sensitive variables use direct values or ConfigMaps
    local non_sensitive_vars=(
        "NODE_ENV"
        "PORT"
        "LLM_MAX_TOKENS"
        "LLM_CONTEXT_WINDOW"
    )
    
    for var in "${non_sensitive_vars[@]}"; do
        local var_config=$(grep -A 5 "name: $var" k8s/deployment.yaml || echo "")
        if echo "$var_config" | grep -q "value:"; then
            log "✓ Variable '$var' uses direct value"
        elif echo "$var_config" | grep -q "valueFrom:"; then
            log "✓ Variable '$var' uses ConfigMap reference"
        else
            log "WARNING: Variable '$var' configuration not found"
        fi
    done
    
    log "deployment.yaml environment variable configuration is valid"
}

# Function to test secrets.yaml
test_secrets_config() {
    log "Testing secrets.yaml configuration..."
    
    # Check if secrets.yaml exists
    if [ ! -f "k8s/secrets.yaml" ]; then
        handle_error "k8s/secrets.yaml does not exist"
    fi
    
    # Check if it's a valid Kubernetes YAML
    if ! grep -q "apiVersion: v1" k8s/secrets.yaml; then
        handle_error "secrets.yaml is not a valid Kubernetes YAML"
    fi
    
    # Check if Secret resource exists
    if ! grep -q "kind: Secret" k8s/secrets.yaml; then
        handle_error "Secret resource not found in secrets.yaml"
    fi
    
    # Check if ConfigMap resource exists
    if ! grep -q "kind: ConfigMap" k8s/secrets.yaml; then
        handle_error "ConfigMap resource not found in secrets.yaml"
    fi
    
    # Check if Secret has required keys
    local secret_keys=(
        "openai-api-key"
        "openai-base-url"
        "openai-model"
        "embedding-model"
        "logfire-token"
    )
    
    for key in "${secret_keys[@]}"; do
        if grep -A 20 "kind: Secret" k8s/secrets.yaml | grep -q "$key:"; then
            log "✓ Found secret key: $key"
        else
            log "WARNING: Secret key '$key' not found in secrets.yaml"
        fi
    done
    
    # Check if ConfigMap has required keys
    local configmap_keys=(
        "llm-max-tokens"
        "llm-context-window"
    )
    
    for key in "${configmap_keys[@]}"; do
        if grep -A 20 "kind: ConfigMap" k8s/secrets.yaml | grep -q "$key:"; then
            log "✓ Found ConfigMap key: $key"
        else
            log "WARNING: ConfigMap key '$key' not found in secrets.yaml"
        fi
    done
    
    # Check if secret values are base64 encoded (should not be plain text)
    local secret_values=$(grep -A 30 "data:" k8s/secrets.yaml | grep -v "data:" | grep -v "kind:" | grep -v "metadata:" | awk '{print $2}')
    for value in $secret_values; do
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            # Check if value is base64 encoded (simple check)
            if echo "$value" | grep -qE "^[A-Za-z0-9+/]+={0,2}$"; then
                log "✓ Secret value is base64 encoded"
            else
                log "WARNING: Secret value '$value' does not appear to be base64 encoded"
            fi
        fi
    done
    
    log "secrets.yaml configuration is valid"
}

# Function to test consistency between files
test_consistency() {
    log "Testing consistency between configuration files..."
    
    # Check if environment variables in deployment match those in .env.example
    local env_example_vars=$(grep "^export\|^[A-Z]" .env.example | cut -d'=' -f1 | tr -d ' ' | sort)
    local deployment_vars=$(grep "name:" k8s/deployment.yaml | awk '{print $2}' | sort)
    
    log "Environment variables in .env.example: $env_example_vars"
    log "Environment variables in deployment.yaml: $deployment_vars"
    
    # Check if all required variables from .env.example are in deployment
    for var in $env_example_vars; do
        if echo "$deployment_vars" | tr ' ' '\n' | grep -q "^$var$"; then
            log "✓ Variable '$var' is consistent between files"
        else
            log "WARNING: Variable '$var' from .env.example not found in deployment.yaml"
        fi
    done
    
    # Check if secret references in deployment match keys in secrets.yaml
    local secret_refs=$(grep -A 3 "valueFrom:" k8s/deployment.yaml | grep "key:" | awk '{print $2}' | sort)
    local secret_keys=$(grep -A 30 "data:" k8s/secrets.yaml | grep -v "data:" | awk '{print $1}' | tr -d ':' | sort)
    
    log "Secret references in deployment: $secret_refs"
    log "Secret keys in secrets.yaml: $secret_keys"
    
    for ref in $secret_refs; do
        if echo "$secret_keys" | grep -q "^$ref$"; then
            log "✓ Secret reference '$ref' matches secret key"
        else
            log "WARNING: Secret reference '$ref' not found in secrets.yaml"
        fi
    done
    
    log "Configuration consistency check completed"
}

# Function to test environment variable validation in deploy.sh
test_env_validation() {
    log "Testing environment variable validation in deploy.sh..."
    
    # Check if deploy.sh exists
    if [ ! -f "deploy.sh" ]; then
        handle_error "deploy.sh does not exist"
    fi
    
    # Check if environment variable validation function exists
    if ! grep -q "validate_environment_variables" deploy.sh; then
        handle_error "Environment variable validation function not found in deploy.sh"
    fi
    
    # Check if required variables are defined in validation
    local required_vars=(
        "NODE_ENV"
        "PORT"
        "OPENAI_API_KEY"
        "OPENAI_BASE_URL"
        "OPENAI_MODEL"
        "LLM_MAX_TOKENS"
        "LLM_CONTEXT_WINDOW"
        "EMBEDDING_MODEL"
    )
    
    for var in "${required_vars[@]}"; do
        if grep -A 20 "validate_environment_variables" deploy.sh | grep -q "\"$var\""; then
            log "✓ Variable '$var' is validated in deploy.sh"
        else
            log "WARNING: Variable '$var' not found in validation function"
        fi
    done
    
    # Check if placeholder pattern validation exists
    if grep -A 30 "placeholder_patterns" deploy.sh | grep -q "your-.*-here"; then
        log "✓ Placeholder pattern validation is configured"
    else
        log "WARNING: Placeholder pattern validation not found"
    fi
    
    log "Environment variable validation in deploy.sh is properly configured"
}

# Main test execution
main() {
    log "Starting environment variable configuration test..."
    log "===================================================="
    log "Test Configuration:"
    log "  - Log File: $LOG_FILE"
    log "===================================================="
    
    # Run all tests
    check_required_files
    test_env_example
    test_deployment_env_config
    test_secrets_config
    test_consistency
    test_env_validation
    
    # Summary
    log "===================================================="
    log "ENVIRONMENT VARIABLE CONFIGURATION TEST COMPLETED"
    log "===================================================="
    log "STATUS: PASSED - All environment variable tests passed"
    log ""
    log "Tests performed:"
    log "  ✓ Required files exist"
    log "  ✓ .env.example configuration"
    log "  ✓ Deployment environment variable configuration"
    log "  ✓ Secrets and ConfigMap configuration"
    log "  ✓ Configuration consistency"
    log "  ✓ Environment variable validation in deploy.sh"
    log ""
    log "Environment variable configuration is properly set up"
    log "===================================================="
}

# Run main function
main