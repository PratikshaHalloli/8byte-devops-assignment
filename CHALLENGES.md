Challenges Faced and Resolutions

## 8Byte DevOps Assignment

This document describes the key technical challenges encountered during the implementation of the 8Byte DevOps assignment and the steps taken to troubleshoot and resolve them.

The main challenges involved application testing, dependency security scanning, Jenkins CI/CD execution, Docker and container security, Kubernetes deployment, AWS EKS connectivity, and deployment validation.

---

1. Application Test Setup and Validation

### Challenge

The application included a dedicated `test/` directory, but it was necessary to verify that the existing tests were correctly configured and could be executed through the Node.js project.

The test file was located at:

```text
app/test/app.test.js
```

### Investigation

The test directory and files were inspected using:

```bash
ls -la test
find test -type f -maxdepth 2 -print
```

The application test suite was then executed using:

```bash
npm test
```

### Resolution

The existing Jest/Supertest test was successfully executed.

Final result:

```text
PASS  test/app.test.js

Test Suites: 1 passed, 1 total
Tests:       1 passed, 1 total
```

The test validates the application's `/health` endpoint and confirms that the application returns HTTP 200 with an `UP` status.

### Result

The application test stage was confirmed to be working and was integrated into the Jenkins pipeline.

---

 2. Dependency Vulnerability Scan Initially Failed the Pipeline

### Challenge

The Jenkins pipeline included an npm dependency security scan.

The initial implementation used:

```bash
npm audit --audit-level=high || true
```

Although this allowed the pipeline to continue, it also meant that the security scan could not act as a proper quality gate because the pipeline ignored the command's exit status.

### Investigation

The dependency tree was tested locally using:

```bash
npm install
npm audit --audit-level=high
```

The local application initially reported:

```text
found 0 vulnerabilities
```

However, the container security scan later identified vulnerabilities in packages contained within the application dependency tree.

### Resolution

The Jenkins dependency security stage was changed so that security findings can fail the pipeline instead of being silently ignored.

This provides a proper CI/CD security gate.

### Result

The pipeline can now stop before the Docker image is published if dependency vulnerabilities meeting the configured severity threshold are detected.

---

 3. Trivy Was Not Initially Available on the Jenkins Machine

### Challenge

The assignment required container image vulnerability scanning.

Trivy was initially not installed on the Jenkins execution environment.

The following command returned:

```text
trivy: command not found
```

### Investigation

The Jenkins EC2 instance was checked to determine whether the required DevOps tools were available.

The following commands were used:

```bash
trivy --version
docker --version
aws --version
kubectl version --client
```

## Resolution

Trivy was installed on the Jenkins EC2 instance and verified successfully.

The final environment reported:

```text
Trivy Version: 0.74.0
Docker Version: 29.1.3
AWS CLI: 2.36.34
kubectl Client: v1.37.0
```

## Result

The Jenkins machine was capable of performing:

```text
Docker Build
     ↓
Trivy Image Scan
     ↓
AWS ECR Authentication
     ↓
ECR Push
     ↓
Kubernetes Deployment
```

---

# 4. Trivy Identified Vulnerabilities in the Container

### Challenge

After Trivy was configured, the container/dependency scan identified multiple vulnerabilities.

Examples included vulnerabilities in:

* `brace-expansion`
* `cross-spawn`
* `glob`
* `ip-address`
* `minimatch`
* `pacote`
* `sigstore`
* `tar`

The scan included both HIGH and CRITICAL severity findings.

For example:

```text
tar
Severity: CRITICAL
Installed Version: 6.2.1
```

### Investigation

The vulnerability report was reviewed to determine whether the findings were caused by direct application dependencies or transitive dependencies.

The fixed versions reported by the scanner were used as guidance for dependency updates.

### Resolution

The npm dependency tree was updated and reinstalled where compatible.

The application was then re-tested and the dependency audit was executed again.

### Result

The local npm audit ultimately returned:

```text
found 0 vulnerabilities
```

This allowed the CI/CD security gate to proceed successfully.

---

# 5. Jenkins Pipeline Stopped Before Deployment

### Challenge

At one point, the Jenkins pipeline failed during the security scanning stage.

Because the pipeline follows sequential execution, all subsequent stages were automatically skipped.

The Jenkins console showed messages similar to:

```text
Stage "Login to Amazon ECR" skipped due to earlier failure(s)

Stage "Push Docker Image to ECR" skipped due to earlier failure(s)

Stage "Deploy to Staging" skipped due to earlier failure(s)

Stage "Production Approval" skipped due to earlier failure(s)
```

### Investigation

The Jenkins console output was examined from the first failing stage rather than troubleshooting the later skipped stages.

This established that the later stages were not independently broken; they were skipped because an earlier stage had failed.

### Resolution

The dependency/security scan issue was corrected first.

The pipeline was then executed again from the beginning.

### Result

After correcting the security-stage issue, the complete Jenkins pipeline was able to progress through the later build, image, deployment, and validation stages.

---

# 6. Kubernetes Rollout Verification Command Error

### Challenge

After deploying the application to EKS, rollout status needed to be verified.

An incorrect command was initially attempted:

```bash
kubectl rollout status...
```

Kubernetes returned:

```text
error: unknown command "status..."
```

A second attempt without specifying a resource also failed:

```text
error: required resource not specified
```

### Resolution

The correct resource-specific command was used:

```bash
kubectl rollout status deployment/8byte-app
```

### Result

Kubernetes confirmed:

```text
deployment "8byte-app" successfully rolled out
```

This verified that the Deployment had successfully completed its rollout.

---

# 7. Verifying Kubernetes Pod Health

### Challenge

A successful `kubectl apply` does not by itself guarantee that the application is healthy.

The application pods needed to be checked after deployment.

### Investigation

The following command was used:

```bash
kubectl get pods -o wide
```

The result showed two application replicas:

```text
8byte-app-767b7774c-7ls2r   1/1   Running
8byte-app-767b7774c-qffzp   1/1   Running
```

Both pods had:

```text
READY: 1/1
STATUS: Running
RESTARTS: 0
```

### Resolution

The Deployment was also checked:

```bash
kubectl get deployment
```

Result:

```text
8byte-app   2/2   2   2
```

### Result

The Kubernetes application was confirmed to have two healthy running replicas.

---

# 8. Exposing the Application Outside the EKS Cluster

### Challenge

The application was running successfully inside Kubernetes, but external accessibility also needed to be verified.

### Investigation

The Kubernetes services were inspected using:

```bash
kubectl get svc
```

The application service was configured as a `LoadBalancer` and received an AWS Elastic Load Balancer hostname.

Example:

```text
app-8byte-service
TYPE: LoadBalancer
PORT: 80
```

### Resolution

The AWS LoadBalancer endpoint was used to access the application externally.

The health endpoint was tested using:

```bash
curl http://<LOAD_BALANCER_HOSTNAME>/health
```

### Result

The endpoint returned:

```json
{
  "status": "UP"
}
```

This confirmed the complete application path:

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
```

---

# 9. Ensuring CI/CD Deployment Order

### Challenge

The assignment required a controlled CI/CD process where code quality and security checks occur before deployment.

A simple build-and-deploy pipeline would not provide sufficient protection against deploying an untested or vulnerable image.

### Resolution

The Jenkins pipeline was structured into sequential stages:

```text
Dependency Security Scan
        ↓
Install Dependencies
        ↓
Unit/Integration Tests
        ↓
Code Analysis
        ↓
Docker Build
        ↓
Trivy Container Scan
        ↓
ECR Login
        ↓
Push Image to ECR
        ↓
Deploy to Staging
        ↓
Smoke Test
        ↓
Manual Approval
        ↓
Production Deployment
```

### Result

The pipeline provides multiple quality gates before production deployment.

---

# 10. Manual Production Approval

### Challenge

Production deployment should not happen automatically immediately after a staging deployment.

The assignment required a manual approval step.

### Resolution

A Jenkins input/approval stage was included between staging and production:

```text
Deploy to Staging
       ↓
Smoke Test
       ↓
Manual Approval
       ↓
Deploy to Production
```

The Jenkins pipeline waits for an authorized user to approve the production deployment.

### Result

Production deployment is controlled and cannot proceed automatically without approval.

---

# 11. Jenkins Execution Environment

### Challenge

The Jenkins pipeline required several tools to be available on the machine executing the pipeline.

Missing tools could cause failures even when the application code itself was correct.

### Resolution

The Jenkins EC2 instance was prepared and validated with:

```bash
docker --version
aws --version
kubectl version --client
trivy --version
```

The environment was confirmed to support:

* Node.js/npm application builds
* Jest tests
* Docker image builds
* Trivy security scans
* AWS ECR authentication
* Docker image pushes
* Kubernetes deployments

### Result

The Jenkins agent was capable of executing the complete CI/CD workflow.

---

# 12. Kubernetes Deployment Validation

### Challenge

It was important to verify not only that the deployment command completed, but that the application was actually functioning after deployment.

### Resolution

Multiple levels of validation were performed:

### Deployment status

```bash
kubectl get deployment
```

### Pod status

```bash
kubectl get pods -o wide
```

### Rollout status

```bash
kubectl rollout status deployment/8byte-app
```

### Service status

```bash
kubectl get svc
```

### Application health

```bash
curl http://<LOAD_BALANCER_HOSTNAME>/health
```

### Result

The final validation confirmed:

```text
Deployment: 2/2 available
Pods:       2/2 Running
Rollout:    Successfully rolled out
Health:     status = UP
```

---

# 13. Overall Troubleshooting Approach

The troubleshooting process followed a structured approach instead of bypassing failures.

```text
                Failure
                   │
                   ↓
          Check Console Output
                   │
                   ↓
            Identify Stage
                   │
                   ↓
           Find Root Cause
                   │
                   ↓
             Apply Fix
                   │
                   ↓
             Re-run Stage
                   │
                   ↓
              Validate
                   │
                   ↓
          Continue Pipeline
```

This approach was particularly useful for Jenkins because later stages can be skipped when an earlier stage fails.

---

# Final Outcome

The assignment was successfully implemented and validated across the major DevOps components.

### Application

* Node.js/Express application
* `/health` endpoint
* Jest + Supertest test
* Successful test execution

### Containerization

* Dockerized application
* Multi-stage Docker build
* Non-root container execution
* Trivy vulnerability scanning

### AWS

* Amazon ECR
* Amazon EKS
* AWS LoadBalancer
* AWS IAM/IRSA
* AWS Secrets Manager
* Terraform-managed infrastructure

### Kubernetes

* Kubernetes Deployment
* Two application replicas
* Kubernetes Service
* Successful rollout
* External application access

### CI/CD

* Jenkins pipeline
* Dependency security scanning
* Automated testing
* Container vulnerability scanning
* Docker image build
* ECR push
* Staging deployment
* Smoke testing
* Manual production approval
* Production deployment

### Final Application Validation

The deployed application was successfully accessed through the AWS LoadBalancer and returned:

```json
{
  "status": "UP"
}
```

This confirmed that the application was not only built and deployed successfully, but also operational and reachable through the Kubernetes service.
