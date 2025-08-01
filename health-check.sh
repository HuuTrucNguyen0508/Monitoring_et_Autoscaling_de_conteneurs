#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🏥 Kubernetes Monitoring Stack Health Check"
echo "=========================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check cluster connectivity
print_status "Checking cluster connectivity..."
if kubectl cluster-info >/dev/null 2>&1; then
    print_success "Cluster is accessible"
else
    print_error "Cannot connect to cluster"
    exit 1
fi

echo ""
print_status "📊 Checking Pod Status:"
echo "----------------------------"

# Check pods in default namespace
print_status "Default namespace pods:"
kubectl get pods -o wide

echo ""
print_status "Monitoring namespace pods:"
kubectl get pods -n monitoring -o wide

echo ""
print_status "🔍 Checking Services:"
echo "-------------------------"
kubectl get services

echo ""
print_status "📈 Checking HPA Status:"
echo "----------------------------"
kubectl get hpa

echo ""
print_status "🌐 Checking Port Forwarding:"
echo "--------------------------------"

# Check if port forwarding is active
check_port() {
    local port=$1
    local service=$2
    if curl -s http://localhost:$port >/dev/null 2>&1; then
        print_success "$service is accessible on port $port"
    else
        print_warning "$service is not accessible on port $port"
    fi
}

check_port 9090 "Prometheus"
check_port 3000 "Grafana"
check_port 8080 "Backend Application"
check_port 7654 "Frontend Application"
check_port 8081 "cAdvisor"

echo ""
print_status "📊 Checking Resource Usage:"
echo "-------------------------------"
kubectl top pods
echo ""
kubectl top nodes

echo ""
print_status "🚨 Checking Recent Events:"
echo "-------------------------------"
kubectl get events --sort-by='.lastTimestamp' | tail -10

echo ""
print_status "🔒 Checking Network Policies:"
echo "----------------------------------"
kubectl get networkpolicies

echo ""
print_status "📊 Checking Resource Quotas:"
echo "---------------------------------"
kubectl get resourcequota
kubectl get limitrange

echo ""
print_status "📈 Checking Metrics Server:"
echo "--------------------------------"
if kubectl get apiservice v1beta1.metrics.k8s.io -o jsonpath='{.status.conditions[0].status}' 2>/dev/null | grep -q "True"; then
    print_success "Metrics Server is working"
else
    print_warning "Metrics Server might not be working properly"
fi

echo ""
print_status "🎯 Health Check Summary:"
echo "----------------------------"

# Count running pods
total_pods=$(kubectl get pods --no-headers | wc -l)
running_pods=$(kubectl get pods --no-headers | grep -c "Running")
failed_pods=$(kubectl get pods --no-headers | grep -c "Failed\|Error\|CrashLoopBackOff")

print_status "Total pods: $total_pods"
print_status "Running pods: $running_pods"
print_status "Failed pods: $failed_pods"

if [ $failed_pods -eq 0 ]; then
    print_success "All pods are running successfully!"
else
    print_warning "$failed_pods pods are in failed state"
fi

echo ""
print_status "Health check completed!" 