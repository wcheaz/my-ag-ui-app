#!/bin/bash

set -e

# Deploy-all.sh - Orchestrator for modular deployment scripts
# This script executes all modular deployment scripts in sequence
# Usage: ./deploy-all.sh

# Execute deployment scripts in correct order
echo "Starting deployment pipeline..."

echo "Step 1: Setting up Kubernetes secrets..."
if ! ./deploy_scripts/setup-k8s-secrets.sh; then
    echo "ERROR: Failed to set up Kubernetes secrets (Step 1)"
    exit 1
fi

echo "Step 2: Building Docker image..."
if ! ./deploy_scripts/build-docker-image.sh; then
    echo "ERROR: Failed to build Docker image (Step 2)"
    exit 1
fi

echo "Step 3: Tagging Docker image..."
if ! ./deploy_scripts/tag-docker-image.sh; then
    echo "ERROR: Failed to tag Docker image (Step 3)"
    exit 1
fi

echo "Step 4: Setting up Microk8s registry..."
if ! ./deploy_scripts/setup-microk8s-registry.sh; then
    echo "ERROR: Failed to set up Microk8s registry (Step 4)"
    exit 1
fi

echo "Step 5: Pushing Docker image..."
if ! ./deploy_scripts/push-docker-image.sh; then
    echo "ERROR: Failed to push Docker image (Step 5)"
    exit 1
fi

echo "Step 6: Deploying to Kubernetes..."
if ! ./deploy_scripts/deploy-to-k8s.sh; then
    echo "ERROR: Failed to deploy to Kubernetes (Step 6)"
    exit 1
fi

echo "Deployment completed successfully!"

