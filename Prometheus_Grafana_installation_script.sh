#!/bin/bash

# Run Prometheus container
docker run --name prometheus -d -p 127.0.0.1:9090:9090 prom/prometheus

# Run Grafana container
docker run -d --name=grafana -p 3000:3000 grafana/grafana

