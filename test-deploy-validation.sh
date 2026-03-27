#!/bin/bash
# Test script for deployment manifest validation with invalid YAML
# This script tests error handling when invalid YAML is provided to the deployment script

set -euo pipefail

# Source common functions
source "deploy_scripts/common.sh"

# Setup logging
setup_log_file "test-deploy-validation"

echo "=== TESTING DEPLOYMENT MANIFEST VALIDATION WITH INVALID YAML ==="
echo "This test verifies that the deploy-to-k8s.sh script properly handles invalid YAML"

# Create backup of original deployment.yaml
if [ -f "k8s/deployment.yaml" ]; then
    cp k8s/deployment.yaml k8s/deployment.yaml.backup
    echo "✓ Backed up original deployment.yaml"
else
    echo "❌ Original deployment.yaml not found"
    exit 1
fi

# Test 1: Invalid YAML syntax (missing closing bracket)
echo ""
echo "TEST 1: Invalid YAML syntax (missing closing bracket)"
log_info "Creating deployment manifest with invalid YAML syntax..."

cat > k8s/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-ag-ui-app
  labels:
    app: my-ag-ui-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-ag-ui-app
  template:
    metadata:
      labels:
        app: my-ag-ui-app
    spec:
      containers:
      - name: my-ag-ui-app
        image: localhost:32000/my-ag-ui-app:latest
        ports:
        - containerPort: 3000
        # Missing closing bracket for container spec
EOF

echo "✓ Created invalid YAML (missing closing bracket)"

# Test the validation (should fail)
echo "Testing validation with invalid YAML..."
if bash deploy_scripts/deploy-to-k8s.sh 2>&1 | grep -q "DEPLOYMENT MANIFEST VALIDATION FAILED"; then
    echo "✓ PASS: Validation correctly detected invalid YAML"
    echo "✓ Error handling worked as expected"
else
    echo "❌ FAIL: Validation did not detect invalid YAML"
    # Restore original file
    cp k8s/deployment.yaml.backup k8s/deployment.yaml
    exit 1
fi

# Test 2: Invalid Kubernetes API version
echo ""
echo "TEST 2: Invalid Kubernetes API version"
log_info "Creating deployment manifest with invalid API version..."

cat > k8s/deployment.yaml << 'EOF'
apiVersion: apps/v999  # Non-existent API version
kind: Deployment
metadata:
  name: my-ag-ui-app
  labels:
    app: my-ag-ui-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-ag-ui-app
  template:
    metadata:
      labels:
        app: my-ag-ui-app
    spec:
      containers:
      - name: my-ag-ui-app
        image: localhost:32000/my-ag-ui-app:latest
        ports:
        - containerPort: 3000
EOF

echo "✓ Created manifest with invalid API version"

# Test the validation (should fail)
echo "Testing validation with invalid API version..."
if bash deploy_scripts/deploy-to-k8s.sh 2>&1 | grep -q "DEPLOYMENT MANIFEST VALIDATION FAILED"; then
    echo "✓ PASS: Validation correctly detected invalid API version"
    echo "✓ Error handling worked as expected"
else
    echo "❌ FAIL: Validation did not detect invalid API version"
    # Restore original file
    cp k8s/deployment.yaml.backup k8s/deployment.yaml
    exit 1
fi

# Test 3: Missing required field
echo ""
echo "TEST 3: Missing required field (no selector)"
log_info "Creating deployment manifest with missing required field..."

cat > k8s/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-ag-ui-app
  labels:
    app: my-ag-ui-app
spec:
  replicas: 1
  # Missing required 'selector' field
  template:
    metadata:
      labels:
        app: my-ag-ui-app
    spec:
      containers:
      - name: my-ag-ui-app
        image: localhost:32000/my-ag-ui-app:latest
        ports:
        - containerPort: 3000
EOF

echo "✓ Created manifest with missing required field"

# Test the validation (should fail)
echo "Testing validation with missing required field..."
if bash deploy_scripts/deploy-to-k8s.sh 2>&1 | grep -q "DEPLOYMENT MANIFEST VALIDATION FAILED"; then
    echo "✓ PASS: Validation correctly detected missing required field"
    echo "✓ Error handling worked as expected"
else
    echo "❌ FAIL: Validation did not detect missing required field"
    # Restore original file
    cp k8s/deployment.yaml.backup k8s/deployment.yaml
    exit 1
fi

# Test 4: Valid YAML (should pass validation)
echo ""
echo "TEST 4: Valid YAML (should pass validation)"
log_info "Testing with valid deployment manifest..."

# Restore the original valid deployment.yaml
cp k8s/deployment.yaml.backup k8s/deployment.yaml
echo "✓ Restored valid deployment.yaml"

# Test the validation (should pass, but will fail later due to missing image/cluster)
echo "Testing validation with valid YAML..."
if bash deploy_scripts/deploy-to-k8s.sh 2>&1 | grep -q "✅ Deployment manifest validation successful"; then
    echo "✓ PASS: Validation correctly passed with valid YAML"
    echo "✓ Valid YAML was accepted as expected"
else
    echo "❌ FAIL: Validation did not pass with valid YAML"
    exit 1
fi

# Cleanup
echo ""
echo "=== CLEANUP ==="
rm -f k8s/deployment.yaml.backup
echo "✓ Cleaned up backup file"

echo ""
echo "=== TEST SUMMARY ==="
echo "✅ All validation tests passed!"
echo "✅ Invalid YAML syntax: Correctly rejected"
echo "✅ Invalid API version: Correctly rejected" 
echo "✅ Missing required field: Correctly rejected"
echo "✅ Valid YAML: Correctly accepted"
echo ""
echo "🎉 DEPLOYMENT MANIFEST VALIDATION TESTS COMPLETED SUCCESSFULLY"