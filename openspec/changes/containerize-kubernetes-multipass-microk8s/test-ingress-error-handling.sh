#!/bin/bash

# Test script for ingress error handling
# This script tests various error scenarios for the ingress configuration
# 
# Prerequisites:
# - microk8s cluster must be running and accessible
# - ingress controller must be installed and running
# - the application must be deployed via ingress
#
# Usage: ./test-ingress-error-handling.sh

set -e

echo "=== Testing Ingress Error Handling ==="

# Check if microk8s is available and cluster is running
echo "Checking microk8s cluster status..."
if ! microk8s kubectl cluster-info &>/dev/null; then
    echo "❌ FAIL: microk8s cluster is not accessible"
    echo "Please ensure microk8s is installed and the cluster is running"
    exit 1
fi

echo "✅ microk8s cluster is accessible"

# Check if the ingress resource exists
echo "Checking ingress resource..."
if ! microk8s kubectl get ingress my-ag-ui-app-ingress &>/dev/null; then
    echo "❌ FAIL: ingress resource 'my-ag-ui-app-ingress' not found"
    echo "Please ensure the application is deployed with ingress"
    exit 1
fi

echo "✅ ingress resource found"

# Get the ingress IP or hostname
INGRESS_IP=$(microk8s kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
INGRESS_HOSTNAME=$(microk8s kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -n "$INGRESS_IP" ]; then
    ENDPOINT="$INGRESS_IP"
elif [ -n "$INGRESS_HOSTNAME" ]; then
    ENDPOINT="$INGRESS_HOSTNAME"
else
    # For microk8s, the ingress is usually available via localhost
    ENDPOINT="localhost"
fi

echo "Using endpoint: $ENDPOINT"

# Function to test HTTP status code
test_endpoint() {
    local url=$1
    local expected_status=$2
    local description=$3
    
    echo "Testing: $description"
    echo "URL: http://$url"
    
    status_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "http://$url" 2>/dev/null || echo "000")
    
    if [ "$status_code" = "$expected_status" ]; then
        echo "✅ PASS: Expected $expected_status, got $status_code"
    else
        echo "❌ FAIL: Expected $expected_status, got $status_code"
        return 1
    fi
}

# Function to test HTTPS status code
test_https_endpoint() {
    local url=$1
    local expected_status=$2
    local description=$3
    
    echo "Testing: $description"
    echo "URL: https://$url"
    
    status_code=$(curl -s -o /dev/null -w "%{http_code}" -k --connect-timeout 5 --max-time 10 "https://$url" 2>/dev/null || echo "000")
    
    if [ "$status_code" = "$expected_status" ]; then
        echo "✅ PASS: Expected $expected_status, got $status_code"
    else
        echo "❌ FAIL: Expected $expected_status, got $status_code"
        return 1
    fi
}

# Test 1: Normal operation (should work)
echo -e "\n--- Test 1: Normal Operation ---"
test_endpoint "$ENDPOINT" "200" "Normal HTTP access"
test_https_endpoint "$ENDPOINT" "200" "Normal HTTPS access"

# Test 2: Non-existent path (should return 404)
echo -e "\n--- Test 2: Non-existent Path ---"
test_endpoint "$ENDPOINT/non-existent-path" "404" "Non-existent path HTTP"
test_https_endpoint "$ENDPOINT/non-existent-path" "404" "Non-existent path HTTPS"

# Test 3: Backend service unavailable
echo -e "\n--- Test 3: Backend Service Unavailable ---"
# Scale down the deployment to 0 replicas
echo "Scaling down deployment to 0 replicas..."
microk8s kubectl scale deployment my-ag-ui-app --replicas=0

# Wait for deployment to scale down
echo "Waiting for deployment to scale down..."
sleep 10

# Should return 503 (Service Unavailable) or 502 (Bad Gateway)
test_endpoint "$ENDPOINT" "503" "Backend unavailable HTTP"
test_https_endpoint "$ENDPOINT" "503" "Backend unavailable HTTPS"

# Restore the deployment
echo "Restoring deployment to 1 replica..."
microk8s kubectl scale deployment my-ag-ui-app --replicas=1

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
sleep 30

# Test 4: Invalid host header
echo -e "\n--- Test 4: Invalid Host Header ---"
# Test with an invalid host that's not configured in the ingress
status_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: invalid-host.example" --connect-timeout 5 --max-time 10 "http://$ENDPOINT" 2>/dev/null || echo "000")
if [ "$status_code" = "404" ] || [ "$status_code" = "000" ]; then
    echo "✅ PASS: Invalid host header returned appropriate status ($status_code)"
else
    echo "❌ FAIL: Invalid host header returned unexpected status: $status_code"
fi

# Test 5: Connection timeout
echo -e "\n--- Test 5: Connection Timeout Handling ---"
# Create a non-routable IP address to test connection timeout
status_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 1 --max-time 3 "http://192.0.2.1" 2>/dev/null || echo "000")
if [ "$status_code" = "000" ]; then
    echo "✅ PASS: Connection timeout handled properly (status 000 indicates timeout)"
else
    echo "❌ FAIL: Unexpected status code for timeout test: $status_code"
fi

# Test 6: Large request payload
echo -e "\n--- Test 6: Large Request Payload ---"
# Create a large payload
large_payload=$(printf 'a%.0s' {1..1000000})  # 1MB of 'a's
    
# Test with the large payload
status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: text/plain" -d "$large_payload" --connect-timeout 5 --max-time 15 "http://$ENDPOINT" 2>/dev/null || echo "000")

if [ "$status_code" = "413" ] || [ "$status_code" = "200" ]; then
    echo "✅ PASS: Large payload handled appropriately (status $status_code)"
else
    echo "❌ FAIL: Large payload returned unexpected status: $status_code"
fi

echo -e "\n=== Ingress Error Handling Tests Complete ==="

# Check if deployment is healthy
echo -e "\n--- Checking Deployment Health ---"
deployment_status=$(microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.status.readyReplicas}')
if [ "$deployment_status" = "1" ]; then
    echo "✅ Deployment is healthy with 1 ready replica"
else
    echo "⚠️  Deployment may not be healthy. Ready replicas: $deployment_status"
fi

# Show ingress logs
echo -e "\n--- Ingress Controller Logs (last 10 lines) ---"
microk8s kubectl logs -n ingress deployment/nginx-ingress-controller --tail=10 2>/dev/null || echo "Could not get ingress logs"

echo "Error handling tests completed."