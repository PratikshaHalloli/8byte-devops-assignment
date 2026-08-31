Byte DevOps Assignment

A Node.js/Express application deployed to AWS EKS, provisioned entirely with Terraform, with a Jenkins CI/CD pipeline handling build, test, security scanning, and staged (staging → manual approval → production) deployment.

                          ┌─────────────────────────────┐
                          │            VPC               │
                          │  10.0.0.0/16                 │
                          │                               │
   Internet ── ALB SG ──► │  Public Subnets (2 AZs)      │
                          │   └── NAT Gateway            │
                          │                               │
                          │  Private Subnets (2 AZs)     │
                          │   ├── EKS Managed Node Group │
                          │   │    └── 8byte-app pods    │
                          │   └── RDS PostgreSQL          │
                          └─────────────────────────────┘
                                     │
                          ┌──────────┴──────────┐
                          │  ECR (8byte-app)     │
                          │  Secrets Manager     │
                          │  IRSA IAM Role       │
                          └──────────────────────┘

Flow: Jenkins builds the app → pushes image to ECR → deploys manifests to EKS → pods pull DB credentials from a Kubernetes Secret backed by AWS Secrets Manager, over a pod-level IAM role (IRSA)


Repository Structure
.
├── Jenkinsfile              # CI/CD pipeline definition
├── app/                     # Node.js/Express application
│   ├── index.js             # App entrypoint (/health endpoint)
│   ├── Dockerfile           # Multi-stage build, non-root user
│   └── test/                # Jest + Supertest unit tests
├── k8s/
│   ├── deployment.yaml       # App Deployment (2 replicas)
│   └── service.yaml          # LoadBalancer Service
└── terraform/
    ├── backend.tf            # Remote state (S3)
    ├── vpc.tf                # VPC, public/private subnets, NAT gateway
    ├── eks.tf                # EKS cluster + managed node group
    ├── rds.tf                # PostgreSQL RDS (private subnet)
    ├── ecr.tf                # ECR repo with image scanning
    ├── sg.tf                 # ALB / app security groups
    ├── irsa.tf               # OIDC provider + IAM role for pod-level AWS access
    ├── secrets.tf             # AWS Secrets Manager (DB credentials)
    ├── variables.tf
    └── outputs.tf


Prerequisites
AWS account with credentials configured (aws configure)
Terraform >= 1.5.0
kubectl
Docker
An S3 bucket for Terraform remote state (referenced in backend.tf)
A Jenkins instance with Docker, AWS CLI, and kubectl available on the agent


Setup and Run
1. Provision infrastructure
   cd terraform
   terraform init
   terraform plan -var="db_password=<a-strong-password>"
   terraform apply -var="db_password=<a-strong-password>"

This creates the VPC, EKS cluster, RDS instance, ECR repository, security groups, the IRSA IAM role, and the Secrets Manager secret holding the DB credentials. Key values (ECR URL, cluster name, RDS endpoint, IRSA role ARN) are printed as outputs.


2. Point kubectl at the new cluster
  aws eks update-kubeconfig --name $(terraform output -raw eks_cluster_name) --region us-east-1

3. Build and push the application image
   
