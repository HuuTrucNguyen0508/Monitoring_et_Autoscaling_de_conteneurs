Projet AutoScaling et IaC

Download Docker Window (or the equivalent on the machine)

    - Pull the redis image: docker pull redis  

Kubernetes: Install your prefered Kubernetes environment (MiniKube in my case)

    - Start your Minikube: minikube start
    
    - Install the metrics addons to monitor: minikube addons enable metrics-server
    
    - Create all of your deployment and server: kubectl apply -f <file-name.yaml>
    
    - Expose your nodeJS and frontend: minikube tunnel (will need to keep that terminal open)
    
    - Will now be able to access frontend and nodejs with localhost:7654 and localhost:8080 (Every change will be recorded in the nodejs logs, accessible with kubectl logs <nodejs-pod-name>
    
    - kubectl get all   will get you all info including the % usage of the nodejs and redis replica server

Prometheus and Grafana: 

    - Install and run a container of Prometheus: docker run --name prometheus -d -p 127.0.0.1:9090:9090 prom/prometheus 
    
    - Install and run a container of Grafana: docker run -d --name=grafana -p 3000:3000 grafana/grafana
        - With this, you should be able to acess to Prometheus and Grafana through localhost:9090 and localhost:3000 (enter Grafana with admin admin credential)
        
    - Get into the container of Prometheus to update the prometheus.yml: docker exec -it prometheus /bin/sh
                                                                         cd /etc/prometheus
                                                                         vi prometheus.yml
        - Once inside the prometheus.yml, copy the content of the given prometheus_copy.yml and paste at the end to the prometheus.yml (following the same indentation as the one that is already there)
        - Save and exit the file then restart the container process: kill -HUP 1
                                                                     exit
        - Now, when you get into Prometheus and look into target, you should see all of the wanted endpoint
        
    - In Grafana, create a new datasource: setting, connection, datasource
        - Choose Prometheus datasource and in the url, write host.docker.internal:9090
        - Save and create the datasource
        
    - Create a new dashboard: Go into dashboard and import an existing dashboard (use 11159 and the code and chose the created Promeetheus datasource as the datasource)
      - You will now be able the see differents metrics pertaining to the localhost:8080, which is our nodeJS deployment    



