#!/bin/bash

# Test script to verify application accessibility via ingress endpoint
# This is for task 5.4: Test application accessibility via ingress endpoint

echo "=== TASK 5.4: TEST APPLICATION ACCESSIBILITY VIA INGRESS ENDPOINT ==="
echo "Testing application accessibility..."

# Set default values
INGRESS_HOST="my-ag-ui-app.local"
INGRESS_PORT=80
MAX_RETRIES=30
RETRY_DELAY=2

# Check if we have a running Kubernetes cluster
echo "Step 1: Checking Kubernetes cluster availability..."
if ! kubectl version --client >/dev/null 2>&1; then
    echo "❌ ERROR: kubectl is not available or cannot connect to cluster"
    echo "RECOVERY: Check if Kubernetes cluster is running and accessible"
    exit 1
fi
echo "✅ Kubernetes client is available"

# Check if ingress controller is available
echo "Step 2: Checking ingress controller availability..."
if ! kubectl get ingressclasses.networking.k8s.io nginx >/dev/null 2>&1; then
    echo "❌ ERROR: nginx ingress controller is not available"
    echo "RECOVERY: Install nginx ingress controller: kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml"
    exit 1
fi
echo "✅ nginx ingress controller is available"

# Check if our ingress resource exists
echo "Step 3: Checking ingress resource existence..."
if ! kubectl get ingress my-ag-ui-app-ingress >/dev/null 2>&1; then
    echo "❌ ERROR: ingress resource 'my-ag-ui-app-ingress' does not exist"
    echo "RECOVERY: Apply ingress configuration: kubectl apply -f k8s/ingress.yaml"
    exit 1
fi
echo "✅ ingress resource 'my-ag-ui-app-ingress' exists"

# Check if service exists
echo "Step 4: Checking service existence..."
if ! kubectl get service my-ag-ui-app-service >/dev/null 2>&1; then
    echo "❌ ERROR: service 'my-ag-ui-app-service' does not exist"
    echo "RECOVERY: Apply service configuration: kubectl apply -f k8s/service.yaml"
    exit 1
fi
echo "✅ service 'my-ag-ui-app-service' exists"

# Check if pods are running
echo "Step 5: Checking pod status..."
pod_status=$(kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "unknown")
if [ "$pod_status" != "Running" ]; then
    echo "❌ ERROR: pods are not running (status: $pod_status)"
    echo "RECOVERY: Check pod logs: kubectl logs -l app=my-ag-ui-app"
    echo "         Check pod events: kubectl describe pods -l app=my-ag-ui-app"
    exit 1
fi
echo "✅ pods are running (status: $pod_status)"

# Get ingress IP/hostname
echo "Step 6: Getting ingress endpoint..."
ingress_ip=$(kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
ingress_hostname=$(kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -n "$ingress_ip" ]; then
    endpoint="$ingress_ip"
elif [ -n "$ingress_hostname" ]; then
    endpoint="$ingress_hostname"
else
    # For local development, use minikube or local hostname
    if command -v minikube >/dev/null 2>&1; then
        endpoint=$(minikube ip)
    else
        endpoint="localhost"
    fi
fi

echo "Ingress endpoint: $endpoint"

# Test application accessibility
echo "Step 7: Testing application accessibility..."
echo "Testing URL: http://$endpoint:$INGRESS_PORT"
echo "Host header: $INGRESS_HOST"

# Try to access the application
attempt=1
while [ $attempt -le $MAX_RETRIES ]; do
    echo "Attempt $attempt/$MAX_RETRIES..."
    
    # Test HTTP request with host header
    if curl -s -f -H "Host: $INGRESS_HOST" "http://$endpoint:$INGRESS_PORT" >/dev/null 2>&1; then
        echo "✅ SUCCESS: Application is accessible via ingress endpoint"
        echo "   URL: http://$endpoint:$INGRESS_PORT"
        echo "   Host: $INGRESS_HOST"
        echo "   Status: VERIFIED and ACCESSIBLE"
        
        # Get additional information
        echo ""
        echo "=== APPLICATION ACCESSIBILITY DETAILS ==="
        echo "Ingress Host: $INGRESS_HOST"
        echo "Endpoint: http://$endpoint:$INGRESS_PORT"
        echo "Test Command: curl -H \"Host: $INGRESS_HOST\" http://$endpoint:$INGRESS_PORT"
        
        # Test response headers
        echo ""
        echo "=== RESPONSE HEADERS ==="
        curl -s -I -H "Host: $INGRESS_HOST" "http://$endpoint:$INGRESS_PORT" | head -5
        
        echo ""
        echo "✅ TASK 5.4: TEST APPLICATION ACCESSIBILITY VIA INGRESS ENDPOINT - COMPLETED"
        exit 0
    fi
    
    echo "Attempt $attempt failed, waiting $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
    attempt=$((attempt + 1))
done

echo "❌ ERROR: Application is not accessible via ingress endpoint after $MAX_RETRIES attempts"
echo ""
echo "TROUBLESHOOTING STEPS:"
echo "1. Check ingress controller logs: kubectl logs -n ingress-nginx ingress-nginx-controller-<pod-name>"
echo "2. Check ingress events: kubectl describe ingress my-ag-ui-app-ingress"
echo "3. Check service endpoints: kubectl get endpoints my-ag-ui-app-service"
echo "4. Check pod logs: kubectl logs -l app=my-ag-ui-app"
echo "5. Verify network policies allow traffic"
echo "6. Check if ingress controller has external IP/hostname assigned"

exit 1