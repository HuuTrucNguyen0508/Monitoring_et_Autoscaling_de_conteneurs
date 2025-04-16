#!/bin/bash

# Check if Helm is installed
if ! command -v helm &> /dev/null
then
    echo "Helm not found, installing Helm..."
    # Install Helm
    curl https://get.helm.sh/helm-v3.11.2-linux-amd64.tar.gz -o helm.tar.gz
    tar -xvzf helm.tar.gz
    sudo mv linux-amd64/helm /usr/local/bin/helm
    rm -rf linux-amd64 helm.tar.gz
else
    echo "Helm is already installed"
fi

# Remove any existing cadvisor container if it exists
if [ "$(docker ps -a -q -f name=cadvisor)" ]; then
    echo "Removing existing cadvisor container..."
    docker rm -f cadvisor
fi

# Pull the cadvisor container
VERSION=v0.49.1
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
  gcr.io/cadvisor/cadvisor:$VERSION

# Running the main k8s project
kubectl apply -f Trucat-project.yaml

# Installing k8s metric server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.1/components.yaml

# Creating the monitoring namespace
kubectl create namespace monitoring

# Add Helm repos if not already added
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics || true

# Update repos
helm repo update

# Installing the helm prometheus chart and applying the job
helm install redi-prom prometheus-community/prometheus-redis-exporter -n monitoring
helm install kube-prom prometheus-community/kube-prometheus-stack -f prometheus-values.yaml -n monitoring

kubectl port-forward svc/kube-prom-kube-prometheus-prometheus 9090:9090 -n monitoring &
kubectl port-forward svc/kube-prom-grafana 3000:80 -n monitoring &

