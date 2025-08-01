# Projet AutoScaling et IaC

## PS: The first and beginning of the second part can be done through 2 scripts with the first one being optionnal

## Project Architecture :
![Alt Text](https://github.com/HuuTrucNguyen0508/Monitoring_et_Autoscaling_de_conteneurs/blob/main/PNG/Capture%20d%E2%80%99%C3%A9cran%20du%202024-11-07%2013-25-04.png)

## 🚀 New Features & Improvements

### Enhanced AutoScaling
- **Improved HPA Configuration**: Better scaling policies with memory-based scaling
- **Stabilization Windows**: Prevents rapid scaling up/down
- **Custom Scaling Behavior**: Configurable scale-up and scale-down policies

### Security Enhancements
- **Network Policies**: Restrict pod-to-pod communication
- **Resource Quotas**: Prevent resource exhaustion
- **Limit Ranges**: Default resource limits for containers

### Advanced Monitoring
- **Comprehensive Alerting**: 10+ alert rules for critical metrics
- **Enhanced Prometheus Config**: Better retention and storage
- **Auto-imported Dashboards**: Kubernetes, Node Exporter, and Redis dashboards
- **Health Check Script**: Quick system status overview

### Improved Scripts
- **Better Error Handling**: Colored output and detailed error messages
- **Health Checks**: Automatic validation of all components
- **Process Management**: Proper cleanup of port forwarding
- **Resource Validation**: Prerequisites checking

## I. Prerequisites and project setup

  - 1.Download Docker Desktop, Helm and the kubectl command line. It can be done with the provide script or you can do it by yourself
  
        ./install_Helm_and_Docker_Desktop.sh
    
  - 2.Go into the setting and enable the Kubernetes option for Docker Desktop:
    
![Alt Text](https://github.com/HuuTrucNguyen0508/Monitoring_et_Autoscaling_de_conteneurs/blob/main/PNG/K8s.png)

  - 3.And into the docker engine option, paste the following ip address:
    
![Alt Text](https://github.com/HuuTrucNguyen0508/Monitoring_et_Autoscaling_de_conteneurs/blob/main/PNG/Docker%20metrics.png)  

  - 4.After the cluster is enabled, just run the script and everything will be setup automatically:
    
        ./script.sh

      You should be able to access Prometheus and Grafana through localhost:9090 and localhost:3000 (enter Grafana with admin prom-operator as credential).

  - 5.Now, when you get into Prometheus and look into status then target, you should see all of the wanted endpoint and in Kubernetes, all of the pods, deployment and service running.

![Alt Text](https://github.com/HuuTrucNguyen0508/Monitoring_et_Autoscaling_de_conteneurs/blob/main/PNG/PromTarget.png)

![Alt Text](https://github.com/HuuTrucNguyen0508/Monitoring_et_Autoscaling_de_conteneurs/blob/main/PNG/k-get-all-monitoring.png)

![Alt Text](https://github.com/HuuTrucNguyen0508/Monitoring_et_Autoscaling_de_conteneurs/blob/main/PNG/k-get-all-default.png)

  - 6.The project can be cleaned up using a script:
    
        ./clean.sh

  - 7.Check system health:
    
        ./health-check.sh

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

## III. New Features Documentation

### AutoScaling Improvements
The system now includes enhanced Horizontal Pod Autoscalers with:
- **Memory-based scaling** in addition to CPU
- **Stabilization windows** to prevent thrashing
- **Configurable scaling policies** for different scenarios
- **Higher maximum replicas** for better scalability

### Security Features
- **Network Policies**: Control traffic between pods
- **Resource Quotas**: Limit resource consumption per namespace
- **Limit Ranges**: Set default resource limits

### Monitoring Enhancements
- **Alerting Rules**: Automatic alerts for critical conditions
- **Enhanced Dashboards**: Pre-configured Grafana dashboards
- **Health Monitoring**: Comprehensive health check script

### Script Improvements
- **Colored Output**: Better visual feedback
- **Error Handling**: Detailed error messages and recovery
- **Health Validation**: Automatic component validation
- **Process Management**: Proper cleanup and PID tracking

## IV. Access URLs

After deployment, you can access:
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/prom-operator)
- **Backend**: http://localhost:8080
- **Frontend**: http://localhost:7654
- **cAdvisor**: http://localhost:8081

## V. Troubleshooting

Use the health check script to diagnose issues:
```bash
./health-check.sh
```

This will provide a comprehensive overview of:
- Pod status
- Service availability
- Resource usage
- Recent events
- Network policies
- Metrics server status




