# Projet AutoScaling et IaC

## Download Docker Window (or the equivalent on the machine)

## Kubernetes: Install your prefered Kubernetes environment (MiniKube in my case)

    - Start your Minikube: minikube start
    
    - Install the metrics addons to monitor: minikube addons enable metrics-server
    
    - Create all of your deployment and server: kubectl apply -f <file-name.yaml>
    
    - Expose your nodeJS and frontend with minikube tunnel (will need to keep that terminal open)
    
    - You will now be able to access frontend and nodejs with localhost:7654 and localhost:8080 (Every change will be recorded in the nodejs logs, accessible with kubectl logs <nodejs-pod-name>
    
    - use   kubectl get all   to get all info including the % usage of the nodejs and redis replica server

## Prometheus and Grafana: 
    - Install and run a container of Prometheus and Grafana 
    
    docker run --name prometheus -d -p 127.0.0.1:9090:9090 prom/prometheus ; docker run -d --name=grafana -p 3000:3000 grafana/grafana

### You should be able to acess to Prometheus and Grafana through localhost:9090 and localhost:3000 (enter Grafana with admin admin as credential)
  - Get into the container of Prometheus to update the prometheus.yml: 
    
        docker exec -it prometheus /bin/sh -c 'cd /etc/prometheus && vi prometheus.yml && kill -HUP 1' 
        
### Once inside the prometheus.yml, copy the content and paste at the end to the prometheus.yml (following the same indentation as the one that is already there)

      - job_name: "WMI Exporter"
        static_configs:
          - targets: ["host.docker.internal:9182"]
    
      - job_name: "Grafana"
        static_configs:
          - targets: ["host.docker.internal:3000"]
    
      - job_name: "node-redis"
        static_configs:
          - targets: ["host.docker.internal:8080"]

### Save and exit the file then restart the container process

- Now, when you get into Prometheus and look into status then target, you should see all of the wanted endpoint\n        
In Grafana, create a new datasource: setting -> connection(on the left) -> datasource
  - Add new datasource
    - Choose Prometheus datasource and in Prometheus server URL, paste http://host.docker.internal:9090/
    - Save and test the datasource
        
    - Create a new dashboard: Go into dashboard and import an existing dashboard (use 11159 as the ID and load select the deefault Promeetheus as the datasource and import)
      - You will now be able the see differents metrics pertaining to the localhost:8080, which is our nodeJS deployment    



