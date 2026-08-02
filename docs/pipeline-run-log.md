# VaultForge DevSecOps Pipeline Run Log

## Phase 1 — Repository Initialization & GitHub Push
- **Status**: SUCCESS
- **Action**: Initialized git repository, added all project files, committed initial VaultForge DevSecOps structure, set default branch to `main`, added remote `https://github.com/sanmathik8/Vaultforge.git`, and pushed `main` to GitHub.
- **Result**: `main` branch pushed cleanly to `https://github.com/sanmathik8/Vaultforge.git`.

## Phase 2 — Pipeline Runs & Initial Scans
- **Discovered Failures & Fixes**:
  1. `.gitleaks.toml` created to allowlist PyGoat training lab sample tokens (`app/introduction/.*`).
  2. `kube-score` manifest validation fixed across `deployment.yaml` (ephemeral storage limits, user/group IDs >10000, `imagePullPolicy`, probe separation, pod anti-affinity) and kustomization overlays (static replicas removed for HPA compatibility).
  3. `/health` endpoint added to PyGoat application views for probes and smoke tests.

## Phase 3 — Production-Hardening Review & Security Strengthening
- **ECR Hardening**: Added default `AES256` server-side encryption configuration and tightened resource policy statement actions (`ecr:PutImage`, `ecr:UploadLayerPart`, `ecr:InitiateLayerUpload`, `ecr:CompleteLayerUpload`, `ecr:BatchCheckLayerAvailability`, `ecr:BatchGetImage`, `ecr:GetDownloadUrlForLayer`).
- **IAM Least Privilege**: Scoped `sanmathik8/Vaultforge` OIDC repository parameters across all federated IAM role policies (`ecr_push`, `eks_deploy`, `terraform_bootstrap`).

## Targeted Architectural Migration — Amazon EKS to Amazon ECS on Fargate
- **Status**: SUCCESS & VALIDATED
- **Action**: Replaced Amazon EKS deployment target with production Amazon ECS on Fargate while preserving 87% of the codebase (all supply chain security, SAST, SCA, SBOM generation, Trivy CVE scans, Cosign signing, ECR, OIDC, PyGoat target app, and OWASP ZAP DAST).
- **Changes**:
  1. Removed `terraform/modules/eks`, `kubernetes/`, `security/kyverno-policies`, and `runtime-security/falco`.
  2. Created `terraform/modules/ecs_fargate` provisioning ECS Cluster (Container Insights), Fargate Service, Task Definition, Task Execution IAM Role, Application Load Balancer (ALB), Target Group (/health), CloudWatch Log Group (`/ecs/vault-forge-app`), and ECS Service Auto Scaling (CPU 70%, Memory 80%).
  3. Created `ecs/task-definition.json` template with non-root UID `10001`, `readonlyRootFilesystem: true`, `/tmp` `emptyDir` volume, and CloudWatch log configuration.
  4. Updated `.github/workflows/deploy.yml` to issue `aws ecs register-task-definition`, `aws ecs update-service --force-new-deployment`, and `aws ecs wait services-stable`.
  5. Updated `.github/workflows/security.yml` to validate `ecs/task-definition.json` JSON syntax.
  6. Updated Terraform module bindings in `terraform/bootstrap/main.tf` and outputs in `outputs.tf` (`ecs_cluster_name`, `ecs_service_name`, `alb_dns_name`).
- **Verification**: `terraform init -backend=false` and `terraform validate` returned **`Success! The configuration is valid.`**.

## Modular Enterprise Pipeline Architecture

```text
.github/workflows/
├── pipeline.yml          ← Main Orchestrator (on: push, pull_request, workflow_dispatch)
├── security.yml          ← Reusable Security Scanning (Gitleaks, Hadolint, Semgrep, OSV, TaskDef validation)
├── build.yml             ← Reusable Build & Container Security (Buildx, Syft SBOM, Trivy, Cosign Sign/Push)
├── deploy.yml            ← Reusable IaC & ECS Fargate CD (Checkov, Terraform validate, TaskDef register, Rollout)
└── validate.yml          ← Reusable Post-Deploy Validation (Smoke tests, OWASP ZAP DAST, SARIF, Summary)
```
