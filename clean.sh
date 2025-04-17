#!/bin/bash

echo "🧹 Starting cleanup of Kubernetes Monitoring Stack..."

# Function to check if a port is in use and kill the process if so
check_and_kill_port() {
    PORT=$1
    PID=$(sudo lsof -t -i:$PORT)
    if [ -n "$PID" ]; then
        echo "⚠️ Port $PORT is in use by process $PID. Terminating it..."
        sudo kill -9 $PID
        sleep 2
        echo "✅ Port $PORT is now free."
    else
        echo "✔️ Port $PORT is not in use."
    fi
}

# Stop and remove cAdvisor
echo "📦 Stopping and removing cAdvisor container (if running)..."
docker stop cadvisor &> /dev/null
docker rm cadvisor &> /dev/null
echo "✅ cAdvisor cleaned up."

# Uninstall Prometheus stack via Helm
echo "🧼 Uninstalling kube-prom Helm release..."
helm uninstall kube-prom -n monitoring || echo "⚠️ Helm release not found. Skipping..."

# Delete Redis exporter
echo "🗑️ Deleting Redis Exporter..."
kubectl delete -f redis-exporter.yaml -n monitoring || echo "⚠️ Redis Exporter not found."

# Delete monitoring namespace
echo "📂 Deleting 'monitoring' namespace..."
kubectl delete namespace monitoring || echo "⚠️ Namespace already deleted or not found."

# Delete main project resources
echo "🧨 Removing Trucat project resources..."
kubectl delete -f Trucat-project.yaml || echo "⚠️ Trucat project resources not found."

# Free up ports used for port-forwarding
echo "🔌 Checking ports and killing if in use..."
check_and_kill_port 9090
check_and_kill_port 3000

# Final goodbye banner
if command -v figlet &> /dev/null; then
    figlet "Cleanup Done!"
else
    echo "🎉 Cleanup complete!"
fi

