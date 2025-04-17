#!/bin/bash

echo "🔧 Starting Kubernetes Monitoring Stack Setup..."

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "📦 Helm not found, installing..."
    curl -sSL https://get.helm.sh/helm-v3.11.2-linux-amd64.tar.gz -o helm.tar.gz
    tar -xzf helm.tar.gz
    sudo mv linux-amd64/helm /usr/local/bin/helm
    rm -rf linux-amd64 helm.tar.gz
    echo "✅ Helm installed successfully!"
else
    echo "⚠️ Helm is already installed. Skipping..."
fi

# Remove any existing cAdvisor container
if [ "$(docker ps -a -q -f name=cadvisor)" ]; then
    echo "🧹 Removing existing cAdvisor container..."
    docker rm -f cadvisor
fi

# Start cAdvisor container
echo "🚀 Launching cAdvisor (version v0.49.1)..."
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
echo "✅ cAdvisor is running on port 8081."

# Apply main K8s project
echo "📁 Applying Trucat Kubernetes project..."
kubectl apply -f Trucat-project.yaml

# Install Kubernetes Metrics Server
echo "📊 Installing Metrics Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.1/components.yaml

# Create monitoring namespace if it doesn't exist
echo "📂 Creating 'monitoring' namespace..."
kubectl get namespace monitoring &> /dev/null || kubectl create namespace monitoring

# Deploy Redis Exporter
echo "📡 Deploying Redis Exporter..."
kubectl apply -f redis-exporter.yaml -n monitoring

# Add Helm repositories
echo "🔁 Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics || true

# Update Helm repos
echo "📥 Updating Helm repositories..."
helm repo update

# Install Prometheus Stack
echo "📦 Installing kube-prometheus-stack via Helm..."
helm install kube-prom prometheus-community/kube-prometheus-stack -f prometheus-values.yaml -n monitoring

# Wait for all pods to be ready
echo "⏳ Waiting for all pods in 'monitoring' namespace to be ready (timeout: 10 mins)..."
kubectl wait --for=condition=ready pod --all --namespace=monitoring --timeout=600s

# Set up port forwarding
echo "🌐 Setting up port-forwarding..."
kubectl port-forward svc/kube-prom-kube-prometheus-prometheus 9090:9090 -n monitoring &
kubectl port-forward svc/kube-prom-grafana 3000:80 -n monitoring &

# Final message with figlet if available
if command -v figlet &> /dev/null; then
    figlet "Monitoring Ready!"
else
    echo "🎉 Monitoring stack is ready!"
fi

