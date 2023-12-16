# Recipe Generation from Food Image D10
### December 16, 2023
### Pipelines, Spice, and All Things Nice

## Table of Contents
- [Purpose](#purpose)
- [Demo](#demo)
- [Jenkins Infrastructure](#jenkins-infrastructure)
- [Terraform](#terraform)
- [EKS and Kubernetes](#eks-and-kubernetes)
- [Dockerfile](#dockerfile)
- [Application Stack](#application-stack)
- [Monitoring and Notification](#monitoring-and-notification)
- [Troubleshooting](#troubleshooting)
- [Optimization](#optimization)
- [Conclusion](#conclusion)

## Demo:
![Recipe_Generation gif](https://user-images.githubusercontent.com/55757415/124395585-8d0d0780-dd22-11eb-86fe-3a23d921b608.gif)
![diagram]()

## Purpose
The Recipe Generator Application is an advanced solution designed to enhance culinary creativity and accessibility, deployed across AWS's East and West regions to ensure high availability and optimal performance. This application's heart is Elastic Kubernetes Service (EKS), which facilitates efficient container orchestration and management, enabling the application to scale seamlessly and maintain robust deployment. The integration of AWS Lambda Functions allows the application to leverage serverless computing capabilities for responsive, event-driven functionality. Monitoring and operational insights are provided through Amazon CloudWatch, ensuring the application's health and performance are constantly overseen. The infrastructure setup, managed through Terraform, employs infrastructure as code principles to achieve reliable and consistent cloud environment deployments. Continuous integration and deployment processes are automated using Jenkins Webhook, enabling rapid and consistent updates. The application utilizes a Redis Database for data handling, which offers high-performance data access and caching, significantly improving response times and overall user experience. Additionally, background job processing is optimized by a Celery Worker, managing asynchronous task queues to maintain application responsiveness. The culmination of these technologies provides an intuitive and engaging platform for users to discover and create recipes, offering a resilient, scalable, and user-friendly tool for culinary enthusiasts at all levels.

# Jenkins Infrastructure
Jenkins stands out as a versatile open-source automation server known for its flexible CI/CD pipelines. With an expansive plugin ecosystem, Jenkins seamlessly integrates with various tools and facilitates distributed builds, optimizing efficiency, especially for large-scale projects. Jenkins' platform independence and active community contribute to its popularity.

In this deployment, the workload has been distributed to two worker nodes, one per region:

- `agent`: Provisions application infrastructure, creates clusters and node groups and applies all required YAML files.
- `agent2`: Provisions application infrastructure, creates clusters and node groups, applies all required YAML files, and establishes VPC peering.

<details>
  <summary><strong>Steps</strong></summary>

1. **Install Jenkins:**
   - Execute the `agent.sh` script to automatically install the required files.

2. **Generate Key Pairs:**
   - Create a new key pair with PEM on AWS EC2; the secret key is required for agent SSH creation.
   - Save the private key.

3. **Set Up Agents:**
   - Create a new node in Jenkins (Dashboard -> nodes).
   - Specify the name and location of the code directory.
   - Select "Launch agent via SSH" using the saved private key.
   - The host will be the public IP of the agent instance (agent/agent2).
   - Create credentials by entering the private key directly.
   - Save and check the log to verify agent status.
   - Create a second node with the same configuration; the only change should be the public IP.

4. **Configure AWS Credentials:**
   - In Jenkins server:
     - Go to "Manage Jenkins" -> "Credentials" -> "System" -> "Global credentials (unrestricted)".
     - Create 2 credentials (access and secret key) using "Secret text" - one for access key and the secret key.

5. **Create a Multi-Branch Pipeline:**
   - Create a new Jenkins item and select "Multi-branch pipeline."
   - Configure Jenkins Credentials Provider as needed.
   - Copy and import the Repository URL where the application source code resides.
   - Use your GitHub username and the generated key from GitHub as your credentials.

**Note:** To give Terraform access to the AWS account, both access and secret keys must be included. Since GitHub is the Source Code Management (SCM), this part of the Terraform file cannot be included. Instead, AWS keys will be stored securely in Jenkins.
</details>


## Terraform
Terraform, an open-source Infrastructure as Code (IaC) tool, simplifies infrastructure management with its declarative configuration language. It supports multiple cloud providers and enables efficient provisioning. Due to Terraform's capabilities, the automation of provisioning becomes straightforward, allowing for seamless and consistent deployment of infrastructure resources.

<details>
  <summary><strong>Jenkins Environment (jenkins.tf)</strong></summary>

### EC2 (Jenkins Manager)
- The `jenkins.sh` script automates the installation of the Jenkins application on an EC2 instance.

### EC2 (Agent)
- An agent is created with 4GB extra storage.
- The `agent.sh` script installs dependencies for the agent, including Docker, Terraform, AWS CLI, EKSCTL, and kubectl.
- This agent is tasked with deploying in the east region.

### EC2 (Agent2)
- Similar to the first agent, this agent is created with 4GB extra storage.
- The `agent.sh` script installs dependencies for the agent, including Docker, Terraform, AWS CLI, EKSCTL, and kubectl.
- This agent is created to deploy in the west region.
</details>

<details>
  <summary><strong>Application Environment (vpc.tf)</strong></summary>

- A `vpc.tf` file was created for the east and west regions, increasing availability and lowering latency.
- Components include:
  - **Virtual Private Cloud (VPC):** The networking framework that manages resources.
  - **Availability Zones (2 AZs):** Providing redundancy and fault tolerance by distributing resources across different AZs.
  - **2 Public Subnets**
  - **2 Private Subnets:** Subnets isolated from the public internet, for sensitive data.
  - **NAT Gateway:** A network gateway for egress traffic from private subnets to the internet.
  - **2 Route Tables:** Routing rules for traffic between subnets.
  - **Internet Gateway**
  - **NAT Gateway**
</details>

<details>
  <summary><strong>Peering Connection (main.tf)</strong></summary>

- Since a Redis database is being utilized to cache recipes, a peering connection is required to sync the database and display the same information regardless of the user's region.
- Components include:
  - VPC peering connection
  - VPC peering connection accepter
  - Route from east to west
  - Route from west to east
  - Security group rule (Port 6379)
</details>
</details>


###Kubernetes

The manifest files for the kubernetes cluster are executed in each region's pipeline in the DeployEKS stage. The shell files are [cluster.sh](./East/cluster.sh) and [clusterw.sh](!https://github.com/elmorenox/kura-final-team3/blob/west/west/clusterw.sh) and in the [west](!https://github.com/elmorenox/kura-final-team3/tree/west/west) branch.

The manifest files are in [./kubernetes](./kuber) in the main branch and in [./kubernetes](!https://github.com/elmorenox/kura-final-team3/tree/west/kubernetes) in the west branch. 

Cluster architecture

![cluster infra](./kubernetes-nodes/png)

Components:
1. ```kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds"``` 
- Dowloads the Custome Resource Definition for the controller that manages ingress resources and load balancers to those ingress
2. ```IngressClass.yaml``` used for application load balancers
3. ```v2_4_7_full.yaml``` used to extend the KUbernetes API for to manage the load balancer controller
4. ```ingress.yaml``` listens for traffic from the load balancer and brings in the traffic to the nodes
5. ```nginx-config.yaml``` defines the configration file for the nginx proxy deployment
6. ```nginx-proxy-service.yaml``` listens for traffic from the ingress objects and targets the nginx pods
7. ```recipe-generator-service.yaml``` listens for traffic from the nginx proxy and targets the Flask application for the recipe generator 
8. ```nginx-deployment.yaml``` listens for traffic defines how the nginx image will be used
9. ```redis-leader-stateful.yaml``` defines how the redis leader image on the  cluster in the eastern region will be ued
10. ```celery-deployment.yaml``` defines how the image for the celery worker will be used
11. ```recipe-generator-hpa.yaml``` defines how the Flask recipe generator will be scaled
       

###Docker
We used Dockerfile to create custom images of the FLask [recipe generator application](./Dockerfile) and the [Celery worker application](./CeleryWorker/Dockerfile) 

These images were manually pushed to personal Docker Hum repositories and referenced the yaml for the deployments

Application Stack

The stack for this system is made up four main applications NGINX, Flask, Redis, and Celery.

1. Flask is used for the Food2Image application. It is a standard FLask application using Jinja templates for the frontend and views (routes) to the backend. We coded an extra route so that recently recipes and saved to database and presented on the home page
2. NGINX is used as a proxy in front of the Recipe Generator and helps to cache the homepage to reduce latenxy
3. Redis is used a database to cache a list of recently generator recipes and their ingridients
4. Celery is used as a worker that handle the task of writing to the database and helps reduce the responsibilities of the FLask application

The Celery worker can be thought of as the cook that waits for order the waiter (redis) cooks the food and returns it back to the waiter (redis where the list of recipes is saved). Here the application would be the customer that orders from the menu defined by the cook.

###Monitoring and Notificaiton

We use the Cloudwatch add on for EKS which allows insights into the containers in the pod. This is manual set up process. We used the 'pod_status_terminated' so that we can know when the Redis leader on the eastern region is terminated. Knowing when the Redis leader is terminated is important because the Pod IP of Redis leader is configured in the configuration for the Redis follwer pod in the west

## Troubleshooting

## Optimization
Multi-Cluster Service Discovery: By implementing multi-cluster service discovery, our application architecture has been refined to allow seamless referencing of services by their names, instead of relying on IP addresses. This approach not only simplifies the configuration but also enhances the maintainability and scalability of the application across multiple clusters. It eliminates the need for constant updates whenever service IPs change, thereby reducing overhead and potential for errors.

Screen Reading Feature for Visually Impaired Users: In our commitment to making the application inclusive and accessible, we have integrated a screen reading feature specifically designed for visually impaired users. This feature enables these users to access our diverse range of recipes with ease. By providing auditory descriptions and instructions, the application becomes more user-friendly and accessible to a broader audience, ensuring that everyone can participate in the joy of cooking and recipe discovery.

DNS Resolver with Health Status Check: To ensure high availability and consistent user experience, we've incorporated a DNS resolver equipped with health status checks. This system continuously monitors the health of our services and dynamically routes traffic to the healthiest endpoints. This optimization not only enhances the reliability of the application but also ensures that users experience minimal downtime and receive the fastest possible response times.


## Conclusion
