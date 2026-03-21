#!/bin/bash

# setup-secrets.sh - Generate Kubernetes secrets from environment variables
# This script creates a populated secrets.yaml file from the template

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/secrets.yaml.template"
OUTPUT_FILE="$SCRIPT_DIR/secrets.yaml"

# Function to print error message and exit
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# Function to print success message
success_msg() {
    echo -e "${GREEN}$1${NC}"
}

# Function to print warning message
warning_msg() {
    echo -e "${YELLOW}$1${NC}"
}

# Check if template file exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    error_exit "Template file not found: $TEMPLATE_FILE"
fi

# Function to get environment variable or prompt user
get_sensitive_value() {
    local var_name="$1"
    local prompt_text="$2"
    local default_value="${3:-}"
    
    if [[ -n "${!var_name:-}" ]]; then
        # Use environment variable if set
        echo "${!var_name}"
    elif [[ -n "$default_value" ]]; then
        # Use default value if provided
        echo "$default_value"
    else
        # Prompt user for input (in production, this should come from secure storage)
        warning_msg "Environment variable $var_name is not set"
        read -p "Enter $prompt_text: " -r value
        echo "$value"
    fi
}

echo "Setting up Kubernetes secrets for my-ag-ui-app..."
echo "=============================================="

# Get sensitive values
echo "Getting sensitive configuration values..."

OPENAI_API_KEY=$(get_sensitive_value "OPENAI_API_KEY" "OpenAI API Key")
OPENAI_BASE_URL=$(get_sensitive_value "OPENAI_BASE_URL" "OpenAI Base URL" "https://api.openai.com/v1")
OPENAI_MODEL=$(get_sensitive_value "OPENAI_MODEL" "OpenAI Model" "gpt-4")
EMBEDDING_MODEL=$(get_sensitive_value "EMBEDDING_MODEL" "Embedding Model" "text-embedding-3-small")
LOGFIRE_TOKEN=$(get_sensitive_value "LOGFIRE_TOKEN" "Logfire Token")

# Base64 encode the values
echo "Encoding values..."
ENCODED_API_KEY=$(echo -n "$OPENAI_API_KEY" | base64 -w 0)
ENCODED_BASE_URL=$(echo -n "$OPENAI_BASE_URL" | base64 -w 0)
ENCODED_MODEL=$(echo -n "$OPENAI_MODEL" | base64 -w 0)
ENCODED_EMBEDDING_MODEL=$(echo -n "$EMBEDDING_MODEL" | base64 -w 0)
ENCODED_LOGFIRE_TOKEN=$(echo -n "$LOGFIRE_TOKEN" | base64 -w 0)

# Create secrets.yaml from template
echo "Creating secrets.yaml file..."
cp "$TEMPLATE_FILE" "$OUTPUT_FILE"

# Replace empty values with encoded values (using sed)
sed -i.tmp "s/  openai-api-key: $/  openai-api-key: $ENCODED_API_KEY/" "$OUTPUT_FILE"
sed -i.tmp "s/  openai-base-url: $/  openai-base-url: $ENCODED_BASE_URL/" "$OUTPUT_FILE"
sed -i.tmp "s/  openai-model: $/  openai-model: $ENCODED_MODEL/" "$OUTPUT_FILE"
sed -i.tmp "s/  embedding-model: $/  embedding-model: $ENCODED_EMBEDDING_MODEL/" "$OUTPUT_FILE"
sed -i.tmp "s/  logfire-token: $/  logfire-token: $ENCODED_LOGFIRE_TOKEN/" "$OUTPUT_FILE"

# Clean up temporary file
rm -f "$OUTPUT_FILE.tmp"

# Clear sensitive variables from memory
unset OPENAI_API_KEY OPENAI_BASE_URL OPENAI_MODEL EMBEDDING_MODEL LOGFIRE_TOKEN
unset ENCODED_API_KEY ENCODED_BASE_URL ENCODED_MODEL ENCODED_EMBEDDING_MODEL ENCODED_LOGFIRE_TOKEN

# Verify the file was created
if [[ ! -f "$OUTPUT_FILE" ]]; then
    error_exit "Failed to create secrets.yaml file"
fi

# Check if the secrets file has the expected structure
if ! grep -q "openai-api-key:" "$OUTPUT_FILE" || [[ $(grep "openai-api-key:" "$OUTPUT_FILE" | awk '{print $2}') == "" ]]; then
    error_exit "Generated secrets.yaml appears to be malformed"
fi

success_msg "Secrets file created successfully: $OUTPUT_FILE"
echo ""
echo "WARNING: This file contains sensitive data. Keep it secure and never commit it to version control."
echo "Next step: Apply the secrets to your cluster with: kubectl apply -f $OUTPUT_FILE"
echo ""
echo "For production use, consider using a proper secrets management system like:"
echo "  - Kubernetes External Secrets Operator"
echo "  - HashiCorp Vault"
echo "  - AWS Secrets Manager"
echo "  - Azure Key Vault"
echo "  - Google Cloud Secret Manager"