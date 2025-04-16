# Projet AutoScaling et IaC

## PS: The first and beginning of the second part can be done through 2 scripts with the first one being optionnal

## Project Architecture :
![Alt Text](https://github.com/HuuTrucNguyen0508/Monitoring_et_Autoscaling_de_conteneurs/blob/main/PNG/Capture%20d%E2%80%99%C3%A9cran%20du%202024-11-07%2013-25-04.png)

## I. Prequisite and project setup

  - 1.Download Docker Desktop, Helm and the kubectl command line. It can be done with the provide script or you can do it by yourself
  
        ./install_Helm_and_Docker_Desktop.sh
    
  - 2.Go into the setting and enable the Kubernetes option for Docker Desktop:
    
![Alt Text](https://github.com/HuuTrucNguyen0508/Monitoring_et_Autoscaling_de_conteneurs/blob/main/PNG/K8s.png)

  - 3.And into the docker engine option, paste the following ip address:
    
![Alt Text](https://github.com/HuuTrucNguyen0508/Monitoring_et_Autoscaling_de_conteneurs/blob/main/PNG/Docker%20metrics.png)  

  - 4.After the cluster is enabled, just run the script and everything will be setup automatically:
    
        ./script.sh

      You should be able to acess to Prometheus and Grafana through localhost:9090 and localhost:3000 (enter Grafana with admin prom-operator as credential).

  - 5.Now, when you get into Prometheus and look into status then target, you should see all of the wanted endpoint and in Kubernetes, all of the pods, deployment and service running.

![Alt Text](https://github.com/HuuTrucNguyen0508/Monitoring_et_Autoscaling_de_conteneurs/blob/main/PNG/PromTarget.png)

![Alt Text](https://github.com/HuuTrucNguyen0508/Monitoring_et_Autoscaling_de_conteneurs/blob/main/PNG/k-get-all-monitoring.png)

![Alt Text](https://github.com/HuuTrucNguyen0508/Monitoring_et_Autoscaling_de_conteneurs/blob/main/PNG/k-get-all-default.png)

  - 6.The project can be cleaned up using a script:
    
        ./clean.sh

## II. In Grafana, create a new dashboard:

  - Create a new dashboard:
    - a.Go into dashboard and create a new dashbpard
    - b.Import an existing dashboard
      
    ![Alt Text](https://github.com/HuuTrucNguyen0508/Rendu_Projet_M1_Reseau_Huu_Truc_NGUYEN_21310174/blob/main/PNG/Screenshot%202024-04-07%20131145.png)
      - Use 11159 as the ID and load
        
        ![Alt Text](https://github.com/HuuTrucNguyen0508/Rendu_Projet_M1_Reseau_Huu_Truc_NGUYEN_21310174/blob/main/PNG/Screenshot%202024-04-07%20131156.png)
      - Select the default Prometheus as the datasource and import
        
        ![Alt Text](https://github.com/HuuTrucNguyen0508/Rendu_Projet_M1_Reseau_Huu_Truc_NGUYEN_21310174/blob/main/PNG/Screenshot%202024-04-07%20131238.png)
    - c.You will now be able the see differents metrics pertaining to the localhost:8080, which is our nodeJS deployment
      
      ![Alt Text](https://github.com/HuuTrucNguyen0508/Rendu_Projet_M1_Reseau_Huu_Truc_NGUYEN_21310174/blob/main/PNG/Screenshot%202024-04-07%20111011.png)

    - d.You could add other dashboard using [the Grafana community dashboard](https://grafana.com/grafana/dashboards/). Some example such as the Node Exporter Full or the Kubernetes/View/Global dashboards.
  




