# 8Byte DevOps Assignment

A Node.js/Express application deployed to AWS EKS, provisioned entirely with Terraform, with a Jenkins CI/CD pipeline handling build, test, security scanning, and staged (staging → manual approval → production) deployment.

## Architecture

```
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
```

**Flow:** Jenkins builds the app → pushes image to ECR → deploys manifests to EKS → pods pull DB credentials from a Kubernetes Secret backed by AWS Secrets Manager, over a pod-level IAM role (IRSA).

## Repository Structure

```
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
```

## Prerequisites

- AWS account with credentials configured (`aws configure`)
- Terraform >= 1.5.0
- `kubectl`
- Docker
- An S3 bucket for Terraform remote state (referenced in `backend.tf`)
- A Jenkins instance with Docker, AWS CLI, and `kubectl` available on the agent

## Setup and Run

### 1. Provision infrastructure

```bash
cd terraform
terraform init
terraform plan -var="db_password=<a-strong-password>"
terraform apply -var="db_password=<a-strong-password>"
```

This creates the VPC, EKS cluster, RDS instance, ECR repository, security groups, the IRSA IAM role, and the Secrets Manager secret holding the DB credentials. Key values (ECR URL, cluster name, RDS endpoint, IRSA role ARN) are printed as outputs.

### 2. Point kubectl at the new cluster

```bash
aws eks update-kubeconfig --name $(terraform output -raw eks_cluster_name) --region us-east-1
```

### 3. Build and push the application image

```bash
cd ../app
docker build -t 8byte-app:latest .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
docker tag 8byte-app:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/8byte-app:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/8byte-app:latest
```

### 4. Deploy to the cluster

```bash
kubectl apply -f ../k8s/
kubectl get svc app-8byte-service   # note the LoadBalancer external IP/hostname
```

### 5. Run it through Jenkins instead

Point a Jenkins pipeline job at this repo. The `Jenkinsfile` runs, in order: dependency/vulnerability scan → install & test → static analysis → build & push to ECR → deploy to staging → **manual approval gate** → deploy to production.

## Architecture Decisions

- **EKS over raw EC2/ECS** — gives declarative, version-controlled deployments (`k8s/`) and room to grow into Helm/GitOps later, at the cost of more moving parts than a single EC2 instance.
- **Private subnets for compute and data, public subnets only for ingress** — EKS worker nodes and RDS have no public IPs; only the load balancer sits in the public subnet.
- **Single NAT Gateway** — one NAT gateway shared across both AZs instead of one per AZ. Cheaper, at the cost of an AZ-level single point of failure for outbound traffic (acceptable for a staging-grade assignment; call out `single_nat_gateway = false` as the production fix).
- **IRSA (IAM Roles for Service Accounts) instead of node-level IAM roles or static AWS keys** — pods assume a scoped IAM role via OIDC federation, so only the specific service account can read the Secrets Manager secret, not every pod on the node.
- **Multi-stage Docker build** — the final image only contains production `node_modules` and app code, not build tooling, which keeps the image small and reduces attack surface.
- **Manual approval before production** — the Jenkins pipeline deploys to staging automatically but gates the production stage on a human approval step, so a bad build can't reach prod unattended.

## Monitoring and Logging

See [`monitoring/README.md`](./monitoring/README.md) for the Prometheus/Grafana/Loki setup, dashboards, and Helm values used.

## Security Considerations

- **Network isolation**: RDS and EKS nodes live in private subnets; RDS's security group only allows inbound Postgres (5432) from the EKS node security group, not from the internet or a CIDR range.
- **No plaintext credentials in manifests**: the app Deployment reads `DB_USER`/`DB_PASSWORD` from a Kubernetes Secret rather than hardcoding them in `deployment.yaml`.
- **Secrets Manager for the source of truth**: DB credentials are generated/stored in AWS Secrets Manager (`secrets.tf`), not committed to the repo.
- **Least-privilege IAM**: the IRSA role (`irsa.tf`) grants only `secretsmanager:GetSecretValue` / `DescribeSecret` on the one secret ARN it needs — not a wildcard.
- **Non-root container**: the Dockerfile runs the app as the built-in `node` user, not root.
- **Image scanning on push**: ECR has `scan_on_push` enabled, and the Jenkins pipeline runs `npm audit` before every build.
- **Known gap to flag honestly**: `variables.tf` currently ships a hardcoded default for `db_password`. That's fine for a quick `terraform apply` in this assignment, but in a real environment it should be generated (e.g. `random_password` resource) or supplied only via a secrets-backed CI variable — never a checked-in default.

## Cost Optimization

- **Single NAT Gateway** instead of one per AZ (~$32/month saved per extra gateway).
- **`c7i-flex.large`** node instance type — the "flex" family is priced for variable, non-peak workloads rather than always paying for a fixed-performance instance.
- **Small, autoscaling node group** (`min=1, max=3, desired=2`) so capacity tracks actual load instead of running fixed oversized nodes.
- **`db.t3.micro`, single-AZ RDS, `gp2` storage, 20 GB with no autoscaling headroom beyond that** — appropriately sized for a staging/demo workload rather than over-provisioned.
- **1-day backup retention** on RDS — enough to demonstrate the capability without paying for long-term snapshot storage (see Backup Strategy below for the production recommendation).

## Secret Management & Backup Strategy

**Secret management (implemented):** DB credentials are provisioned into AWS Secrets Manager via Terraform (`secrets.tf`) and consumed by the pod through a Kubernetes Secret + IRSA-scoped IAM role, rather than being embedded in Terraform state output, manifests, or the image.

**Backup strategy (implemented, minimal):** RDS automated backups are enabled with a 1-day retention window and a defined backup/maintenance window (`rds.tf`). For production this should be increased (e.g. 7–35 days), paired with periodic manual snapshots before risky changes, and ideally cross-region snapshot copy for disaster recovery.

## Notes / Potential Improvements

- Add `random_password` for `db_password` instead of a hardcoded Terraform default.
- Replace the placeholder SonarQube stage in the Jenkinsfile with an actual `sonar-scanner` invocation against a real SonarQube/SonarCloud instance.
- Add pipeline notifications (Slack/email) on failure — not yet wired up.
- Move from a plain `LoadBalancer` Service to an ALB Ingress Controller to reuse the `alb_sg` already defined in Terraform and get path-based routing/TLS termination.
- Add resource requests/limits and a readiness/liveness probe (using the existing `/health` endpoint) to `deployment.yaml`.
