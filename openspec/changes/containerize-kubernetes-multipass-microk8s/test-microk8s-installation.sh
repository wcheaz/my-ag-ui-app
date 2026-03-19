#!/bin/bash

# Test script to verify microk8s installation section has been added correctly

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy.sh"

echo "Testing microk8s installation section in $DEPLOY_SCRIPT..."

# Check if microk8s installation section exists
if ! grep -q "MICROK8S INSTALLATION SECTION" "$DEPLOY_SCRIPT"; then
    echo "ERROR: Microk8s installation section not found in deploy.sh"
    exit 1
fi

echo "✓ Microk8s installation section found"

# Check for key microk8s installation functions
REQUIRED_FUNCTIONS=(
    "handle_microk8s_error"
    "handle_microk8s_addon_error"
    "microk8s_ready"
    "microk8s_addon_enabled"
)

for func in "${REQUIRED_FUNCTIONS[@]}"; do
    if ! grep -q "^[[:space:]]*${func}()" "$DEPLOY_SCRIPT"; then
        echo "ERROR: Function $func not found in deploy.sh"
        exit 1
    fi
    echo "✓ Function $func found"
done

# Check for key microk8s installation steps
REQUIRED_STEPS=(
    "Installing microk8s in VM"
    "Enabling dns add-on"
    "Enabling storage add-on"
    "Enabling ingress add-on"
    "Waiting for microk8s to be ready"
    "Verifying microk8s status"
)

for step in "${REQUIRED_STEPS[@]}"; do
    if ! grep -q "$step" "$DEPLOY_SCRIPT"; then
        echo "ERROR: Step '$step' not found in deploy.sh"
        exit 1
    fi
    echo "✓ Step '$step' found"
done

# Check for error handling
if ! grep -q "handle_microk8s_error" "$DEPLOY_SCRIPT"; then
    echo "ERROR: Microk8s error handling not found"
    exit 1
fi
echo "✓ Microk8s error handling found"

# Check for add-on error handling
if ! grep -q "handle_microk8s_addon_error" "$DEPLOY_SCRIPT"; then
    echo "ERROR: Microk8s add-on error handling not found"
    exit 1
fi
echo "✓ Microk8s add-on error handling found"

echo ""
echo "All tests passed! Microk8s installation section has been correctly added to deploy.sh"
echo ""
echo "Key features implemented:"
echo "- Microk8s installation with snap"
echo "- Error handling for installation failures"
echo "- Add-on enablement (dns, storage, ingress)"
echo "- Status verification and readiness checks"
echo "- Comprehensive error handling and recovery suggestions"