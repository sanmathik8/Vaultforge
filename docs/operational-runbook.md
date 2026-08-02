# VaultForge — Production Deployment Operational Runbook

## 1. Overview
This operational runbook provides the step-by-step procedure for provisioning AWS infrastructure, setting up GitHub OIDC authentication, running Terraform, deploying Kubernetes platform services, and validating the live VaultForge DevSecOps platform.

---

## 2. Step 1: GitHub Repository Secrets & Variables Setup

In your GitHub repository settings (`Settings > Secrets and variables > Actions`):

### Repository Variables (`Variables`)
- `ALLOW_CRITICAL_CVES`: Set to `true` (required for OWASP PyGoat demo target vulnerability gates).

### Repository Secrets (`Secrets`)
- `AWS_ROLE_TO_ASSUME`: IAM Role ARN for ECR push & OIDC authentication (`arn:aws:iam::<ACCOUNT_ID>:role/vaultforge-ecr-push-role`).
- `ECR_REPOSITORY_URL`: Amazon ECR repository URI (`<ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/vault-forge-app`).
- `AWS_EKS_DEPLOY_ROLE_ARN`: IAM Role ARN for EKS deployment (`arn:aws:iam::<ACCOUNT_ID>:role/vaultforge-eks-deploy-role`).
- `EKS_CLUSTER_NAME`: Name of the Amazon EKS cluster (`vaultforge-eks-cluster`).
- `AWS_TERRAFORM_ROLE_ARN`: IAM Role ARN for Terraform IaC workflow (`arn:aws:iam::<ACCOUNT_ID>:role/vaultforge-terraform-role`).

---

## 3. Step 2: Infrastructure Bootstrap (Terraform)

### Option A: Manual Trigger via GitHub Actions
1. Navigate to `Actions > VaultForge Infra - Terraform Bootstrap`.
2. Click `Run workflow`.
3. Select `plan` to review proposed infrastructure changes.
4. Review the generated Terraform plan output.
5. Trigger workflow with input `apply` (requires approval on `production` environment).

### Option B: Local Execution (AWS Credentials Configured)
```bash
cd terraform/bootstrap

# 1. Initialize Terraform plugins and modules
terraform init

# 2. Generate and inspect infrastructure execution plan
terraform plan -out=tfplan

# 3. Apply infrastructure plan (Creates ECR, EKS cluster, KMS, OIDC roles)
terraform apply tfplan
```

---

## 4. Step 3: Platform Services Deployment (Kubernetes)

Once EKS cluster is active and `kubectl` context is configured (`aws eks update-kubeconfig --name vaultforge-eks-cluster`):

```bash
# 1. Install Metrics Server
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm upgrade --install metrics-server metrics-server/metrics-server -f monitoring/metrics-server/values.yaml -n kube-system

# 2. Install Kyverno Admission Controller
helm repo add kyverno https://kyverno.github.io/kyverno/
helm upgrade --install kyverno kyverno/kyverno -n kyverno --create-namespace
kubectl apply -f security/kyverno-policies/

# 3. Install kube-prometheus-stack (Prometheus, Grafana, Alertmanager)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack -f monitoring/kube-prometheus-stack/values.yaml -n monitoring --create-namespace
kubectl apply -f monitoring/prometheus-rules.yaml

# 4. Install Falco eBPF Runtime Security
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm upgrade --install falco falcosecurity/falco -f runtime-security/falco/values.yaml -n falco --create-namespace
```

---

## 5. Step 4: Application Deployment & Verification

1. Trigger `VaultForge Pipeline` (`pipeline.yml`) on `main` push or manual dispatch.
2. Verify CI stages pass (Gitleaks, Hadolint, Semgrep, OSV, kube-score, Docker Build, Syft SBOM, Trivy, Cosign Sign & Push).
3. Verify CD deployment to `vault-forge` namespace.
4. Confirm application readiness and run smoke tests:
   `./scripts/smoke-test.sh dev`
