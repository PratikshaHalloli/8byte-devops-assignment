# 8Byte DevOps Assignment

A complete DevOps implementation for a Node.js/Express application deployed on **Amazon EKS**, with AWS infrastructure provisioned using **Terraform** and application delivery automated through **Jenkins CI/CD**.

The project demonstrates an end-to-end workflow including source checkout, dependency installation, automated testing, dependency vulnerability scanning, Docker image creation, container vulnerability scanning using Trivy, Amazon ECR image publishing, Kubernetes deployment, staging validation, manual production approval, and production deployment.

---

# 1. Project Overview

The purpose of this project is to demonstrate a practical DevOps workflow for building, testing, securing, containerizing, and deploying a web application in AWS.

The application is a lightweight Node.js/Express service that exposes a health endpoint:

```text
GET /health
```

The application is packaged as a Docker container and deployed to an Amazon EKS cluster using Kubernetes manifests.

Terraform is used to provision the required AWS infrastructure, while Jenkins automates the application delivery lifecycle.

The overall workflow is:

```text
Developer
    │
    ▼
Git Repository
    │
    ▼
Jenkins
    │
    ├── Checkout Source
    │
    ├── Install Dependencies
    │
    ├── Dependency Security Scan
    │
    ├── Automated Tests
    │
    ├── Code Analysis
    │
    ├── Docker Build
    │
    ├── Trivy Container Scan
    │
    ├── Login to Amazon ECR
    │
    ├── Push Docker Image
    │
    ├── Deploy to Staging
    │
    ├── Smoke Test
    │
    ├── Manual Approval
    │
    └── Deploy to Production
    │
    ▼
Amazon EKS
    │
    ▼
Kubernetes Pods
    │
    ▼
LoadBalancer
    │
    ▼
Application
```

---

# 2. Architecture

```text
                         AWS CLOUD
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│                         VPC                                  │
│                                                              │
│   ┌──────────────────────────────────────────────────────┐   │
│   │                    Amazon EKS                        │   │
│   │                                                      │   │
│   │   ┌──────────────────┐     ┌──────────────────┐      │   │
│   │   │  8byte-app Pod   │     │  8byte-app Pod   │      │   │
│   │   │    Replica 1     │     │    Replica 2     │      │   │
│   │   └────────┬─────────┘     └────────┬─────────┘      │   │
│   │            │                        │                │   │
│   │            └───────────┬────────────┘                │   │
│   │                        │                             │   │
│   │                 Kubernetes Service                  │   │
│   │                    LoadBalancer                     │   │
│   └────────────────────────┬─────────────────────────────┘   │
│                            │                                 │
│                            ▼                                 │
│                       AWS ELB                               │
│                            │                                 │
└────────────────────────────┼─────────────────────────────────┘
                             │
                             ▼
                          Internet
```

The deployment uses two application replicas to provide basic redundancy and availability.

The Kubernetes Service is configured as a `LoadBalancer`, which provisions an AWS load balancer and exposes the application externally.

---

# 3. Technology Stack

| Component              | Technology        |
| ---------------------- | ----------------- |
| Application            | Node.js           |
| Framework              | Express.js        |
| Testing                | Jest + Supertest  |
| Containerization       | Docker            |
| Container Registry     | Amazon ECR        |
| Orchestration          | Kubernetes        |
| Kubernetes Platform    | Amazon EKS        |
| Infrastructure as Code | Terraform         |
| CI/CD                  | Jenkins           |
| Dependency Security    | npm audit         |
| Container Security     | Trivy             |
| Cloud Platform         | AWS               |
| Container Runtime      | Docker            |
| CLI                    | AWS CLI / kubectl |

---

# 4. Repository Structure

```text
8byte-devops-assignment/
│
├── Jenkinsfile
├── README.md
│
├── app/
│   ├── index.js
│   ├── package.json
│   ├── package-lock.json
│   ├── Dockerfile
│   │
│   └── test/
│       └── app.test.js
│
├── k8s/
│   ├── deployment.yaml
│   └── service.yaml
│
└── terraform/
    ├── backend.tf
    ├── vpc.tf
    ├── eks.tf
    ├── rds.tf
    ├── ecr.tf
    ├── sg.tf
    ├── irsa.tf
    ├── secrets.tf
    ├── variables.tf
    └── outputs.tf
```

---

# 5. Application

The application is implemented using Node.js and Express.

The main application entry point is:

```text
app/index.js
```

The application exposes a health endpoint:

```text
GET /health
```

A successful request returns an HTTP `200` response and indicates that the application is healthy.

Example:

```json
{
  "status": "UP",
  "timestamp": "2026-08-31T21:52:11.634Z"
}
```

The health endpoint is also used for deployment verification and smoke testing.

---

# 6. Local Application Setup

Install the application dependencies:

```bash
cd app
npm install
```

Start the application:

```bash
npm start
```

The application can then be tested using:

```bash
curl http://localhost:8080/health
```

Expected result:

```json
{
  "status": "UP"
}
```

---

# 7. Automated Testing

The project uses **Jest** and **Supertest** for automated application testing.

The tests are located under:

```text
app/test/
```

Current test:

```text
app/test/app.test.js
```

The test verifies that the `/health` endpoint responds correctly.

Run the tests:

```bash
npm test
```

Successful execution:

```text
PASS  test/app.test.js

Test Suites: 1 passed, 1 total
Tests:       1 passed, 1 total
```

The Jenkins pipeline executes these tests automatically before the Docker image is created.

This ensures that a failed application test prevents the application from progressing through the deployment pipeline.

---

# 8. Dependency Vulnerability Scanning

The pipeline performs dependency vulnerability scanning using npm's built-in audit functionality.

Command:

```bash
npm audit --audit-level=high
```

This checks the project's dependency tree for known security vulnerabilities.

During local validation, the application dependencies returned:

```text
found 0 vulnerabilities
```

The Jenkins pipeline is configured to treat high-severity dependency vulnerabilities as a pipeline failure.

This prevents an application with unacceptable dependency vulnerabilities from automatically progressing to the container build and deployment stages.

---

# 9. Docker Containerization

The application is containerized using Docker.

The Dockerfile is located at:

```text
app/Dockerfile
```

The image is built using:

```bash
docker build -t 8byte-app:latest ./app
```

The container can be tested locally:

```bash
docker run -p 8080:8080 8byte-app:latest
```

Then:

```bash
curl http://localhost:8080/health
```

The Docker image is used as the deployment artifact throughout the CI/CD pipeline.

---

# 10. Container Security Scanning

After the Docker image is built, the Jenkins pipeline performs a vulnerability scan using **Trivy**.

Trivy is installed on the Jenkins execution environment.

Verified tooling:

```text
Trivy: 0.74.0
Docker: 29.1.3
AWS CLI: 2.36.34
kubectl: v1.37.0
```

The pipeline scans the built image before publishing it to Amazon ECR.

Example:

```bash
trivy image \
  --severity HIGH,CRITICAL \
  --no-progress \
  8byte-app:${BUILD_NUMBER}
```

The purpose of this stage is to identify vulnerable operating-system packages and application dependencies contained within the final Docker image.

The security scan occurs before the ECR push so that the pipeline can prevent vulnerable images from being published.

---

# 11. Amazon ECR

Amazon Elastic Container Registry is used as the private Docker registry for the application.

The repository is:

```text
8byte-app
```

Jenkins authenticates with ECR using the AWS CLI:

```bash
aws ecr get-login-password --region us-east-1 \
| docker login \
  --username AWS \
  --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

The Docker image is tagged using the Jenkins build number:

```text
<AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/8byte-app:<BUILD_NUMBER>
```

A `latest` tag can also be maintained for convenience.

Using the Jenkins build number provides a unique image version for each pipeline execution and makes it possible to identify which build was deployed.

---

# 12. Terraform Infrastructure

Terraform is used as Infrastructure as Code to define and provision AWS resources.

The Terraform configuration is located in:

```text
terraform/
```

The infrastructure configuration is divided into logical files:

```text
vpc.tf
    ↓
Network infrastructure

eks.tf
    ↓
Amazon EKS cluster and node group

ecr.tf
    ↓
Amazon ECR repository

rds.tf
    ↓
Database infrastructure

sg.tf
    ↓
Security groups

irsa.tf
    ↓
IAM / OIDC configuration

secrets.tf
    ↓
AWS Secrets Manager configuration
```

This structure keeps the infrastructure modular and easier to maintain.

---

# 13. Terraform Workflow

Initialize Terraform:

```bash
cd terraform
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Create an execution plan:

```bash
terraform plan
```

Apply the infrastructure:

```bash
terraform apply
```

Terraform state is configured using the backend defined in:

```text
terraform/backend.tf
```

The infrastructure should be managed through Terraform rather than manually creating individual AWS resources whenever possible.

---

# 14. Amazon EKS

The application is deployed to an Amazon EKS cluster.

After the cluster is created, configure kubectl:

```bash
aws eks update-kubeconfig \
  --name <EKS_CLUSTER_NAME> \
  --region us-east-1
```

Verify the nodes:

```bash
kubectl get nodes
```

Example:

```text
NAME                           STATUS
ip-10-0-10-139.ec2.internal    Ready
ip-10-0-11-48.ec2.internal     Ready
```

---

# 15. Kubernetes Deployment

The Kubernetes resources are defined under:

```text
k8s/
```

The deployment is defined in:

```text
k8s/deployment.yaml
```

The application is configured with two replicas.

Deploy the application:

```bash
kubectl apply -f k8s/
```

Check the deployment:

```bash
kubectl get deployment
```

Expected result:

```text
NAME        READY   UP-TO-DATE   AVAILABLE
8byte-app   2/2     2            2
```

Check the pods:

```bash
kubectl get pods -o wide
```

Example:

```text
NAME                        READY   STATUS    RESTARTS
8byte-app-767b7774c-7ls2r   1/1     Running   0
8byte-app-767b7774c-qffzp   1/1     Running   0
```

This confirms that both application replicas are running successfully.

---

# 16. Kubernetes Service

The application is exposed using a Kubernetes `LoadBalancer` Service.

Check the service:

```bash
kubectl get svc
```

Example:

```text
NAME                TYPE           CLUSTER-IP       EXTERNAL-IP
app-8byte-service   LoadBalancer   172.20.148.179   <AWS-ELB-HOSTNAME>
```

The `LoadBalancer` type causes AWS to provision an external load balancer that routes traffic to the application pods.

---

# 17. Deployment Verification

Kubernetes rollout status is checked using:

```bash
kubectl rollout status deployment/8byte-app
```

Successful result:

```text
deployment "8byte-app" successfully rolled out
```

This confirms that Kubernetes successfully updated the deployment and that the required replicas became available.

---

# 18. Application Smoke Test

After deployment, the externally accessible LoadBalancer endpoint is tested.

Example:

```bash
curl http://<LOAD_BALANCER_HOSTNAME>/health
```

Successful response:

```json
{
  "status": "UP",
  "timestamp": "2026-08-31T21:52:11.634Z"
}
```

This verifies the complete request path:

```text
Internet
   ↓
AWS LoadBalancer
   ↓
Kubernetes Service
   ↓
EKS Pod
   ↓
Node.js Application
   ↓
/health
```

---

# 19. Jenkins CI/CD Pipeline

The complete CI/CD workflow is defined in:

```text
Jenkinsfile
```

The pipeline automates the application lifecycle from source code to Kubernetes deployment.

The pipeline stages are:

```text
1. Checkout
       ↓
2. Install Dependencies
       ↓
3. Dependency Security Scan
       ↓
4. Automated Tests
       ↓
5. Code Analysis
       ↓
6. Docker Build
       ↓
7. Trivy Security Scan
       ↓
8. Login to Amazon ECR
       ↓
9. Push Docker Image
       ↓
10. Deploy to Staging
       ↓
11. Smoke Test Staging
       ↓
12. Manual Production Approval
       ↓
13. Deploy to Production
```

---

# 20. Pipeline Stage Details

## Stage 1 — Checkout

Jenkins checks out the latest application source code from the Git repository.

This ensures that every pipeline execution operates on a specific version of the source code.

---

## Stage 2 — Install Dependencies

Jenkins installs Node.js application dependencies:

```bash
npm install
```

This ensures that the environment contains all packages required to build and test the application.

---

## Stage 3 — Dependency Security Scan

Jenkins runs:

```bash
npm audit --audit-level=high
```

The stage checks the application dependencies for known security vulnerabilities.

A high-severity vulnerability can cause the pipeline to fail.

---

## Stage 4 — Automated Tests

Jenkins executes:

```bash
npm test
```

Jest and Supertest validate the application's functionality.

If the tests fail, later deployment stages are skipped.

---

## Stage 5 — Code Analysis

The pipeline contains a dedicated code-analysis stage.

The purpose of this stage is to provide a location for static code-quality analysis before the application is packaged.

A production implementation can connect this stage to SonarQube or SonarCloud.

---

## Stage 6 — Docker Build

The application image is built:

```bash
docker build -t 8byte-app:${BUILD_NUMBER} ./app
```

The Jenkins build number is used as the image version.

---

## Stage 7 — Trivy Security Scan

The newly created Docker image is scanned:

```bash
trivy image \
  --severity HIGH,CRITICAL \
  --no-progress \
  8byte-app:${BUILD_NUMBER}
```

This ensures the image is scanned before it is published to ECR.

---

## Stage 8 — ECR Login

Jenkins authenticates with Amazon ECR using AWS CLI credentials configured on the Jenkins environment.

```bash
aws ecr get-login-password --region us-east-1
```

The resulting authentication token is passed to Docker.

---

## Stage 9 — Push Docker Image

The image is tagged with the ECR repository URI and pushed to Amazon ECR.

Example:

```text
8byte-app:42
       ↓
AWS ECR
       ↓
8byte-app:42
```

The build-number tag provides traceability between a Jenkins build and the corresponding container image.

---

## Stage 10 — Deploy to Staging

Jenkins applies the Kubernetes manifests:

```bash
kubectl apply -f k8s/
```

The deployment is then verified:

```bash
kubectl rollout status deployment/8byte-app
```

---

## Stage 11 — Staging Smoke Test

The staging application is verified using the health endpoint.

Example:

```bash
curl http://<LOAD_BALANCER_HOSTNAME>/health
```

Expected:

```json
{
  "status": "UP"
}
```

This provides a basic end-to-end validation before production deployment.

---

## Stage 12 — Manual Production Approval

The pipeline pauses before production.

```text
Staging
   ↓
Smoke Test
   ↓
Manual Approval
   ↓
Production
```

Jenkins requires an authorized user to approve the deployment.

This prevents an unattended pipeline from automatically deploying every successful build to production.

---

## Stage 13 — Production Deployment

After manual approval, Jenkins applies the Kubernetes configuration for the production deployment.

```bash
kubectl apply -f k8s/
```

The rollout can then be verified using:

```bash
kubectl rollout status deployment/8byte-app
```

---

# 21. Failure Handling

The pipeline is designed so that a failure in an earlier quality or security stage prevents later deployment stages from executing.

For example:

```text
npm test fails
     ↓
Pipeline fails
     ↓
Docker build skipped
     ↓
ECR push skipped
     ↓
Deployment skipped
```

Similarly:

```text
Trivy scan fails
     ↓
Pipeline fails
     ↓
ECR push skipped
     ↓
Deployment skipped
```

This prevents known failures from progressing through the delivery pipeline.

---

# 22. Security Practices

Several security controls are incorporated into the project.

### Dependency Security

Application dependencies are scanned using:

```bash
npm audit --audit-level=high
```

### Container Security

Docker images are scanned using Trivy for HIGH and CRITICAL vulnerabilities.

### AWS IAM

AWS IAM is used to control access to AWS resources.

### Kubernetes

Application workloads are deployed through Kubernetes resources rather than manually running containers on EC2.

### Secrets

Sensitive credentials should not be committed to source control.

Where database integration is used, AWS Secrets Manager and IAM-based access can be used to securely provide application credentials.

### Non-Root Container

The Dockerfile is designed to run the Node.js application using a non-root user, reducing the impact of a potential container compromise.

---

# 23. Network Architecture

The AWS infrastructure is designed around network separation.

```text
                    VPC
                     │
          ┌──────────┴──────────┐
          │                     │
     Public Subnets        Private Subnets
          │                     │
     Load Balancer          EKS Nodes
                                │
                                ▼
                              Pods
```

Public-facing components can receive external traffic, while compute and data resources can be placed in private subnets.

This reduces the direct exposure of internal infrastructure to the public internet.

---

# 24. Infrastructure as Code Benefits

Terraform provides several benefits for this project:

* Infrastructure is version controlled.
* AWS resources can be recreated consistently.
* Infrastructure changes can be reviewed before deployment.
* Configuration is separated into logical Terraform files.
* Manual configuration is reduced.
* The environment can be reproduced more easily.

The standard Terraform workflow is:

```text
terraform init
       ↓
terraform validate
       ↓
terraform plan
       ↓
terraform apply
```

---

# 25. Cost Optimization

Because this project is designed for an assignment/demo environment, infrastructure should be kept small.

Cost optimization considerations include:

* Small EKS node group
* Limited number of worker nodes
* Small RDS instance where database functionality is required
* Single NAT Gateway for non-production environments
* Limited RDS backup retention
* Avoiding unnecessary AWS resources
* Destroying unused infrastructure after testing

For production workloads, high availability and resilience should take priority over the minimum possible cost.

---

# 26. Monitoring and Logging

The application exposes a `/health` endpoint that provides a basic application health signal.

The Kubernetes deployment can be extended with:

* Liveness probes
* Readiness probes
* Prometheus metrics
* Grafana dashboards
* Centralized logging
* Loki/Fluent Bit
* CloudWatch integration
* Alerting

For a production environment, application, infrastructure, and Kubernetes metrics should be monitored continuously.

---

# 27. Backup and Disaster Recovery

Where a database is deployed using Amazon RDS, automated backups should be enabled.

For a staging/demo environment, a short retention period can be used to control costs.

For production, the recommended approach would include:

* Longer automated backup retention
* Manual snapshots before major changes
* Multi-AZ database deployment where required
* Cross-region backup copies for disaster recovery
* Documented restore procedures
* Periodic restore testing

A backup strategy should be validated by actually performing restoration tests rather than relying only on backup configuration.

---

# 28. Validation Performed

The following application and Kubernetes checks were successfully performed:

### Automated tests

```text
Test Suites: 1 passed
Tests:       1 passed
```

### Kubernetes deployment

```text
NAME        READY   UP-TO-DATE   AVAILABLE
8byte-app   2/2     2            2
```

### Kubernetes pods

```text
8byte-app-767b7774c-7ls2r   1/1   Running
8byte-app-767b7774c-qffzp   1/1   Running
```

### Rollout

```text
deployment "8byte-app" successfully rolled out
```

### Application health

```json
{
  "status": "UP"
}
```

These checks confirm that the application was successfully built, tested, deployed to EKS, and made accessible through the AWS LoadBalancer.

---

# 29. Troubleshooting

## Check Pods

```bash
kubectl get pods -o wide
```

## Check Deployment

```bash
kubectl get deployment
```

## Check Service

```bash
kubectl get svc
```

## Check Rollout

```bash
kubectl rollout status deployment/8byte-app
```

## View Application Logs

```bash
kubectl logs deployment/8byte-app
```

## Describe a Pod

```bash
kubectl describe pod <POD_NAME>
```

## Test Application

```bash
curl http://<LOAD_BALANCER_HOSTNAME>/health
```

---

# 30. Known Limitations and Future Improvements

The following improvements would be appropriate for a production-grade implementation.

### SonarQube

Connect the code-analysis stage to a real SonarQube or SonarCloud server instead of using a placeholder analysis command.

### Notifications

Add Jenkins notifications using Slack or email so that developers are notified when a pipeline succeeds or fails.

### Pull Request Validation

Configure Jenkins Multibranch Pipeline and GitHub webhooks so that pull requests automatically trigger validation builds.

Recommended flow:

```text
Pull Request
     ↓
GitHub Webhook
     ↓
Jenkins
     ↓
npm audit
     ↓
npm test
     ↓
Security checks
     ↓
PR Status
```

### Kubernetes Health Probes

Add:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080

readinessProbe:
  httpGet:
    path: /health
    port: 8080
```

This allows Kubernetes to automatically determine whether the application is healthy and ready to receive traffic.

### Resource Management

Add CPU and memory requests/limits to prevent one application from consuming excessive node resources.

### Autoscaling

Implement Kubernetes Horizontal Pod Autoscaler for workloads with variable traffic.

### Ingress

For a more production-oriented architecture, replace the basic `LoadBalancer` Service with the AWS Load Balancer Controller and Kubernetes Ingress.

### Secrets

Avoid hardcoded database passwords in Terraform variables or source code.

Use generated secrets or CI/CD secret stores wherever possible.

---

# 31. Production Improvements

A production deployment could further include:

```text
GitHub
   │
   ▼
Jenkins
   │
   ├── Unit Tests
   ├── Dependency Scan
   ├── SonarQube
   ├── Docker Build
   ├── Trivy
   │
   ▼
Amazon ECR
   │
   ▼
EKS Staging
   │
   ├── Smoke Tests
   ├── Health Checks
   │
   ▼
Manual Approval
   │
   ▼
EKS Production
   │
   ├── Monitoring
   ├── Logging
   ├── Alerting
   └── Autoscaling
```

---

# 32. Final Result

The completed project demonstrates an end-to-end DevOps workflow using AWS, Terraform, Docker, Jenkins, Kubernetes, EKS, ECR, npm audit, and Trivy.

The application was successfully:

```text
✓ Built
✓ Unit/Integration Tested
✓ Dependency Scanned
✓ Containerized
✓ Container Security Scanned
✓ Published to Amazon ECR
✓ Deployed to Amazon EKS
✓ Exposed through AWS LoadBalancer
✓ Verified using Kubernetes rollout
✓ Verified using /health endpoint
✓ Integrated with Jenkins CI/CD
✓ Protected by a manual production approval stage
```

The successful deployment was verified using:

```bash
kubectl rollout status deployment/8byte-app
```

Result:

```text
deployment "8byte-app" successfully rolled out
```

The application was also verified externally:

```bash
curl http://<LOAD_BALANCER_HOSTNAME>/health
```

Response:

```json
{
  "status": "UP"
}
```

This demonstrates a complete CI/CD workflow from source code through automated testing and security validation to container deployment on Amazon EKS.
