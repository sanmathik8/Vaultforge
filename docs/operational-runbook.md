# VaultForge — Production Deployment Operational Runbook

## 1. Overview
This operational runbook provides the step-by-step procedure for provisioning AWS infrastructure via Terraform (ECS Fargate, ALB, ECR, CloudWatch, OIDC), configuring GitHub OIDC authentication, executing zero-downtime rolling container deployments, and validating the live VaultForge platform.

---

## 2. Step 1: GitHub Repository Secrets & Variables Setup

In your GitHub repository settings (`Settings > Secrets and variables > Actions`):

### Repository Variables (`Variables`)
- `ALLOW_CRITICAL_CVES`: Set to `true` (required for OWASP PyGoat demo target vulnerability gates).

### Repository Secrets (`Secrets`)
- `AWS_ROLE_TO_ASSUME`: IAM Role ARN for ECR push & ECS deployment (`arn:aws:iam::<ACCOUNT_ID>:role/vault-forge-cd-ecs-deploy`).
- `ECR_REPOSITORY_URL`: Amazon ECR repository URI (`<ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/vault-forge-app`).
- `ECS_CLUSTER_NAME`: Name of the Amazon ECS cluster (`vault-forge`).
- `AWS_TERRAFORM_ROLE_ARN`: IAM Role ARN for Terraform IaC workflow (`arn:aws:iam::<ACCOUNT_ID>:role/vault-forge-terraform-bootstrap`).

---

## 3. Step 2: Infrastructure Bootstrap (Terraform)

### Option A: Manual Trigger via GitHub Actions
1. Navigate to `Actions > VaultForge Infra - Terraform Bootstrap`.
2. Click `Run workflow`.
3. Select `plan` to review proposed infrastructure changes.
4. Review the generated Terraform plan output.
5. Trigger workflow with input `apply` to create ECS Cluster, Fargate Service, ALB, Target Group, CloudWatch Log Group, and OIDC Roles.

### Option B: Local Execution (AWS Credentials Configured)
```bash
cd terraform/bootstrap

# 1. Initialize Terraform plugins and modules
terraform init -backend=false

# 2. Generate and inspect infrastructure execution plan
terraform plan

# 3. Apply infrastructure plan (Creates ECR, ECS Cluster, ALB, CloudWatch, OIDC roles)
terraform apply
```

---

## 4. Step 3: Application Deployment & Verification

1. Trigger `VaultForge Enterprise DevSecOps Pipeline` (`pipeline.yml`) on `main` push or manual dispatch.
2. Verify CI stages pass (Gitleaks, Hadolint, Semgrep, OSV, TaskDef validation, Docker Buildx, Syft SBOM, Trivy, Cosign Sign & ECR Push).
3. Verify CD deployment to ECS Fargate (`aws ecs register-task-definition`, `aws ecs update-service --force-new-deployment`, `aws ecs wait services-stable`).
4. Confirm application health via Application Load Balancer endpoint:
   `curl -sf http://<ALB_DNS_NAME>/health`
5. Run smoke tests:
   `./scripts/smoke-test.sh dev`
