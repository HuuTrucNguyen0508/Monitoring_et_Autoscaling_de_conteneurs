#!/bin/bash

# Start Minikube
minikube start

# Enable metrics-server addon
minikube addons enable metrics-server

# Apply Trucat-project.yaml
kubectl apply -f Trucat-project.yaml

# Start minikube tunnel
minikube tunnel
