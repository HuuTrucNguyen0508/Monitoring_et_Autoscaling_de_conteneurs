#!/bin/bash

set -e

# Set a timeout for the entire script (2 minutes)
TIMEOUT=120
start_time=$(date +%s)

# Function to check timeout
check_timeout() {
    local elapsed=$(( $(date +%s) - start_time ))
    if (( elapsed >= TIMEOUT )); then
        print_error "Script timed out after ${TIMEOUT} seconds. Exiting..."
        exit 1
    fi
}

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

print_status "🧹 Starting cleanup of Kubernetes Monitoring Stack..."
check_timeout

# Check for required commands
for cmd in jq lsof helm kubectl docker; do
    if ! command -v $cmd &> /dev/null; then
        print_error "Required command '$cmd' not found. Please install it before running this script."
        exit 1
    fi
done

# Function to check if a port is in use and kill the process if so
check_and_kill_port() {
    PORT=$1
    PID=$(sudo lsof -t -i:$PORT 2>/dev/null || true)
    if [ -n "$PID" ]; then
        print_warning "Port $PORT is in use by process $PID. Terminating it..."
        sudo kill -9 $PID
        sleep 2
        print_success "Port $PORT is now free."
    else
        print_status "Port $PORT is not in use."
    fi
}

# Function to clean up stuck resources in a namespace
cleanup_stuck_resources() {
    local namespace=$1
    print_status "🧹 Cleaning up stuck resources in namespace '$namespace'..."
    
    # Remove finalizers from all resources
    for resource_type in deployment service configmap secret persistentvolumeclaim; do
        kubectl get $resource_type -n $namespace -o name 2>/dev/null | xargs -r kubectl patch -n $namespace --type=merge -p='{"metadata":{"finalizers":[]}}' 2>/dev/null || true
    done
    
    # Force delete all resources
    kubectl delete all --all -n $namespace --force --grace-period=0 2>/dev/null || true
    kubectl delete configmap,secret,pvc --all -n $namespace --force --grace-period=0 2>/dev/null || true
}

# Kill port forwarding processes
print_status "🔌 Stopping port forwarding processes..."
if [ -f /tmp/prometheus_pid ]; then
    PID=$(cat /tmp/prometheus_pid)
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        print_success "Prometheus port forwarding stopped."
    fi
    rm -f /tmp/prometheus_pid
fi

if [ -f /tmp/grafana_pid ]; then
    PID=$(cat /tmp/grafana_pid)
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        print_success "Grafana port forwarding stopped."
    fi
    rm -f /tmp/grafana_pid
fi

# Stop and remove cAdvisor
print_status "📦 Stopping and removing cAdvisor container (if running)..."
docker stop cadvisor &> /dev/null || true
docker rm cadvisor &> /dev/null || true
print_success "cAdvisor cleaned up."

# Uninstall Prometheus stack via Helm
print_status "🧼 Uninstalling kube-prom Helm release..."
helm uninstall kube-prom -n monitoring || print_warning "Helm release not found. Skipping..."

# Uninstall Metrics Server
print_status "🧼 Uninstalling Metrics Server..."
kubectl delete deployment metrics-server -n kube-system || print_warning "Metrics Server deployment not found. Skipping..."
kubectl delete service metrics-server -n kube-system || print_warning "Metrics Server service not found. Skipping..."
kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.1/components.yaml || print_warning "Metrics Server components not found."

# Delete Redis exporter
print_status "🗑️ Deleting Redis Exporter..."
kubectl delete -f redis-exporter.yaml -n monitoring || print_warning "Redis Exporter not found."

# Delete alerting rules
print_status "🚨 Deleting alerting rules..."
kubectl delete -f alerting-rules.yaml || print_warning "Alerting rules not found."

# Delete network policies
print_status "🔒 Deleting network policies..."
kubectl delete -f network-policies.yaml || print_warning "Network policies not found."

# Delete resource quotas
print_status "📊 Deleting resource quotas..."
kubectl delete -f resource-quotas.yaml || print_warning "Resource quotas not found."

# Clean up resources in monitoring namespace first (if it exists)
if kubectl get namespace monitoring &> /dev/null; then
    print_status "🧹 Cleaning up resources in monitoring namespace..."
    
    # Remove finalizers from all resources in the namespace
    for resource_type in deployment service configmap secret persistentvolumeclaim prometheusrule servicemonitor; do
        kubectl get $resource_type -n monitoring -o name 2>/dev/null | xargs -r kubectl patch -n monitoring --type=merge -p='{"metadata":{"finalizers":[]}}' 2>/dev/null || true
    done
    
    # Force delete all resources in the namespace
    kubectl delete all --all -n monitoring --force --grace-period=0 2>/dev/null || true
    kubectl delete prometheusrule,servicemonitor --all -n monitoring --force --grace-period=0 2>/dev/null || true
fi

# Delete monitoring namespace without waiting
print_status "📂 Deleting 'monitoring' namespace..."
kubectl delete namespace monitoring --force --grace-period=0 2>/dev/null || print_warning "Namespace already deleted or not found."

# Quick check if namespace is gone, if not, skip it
if kubectl get namespace monitoring &> /dev/null; then
    print_warning "Namespace 'monitoring' still exists. It will be cleaned up automatically by Kubernetes."
    print_warning "Continuing with cleanup..."
else
    print_success "Namespace 'monitoring' has been deleted."
fi

# Delete main project resources
print_status "🧨 Removing Trucat project resources..."
kubectl delete -f Trucat-project.yaml || print_warning "Truckat project resources not found."

# Force delete any stuck pods
print_status "🧹 Force deleting any stuck pods..."
kubectl delete pods --all --force --grace-period=0 2>/dev/null || print_warning "No pods to force delete."

# Free up ports used for port-forwarding
print_status "🔌 Checking ports and killing if in use..."
check_and_kill_port 9090
check_and_kill_port 3000
check_and_kill_port 8080
check_and_kill_port 7654
check_and_kill_port 8081

# Remove Docker Desktop installer
print_status "🧽 Removing docker-desktop-amd64.deb..."
rm -f docker-desktop-amd64.deb && print_success "docker-desktop-amd64.deb removed." || print_warning "docker-desktop-amd64.deb not found."

# Clean up temporary files
print_status "🧹 Cleaning up temporary files..."
rm -f /tmp/prometheus_pid /tmp/grafana_pid tmp.json

# Final goodbye banner
if command -v figlet &> /dev/null; then
    figlet "Cleanup Done!"
else
    print_success "🎉 Cleanup completed successfully!"
fi

print_status "All resources have been cleaned up. You can now run ./script.sh to redeploy the stack."

