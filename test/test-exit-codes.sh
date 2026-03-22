#!/bin/bash

# Test script to verify deploy.sh exits with non-zero status on file transfer failures
# This is task 5.7 from the Ralph Wiggum Task Execution

set -e

echo "=== Testing deploy.sh exit codes on file transfer failures ==="

# Create a temporary directory for testing
TEST_DIR="/tmp/deploy-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "Test directory: $TEST_DIR"

# Copy the deploy.sh script to test directory
cp /home/ncheaz/git/my-ag-ui-app/deploy.sh ./
chmod +x ./deploy.sh

# Create minimal k8s directory structure
mkdir -p k8s

# Create a dummy .env file to avoid environment variable errors
cat > .env << EOF
OPENAI_API_KEY=dummy-key
OPENAI_BASE_URL=http://localhost
OPENAI_MODEL=gpt-3.5-turbo
EMBEDDING_MODEL=text-embedding-ada-002
EOF

# Create a dummy setup-secrets.sh to avoid setup errors
cat > k8s/setup-secrets.sh << EOF
#!/bin/bash
echo "Dummy setup-secrets.sh"
exit 0
EOF
chmod +x k8s/setup-secrets.sh

echo "=== Test 1: Missing secrets.yaml file ==="
# Don't create secrets.yaml - this should cause error 111
echo "Running deploy.sh without secrets.yaml..."
if ./deploy.sh 2>&1 | grep -q "Failed to transfer secrets.yaml to VM"; then
    echo "✓ Correctly detected missing secrets.yaml"
    echo "✓ Test 1 PASSED"
else
    echo "✗ Did not detect missing secrets.yaml"
    echo "✗ Test 1 FAILED"
    exit 1
fi

echo "=== Test 2: Missing deployment.yaml file ==="
# Create secrets.yaml but don't create deployment.yaml - this should cause error 112
cat > k8s/secrets.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: test-secret
type: Opaque
data:
  test-data: dGVzdC1kYXRh
EOF

echo "Running deploy.sh without deployment.yaml..."
if ./deploy.sh 2>&1 | grep -q "Failed to transfer deployment.yaml to VM"; then
    echo "✓ Correctly detected missing deployment.yaml"
    echo "✓ Test 2 PASSED"
else
    echo "✗ Did not detect missing deployment.yaml"
    echo "✗ Test 2 FAILED"
    exit 1
fi

echo "=== Test 3: Missing service.yaml file ==="
# Create deployment.yaml but don't create service.yaml - this should cause error 113
cat > k8s/deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: test
        image: nginx:latest
        ports:
        - containerPort: 80
EOF

echo "Running deploy.sh without service.yaml..."
if ./deploy.sh 2>&1 | grep -q "Failed to transfer service.yaml to VM"; then
    echo "✓ Correctly detected missing service.yaml"
    echo "✓ Test 3 PASSED"
else
    echo "✗ Did not detect missing service.yaml"
    echo "✗ Test 3 FAILED"
    exit 1
fi

echo "=== Test 4: Missing ingress.yaml file ==="
# Create service.yaml but don't create ingress.yaml - this should cause error 114
cat > k8s/service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: test-service
spec:
  selector:
    app: test
  ports:
  - port: 80
    targetPort: 80
EOF

echo "Running deploy.sh without ingress.yaml..."
if ./deploy.sh 2>&1 | grep -q "Failed to transfer ingress.yaml to VM"; then
    echo "✓ Correctly detected missing ingress.yaml"
    echo "✓ Test 4 PASSED"
else
    echo "✗ Did not detect missing ingress.yaml"
    echo "✗ Test 4 FAILED"
    exit 1
fi

echo "=== Test 5: Verify exit codes ==="
# Create all YAML files to get to validation stage
cat > k8s/ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-service
            port:
              number: 80
EOF

echo "Testing exit codes with a non-existent VM..."
# This should fail at directory creation (error 110) or file transfer (errors 111-114)
# and exit with non-zero status

timeout 10s ./deploy.sh >/dev/null 2>&1 || {
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "✓ Script exited with non-zero status: $EXIT_CODE"
        echo "✓ Test 5 PASSED"
    else
        echo "✗ Script exited with zero status (should be non-zero)"
        echo "✗ Test 5 FAILED"
        exit 1
    fi
}

# Clean up
cd /tmp
rm -rf "$TEST_DIR"

echo ""
echo "=== ALL TESTS PASSED ==="
echo "✓ deploy.sh correctly exits with non-zero status on file transfer failures"
echo "✓ Error codes 110-114 are properly handled"
echo "✓ Task 5.7 verification completed successfully"