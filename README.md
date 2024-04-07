# Projet AutoScaling et IaC

## Download Docker Window (or the equivalent on the machine)

## I.Kubernetes: Install your prefered Kubernetes environment (MiniKube in my case)

  - 1.Start your Minikube:
  
        minikube start
    
  - 2.Install the metrics addons to monitor:
  
        minikube addons enable metrics-server
    
  - 3.Create all of your deployment and server:

        kubectl apply -f Trucat-project.yaml
    
  - 4.Expose your nodeJS and frontend:

        minikube tunnel 
    
    - 5.After a bit of waiting (so that the containers can pull the image start properly), you will now be able to access frontend and nodejs with localhost:7654 and localhost:8080. Every change will be recorded in the nodejs logs, accessible with:

          kubectl logs <nodejs-pod-name>

    - 6.To get all info including the % usage of the nodejs and redis replica server

          kubectl get all
  
   

## II.Prometheus and Grafana: 

  - 1.Install and run a container of Prometheus and Grafana 
    
        docker run --name prometheus -d -p 127.0.0.1:9090:9090 prom/prometheus ; docker run -d --name=grafana -p 3000:3000 grafana/grafana

      You should be able to acess to Prometheus and Grafana through localhost:9090 and localhost:3000 (enter Grafana with admin admin as credential)
  
  - 2.Get into the container of Prometheus to update the prometheus.yml: 
    
        docker exec -it prometheus /bin/sh -c 'cd /etc/prometheus && vi prometheus.yml && kill -HUP 1' 
        
  - 3.Once inside the prometheus.yml, copy the content and paste at the end to the prometheus.yml (following the same indentation as the one that is already there)

        - job_name: "WMI Exporter"
          static_configs:
            - targets: ["host.docker.internal:9182"]
    
        - job_name: "Grafana"
          static_configs:
            - targets: ["host.docker.internal:3000"]
    
        - job_name: "node-redis"
          static_configs:
            - targets: ["host.docker.internal:8080"]

  - 4.Save and exit the file then restart the container process

  - 5.Now, when you get into Prometheus and look into status then target, you should see all of the wanted endpoint

## III.In Grafana, create a new datasource: setting -> connection(on the left) -> datasource
  
  - 1.Add new datasource
    - a.Choose Prometheus datasource and in Prometheus server URL, paste:
      
            http://host.docker.internal:9090/

    - b.Save and test the datasource
        
  - 2.Create a new dashboard:
    - a.Go into dashboard and import an existing dashboard (use 11159 as the ID and load select the deefault Promeetheus as the datasource and import)
    - b.You will now be able the see differents metrics pertaining to the localhost:8080, which is our nodeJS deployment    



