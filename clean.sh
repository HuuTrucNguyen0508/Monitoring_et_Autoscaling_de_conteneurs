#!/bin/bash

# Function to check if a port is in use and kill the process if so
check_and_kill_port() {
    PORT=$1
    # Check if the port is in use
    PID=$(sudo lsof -t -i:$PORT)
    if [ -n "$PID" ]; then
        echo "Port $PORT is in use by process $PID. Killing it..."
        sudo kill -9 $PID
        # Wait a moment to ensure the process is killed
        sleep 2
    else
        echo "Port $PORT is not in use."
    fi
}

docker stop cadvisor
docker rm cadvisor

helm uninstall kube-prom -n monitoring

kubectl delete -f redis-exporter.yaml -n monitoring
kubectl delete namespace monitoring
kubectl delete -f Trucat-project.yaml

check_and_kill_port 9090
check_and_kill_port 3000
