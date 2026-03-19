#!/bin/bash

# Script to set up Kubernetes secrets for my-ag-ui-app
# This script reads environment variables and creates Kubernetes secrets

set -e

# Configuration
SECRETS_FILE="k8s/secrets.yaml.template"
OUTPUT_FILE="k8s/secrets.yaml"
ENV_FILE=".env"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to encode a string to base64
encode_base64() {
    echo -n "$1" | base64
}

# Function to get environment variable value with fallback
get_env_value() {
    local var_name="$1"
    local default_value="$2"
    
    # Check if variable is set in environment
    if [ -n "${!var_name}" ]; then
        echo "${!var_name}"
    elif [ -f "$ENV_FILE" ]; then
        # Try to get value from .env file
        local value=$(grep "^$var_name=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        if [ -n "$value" ]; then
            echo "$value"
        else
            echo "$default_value"
        fi
    else
        echo "$default_value"
    fi
}

log "Setting up Kubernetes secrets..."

# Get environment variable values
OPENAI_API_KEY=$(get_env_value "OPENAI_API_KEY" "")
OPENAI_BASE_URL=$(get_env_value "OPENAI_BASE_URL" "https://api.openai.com/v1")
OPENAI_MODEL=$(get_env_value "OPENAI_MODEL" "gpt-4")
LLM_MAX_TOKENS=$(get_env_value "LLM_MAX_TOKENS" "4096")
LLM_CONTEXT_WINDOW=$(get_env_value "LLM_CONTEXT_WINDOW" "8192")
EMBEDDING_MODEL=$(get_env_value "EMBEDDING_MODEL" "text-embedding-ada-002")
LOGFIRE_TOKEN=$(get_env_value "LOGFIRE_TOKEN" "")

# Encode values to base64
OPENAI_API_KEY_BASE64=$(encode_base64 "$OPENAI_API_KEY")
OPENAI_BASE_URL_BASE64=$(encode_base64 "$OPENAI_BASE_URL")
OPENAI_MODEL_BASE64=$(encode_base64 "$OPENAI_MODEL")
EMBEDDING_MODEL_BASE64=$(encode_base64 "$EMBEDDING_MODEL")
LOGFIRE_TOKEN_BASE64=$(encode_base64 "$LOGFIRE_TOKEN")

# Generate the secrets file
log "Generating Kubernetes secrets file..."
cat > "$OUTPUT_FILE" << EOF
apiVersion: v1
kind: Secret
metadata:
  name: my-ag-ui-app-secrets
  namespace: default
  labels:
    app: my-ag-ui-app
type: Opaque
data:
  # Base64 encoded values for sensitive environment variables
  openai-api-key: $OPENAI_API_KEY_BASE64
  openai-base-url: $OPENAI_BASE_URL_BASE64
  openai-model: $OPENAI_MODEL_BASE64
  embedding-model: $EMBEDDING_MODEL_BASE64
  logfire-token: $LOGFIRE_TOKEN_BASE64
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-ag-ui-app-config
  namespace: default
  labels:
    app: my-ag-ui-app
data:
  # Non-sensitive configuration values
  llm-max-tokens: "$LLM_MAX_TOKENS"
  llm-context-window: "$LLM_CONTEXT_WINDOW"
EOF

log "Kubernetes secrets file generated: $OUTPUT_FILE"
