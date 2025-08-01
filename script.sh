#!/bin/bash

set -e

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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for a deployment to be ready
wait_for_deployment() {
    local deployment=$1
    local namespace=${2:-default}
    local timeout=${3:-300}
    
    print_status "Waiting for deployment $deployment in namespace $namespace to be ready..."
    
    kubectl wait --for=condition=available --timeout=${timeout}s deployment/$deployment -n $namespace || {
        print_error "Deployment $deployment failed to become ready within ${timeout}s"
        kubectl describe deployment $deployment -n $namespace
        exit 1
    }
    print_success "Deployment $deployment is ready!"
}

print_status "🔧 Starting Kubernetes Monitoring Stack Setup..."

# Check prerequisites
print_status "Checking prerequisites..."
for cmd in kubectl helm docker; do
    if ! command_exists $cmd; then
        print_error "$cmd is not installed. Please run ./install_Helm_and_Docker_Desktop.sh first."
        exit 1
    fi
done

# Check if Kubernetes is running
if ! kubectl cluster-info >/dev/null 2>&1; then
    print_error "Kubernetes cluster is not accessible. Please ensure Docker Desktop Kubernetes is enabled."
    exit 1
fi

print_success "All prerequisites are satisfied!"

# Remove any existing cAdvisor container
if [ "$(docker ps -a -q -f name=cadvisor)" ]; then
    print_status "🧹 Removing existing cAdvisor container..."
    docker rm -f cadvisor
fi

# Start cAdvisor container
print_status "🚀 Launching cAdvisor (version v0.49.1)..."
docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8081:8080 \
  --detach=true \
  --name=cadvisor \
  --privileged \
  --device=/dev/kmsg \
  gcr.io/cadvisor/cadvisor:v0.49.1

# Wait for cAdvisor to be ready
sleep 5
if curl -s http://localhost:8081/healthz >/dev/null; then
    print_success "cAdvisor is running on port 8081."
else
    print_warning "cAdvisor health check failed, but continuing..."
fi

# Apply resource quotas and limits
print_status "📊 Applying resource quotas and limits..."
kubectl apply -f resource-quotas.yaml

# Apply main K8s project
print_status "📁 Applying Trucat Kubernetes project..."
kubectl apply -f Trucat-project.yaml

# Wait for main deployments to be ready
wait_for_deployment "truckat-node-redis-deployment"
wait_for_deployment "truckat-frontend-deployment"
wait_for_deployment "truckat-redis-deployment"
wait_for_deployment "truckat-redis-replica-deployment"

# Apply network policies
print_status "🔒 Applying network policies..."
kubectl apply -f network-policies.yaml

# Create monitoring namespace if it doesn't exist
print_status "📂 Creating 'monitoring' namespace..."
kubectl get namespace monitoring &> /dev/null || kubectl create namespace monitoring

# Add Helm repositories
print_status "🔁 Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics || true
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/ || true

# Update Helm repos
print_status "📥 Updating Helm repositories..."
helm repo update

# Install Metrics Server 
print_status "📊 Installing Metrics Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.1/components.yaml

# Patch metrics server to work with Docker Desktop
print_status "🔧 Patching Metrics Server for Docker Desktop compatibility..."
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]' || true

# Wait for metrics server
sleep 15
wait_for_deployment "metrics-server" "kube-system"

# Deploy Redis Exporter
print_status "📡 Deploying Redis Exporter..."
kubectl apply -f redis-exporter.yaml -n monitoring

# Install Prometheus Stack
print_status "📦 Installing kube-prometheus-stack via Helm..."
helm install kube-prom prometheus-community/kube-prometheus-stack -f prometheus-values.yaml -n monitoring

# Wait for Prometheus stack to be ready
print_status "⏳ Waiting for Prometheus stack to be ready..."
sleep 30

# Deploy Alerting Rules (after Prometheus is installed)
print_status "🚨 Deploying alerting rules..."
kubectl apply -f alerting-rules.yaml

# Function to wait for a specific pod to be in Running state
wait_for_pod_ready() {
    local pod_label=$1
    local namespace=$2
    local port=$3
    print_status "⏳ Waiting for a pod with label '$pod_label' in namespace '$namespace' to be Running..."

    for i in {1..30}; do
        pod_name=$(kubectl get pods -n "$namespace" -l "$pod_label" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        status=$(kubectl get pod "$pod_name" -n "$namespace" -o jsonpath='{.status.phase}' 2>/dev/null)

        if [ "$status" == "Running" ]; then
            print_success "$pod_name is Running. Proceeding with port-forward on port $port..."
            return 0
        fi

        print_status "⌛ Current status: $status. Retrying in 5s... (attempt $i/30)"
        sleep 5
    done

    print_error "Timed out waiting for pod with label $pod_label in namespace $namespace."
    exit 1
}

# Wait for specific pods before port forwarding
wait_for_pod_ready "app.kubernetes.io/name=grafana" monitoring 3000
wait_for_pod_ready "app.kubernetes.io/name=prometheus" monitoring 9090

# Set up port forwarding
print_status "🌐 Setting up port-forwarding..."
kubectl port-forward svc/kube-prom-kube-prometheus-prometheus 9090:9090 -n monitoring &
PROMETHEUS_PID=$!
kubectl port-forward svc/kube-prom-grafana 3000:80 -n monitoring &
GRAFANA_PID=$!

# Save PIDs for cleanup
echo $PROMETHEUS_PID > /tmp/prometheus_pid
echo $GRAFANA_PID > /tmp/grafana_pid

# Wait a moment for port forwarding to establish
sleep 3

# Health checks
print_status "🏥 Performing health checks..."

# Check Prometheus
if curl -s http://localhost:9090/-/healthy >/dev/null; then
    print_success "Prometheus is healthy and accessible at http://localhost:9090"
else
    print_warning "Prometheus health check failed"
fi

# Check Grafana
if curl -s http://localhost:3000/api/health >/dev/null; then
    print_success "Grafana is healthy and accessible at http://localhost:3000"
else
    print_warning "Grafana health check failed"
fi

# Check application endpoints
if curl -s http://localhost:8080/ >/dev/null; then
    print_success "Backend application is accessible at http://localhost:8080"
else
    print_warning "Backend application health check failed"
fi

# Display final status
print_success "🎉 Kubernetes Monitoring Stack Setup Complete!"
echo ""
print_status "Access URLs:"
echo "  📊 Prometheus: http://localhost:9090"
echo "  📈 Grafana: http://localhost:3000 (admin/prom-operator)"
echo "  🔧 Backend: http://localhost:8080"
echo "  🖥️  Frontend: http://localhost:7654"
echo "  📊 cAdvisor: http://localhost:8081"
echo ""
print_status "To clean up, run: ./clean.sh"
echo ""
print_status "Port forwarding PIDs saved. To stop port forwarding manually:"
echo "  kill \$(cat /tmp/prometheus_pid) \$(cat /tmp/grafana_pid)"

