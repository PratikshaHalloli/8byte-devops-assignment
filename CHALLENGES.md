 Challenges Faced and Resolutions

During the implementation of the assignment, several challenges were encountered across the application, CI/CD pipeline, container security, and Kubernetes deployment.

## 1. Dependency Vulnerabilities

### Challenge

The initial dependency security scan identified several HIGH and CRITICAL vulnerabilities in transitive npm dependencies, including packages such as `tar`, `brace-expansion`, `minimatch`, and `glob`.

### Resolution

The dependency tree was reviewed and updated using npm package management commands. The dependencies were reinstalled and the application was re-scanned.

The final local dependency audit returned:

```text
found 0 vulnerabilities
```

The Jenkins pipeline was also configured to perform the dependency security check before continuing with the build.

---

## 2. Pipeline Failure Due to Security Scan

### Challenge

The initial Jenkins pipeline used:

```bash
npm audit --audit-level=high || true
```

This caused the pipeline to ignore security scan failures.

### Resolution

The dependency scan was changed so that a high-severity vulnerability can cause the pipeline to fail.

This makes the security stage a quality gate rather than simply displaying scan results.

---

## 3. Docker Image Security Scanning

### Challenge

The assignment required container security scanning, but Trivy was initially not installed on the Jenkins execution environment.

### Resolution

Trivy was installed on the Jenkins EC2 instance and verified successfully.

The Jenkins environment was validated with:

```bash
trivy --version
docker --version
aws --version
kubectl version --client
```

The environment was confirmed to have the required tools available for the CI/CD pipeline.

---

## 4. Kubernetes Deployment Verification

### Challenge

After deployment, it was necessary to verify that the application had actually become available rather than only confirming that the Kubernetes command completed successfully.

### Resolution

The deployment was verified using:

```bash
kubectl get pods -o wide
kubectl get deployment
kubectl rollout status deployment/8byte-app
```

The deployment successfully reported:

```text
deployment "8byte-app" successfully rolled out
```

Two application replicas were running:

```text
8byte-app-767b7774c-7ls2r   1/1   Running
8byte-app-767b7774c-qffzp   1/1   Running
```

---

## 5. External Application Access

### Challenge

A Kubernetes deployment being in `Running` state does not necessarily confirm that users can access the application externally.

### Resolution

The Kubernetes Service was configured as a `LoadBalancer`.

The service was verified using:

```bash
kubectl get svc
```

The AWS LoadBalancer hostname was then used to test the application:

```bash
curl http://<LOAD_BALANCER_HOSTNAME>/health
```

The application successfully returned:

```json
{
  "status": "UP"
}
```

This confirmed the complete traffic path from the external load balancer to the Kubernetes application pod.

---

## 6. Kubernetes Rollout Command

### Challenge

During deployment verification, an incorrect command was initially attempted:

```bash
kubectl rollout status...
```

and Kubernetes returned an unknown-command error.

### Resolution

The correct resource-specific rollout command was used:

```bash
kubectl rollout status deployment/8byte-app
```

The deployment then successfully reported that the rollout was complete.

---

## 7. CI/CD Stage Ordering

### Challenge

The pipeline needed to ensure that security and testing were completed before an image could be published or deployed.

### Resolution

The Jenkins pipeline was structured so that application quality gates occur before deployment:

```text
Dependency Scan
       ↓
Tests
       ↓
Code Analysis
       ↓
Docker Build
       ↓
Trivy Scan
       ↓
ECR Push
       ↓
Staging Deployment
       ↓
Smoke Test
       ↓
Manual Approval
       ↓
Production
```

This prevents failed tests or security checks from automatically progressing to later deployment stages.

---

## 8. Production Deployment Safety

### Challenge

Automatically deploying every successful build directly to production can introduce unnecessary risk.

### Resolution

A manual approval gate was added between staging and production.

The pipeline therefore follows:

```text
Staging
   ↓
Smoke Test
   ↓
Manual Approval
   ↓
Production
```

Production deployment only proceeds after an authorized user approves the Jenkins deployment.

---

## 9. Tooling and Environment Setup

### Challenge

The Jenkins execution environment required multiple DevOps tools to build, scan, publish, and deploy the application.

### Resolution

The Jenkins EC2 environment was prepared with:

* Docker
* AWS CLI
* kubectl
* Trivy
* Node.js/npm

The installed versions were verified before running the pipeline.

This ensured that Jenkins could perform Docker builds, security scanning, ECR authentication, and Kubernetes deployment from the same execution environment.

---

## Overall Resolution Approach

The general troubleshooting approach used throughout the assignment was:

```text
Identify Failure
      ↓
Check Logs / Command Output
      ↓
Identify Root Cause
      ↓
Apply Minimal Fix
      ↓
Re-run Failed Stage
      ↓
Validate Result
      ↓
Continue Pipeline
```

This approach helped ensure that fixes were validated rather than simply bypassing errors.

The final application was successfully deployed to Amazon EKS, with two running replicas, a successful Kubernetes rollout, and a working `/health` endpoint exposed through the AWS LoadBalancer.
