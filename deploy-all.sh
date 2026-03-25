#!/bin/bash

set -e

# Deploy-all.sh - Orchestrator for modular deployment scripts
# This script executes all modular deployment scripts in sequence

# Execute deployment scripts in correct order
echo "Starting deployment pipeline..."

echo "Step 1: Setting up Kubernetes secrets..."
./deploy_scripts/setup-k8s-secrets.sh

echo "Step 2: Building Docker image..."
./deploy_scripts/build-docker-image.sh

echo "Step 3: Tagging Docker image..."
./deploy_scripts/tag-docker-image.sh

echo "Step 4: Setting up Microk8s registry..."
./deploy_scripts/setup-microk8s-registry.sh

echo "Step 5: Pushing Docker image..."
./deploy_scripts/push-docker-image.sh

echo "Step 6: Deploying to Kubernetes..."
./deploy_scripts/deploy-to-k8s.sh

echo "Deployment completed successfully!"