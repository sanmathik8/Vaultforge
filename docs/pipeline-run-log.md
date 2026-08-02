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

## Phase 3 — Infrastructure as Code & Cloud Platform Audit
- **Completed Components Identified**:
  - Modular Terraform HCL structure (`terraform/bootstrap/` and `terraform/modules/` for `ecr`, `eks`, `oidc`).
  - Amazon ECR Repository (`vault-forge-app`) with tag immutability, automated scan on push, and 7-day untagged lifecycle policy.
  - Amazon EKS Cluster module with cost-conscious `t3.medium` managed node group and `AmazonEKSEditPolicy` IAM access entry scoped to `vault-forge` namespace.
  - Keyless GitHub OIDC Provider (`token.actions.githubusercontent.com`) and least-privilege IAM Roles (`vault-forge-ci-ecr-push` and `vault-forge-cd-eks-deploy`).
- **Missing / Partially Implemented Component Enhancements**:
  - Aligned repository name casing in `terraform/bootstrap/variables.tf` (`sanmathik8/Vaultforge`).
  - Added dedicated `vault-forge-terraform-bootstrap` IAM Role and output (`terraform_role_arn`) in `terraform/modules/oidc/main.tf` for IaC workflow execution.
  - Expanded OIDC subject claim matching (`repo:sanmathik8/Vaultforge:*`) in `terraform/modules/oidc/main.tf` so both branch and environment triggers can authenticate via OIDC.

## Modular Enterprise Pipeline Refactoring

Refactored the GitHub Actions workflow architecture from monolithic/duplicated files into an enterprise-grade, modular pipeline:

```text
.github/workflows/
├── pipeline.yml          ← Main Orchestrator (on: push, pull_request, workflow_dispatch)
├── security.yml          ← Reusable Security Scanning (Gitleaks, Hadolint, Semgrep, OSV, kube-score)
├── build.yml             ← Reusable Build & Container Security (Buildx, Syft SBOM, Trivy, Cosign Sign/Push)
├── deploy.yml            ← Reusable IaC & Kubernetes Deployment (Checkov, Kustomize, Kyverno, Rollout/Undo)
└── validate.yml          ← Reusable Post-Deploy Validation (Smoke tests, OWASP ZAP DAST, SARIF, Summary)
```

### Refactoring Details
1. **`pipeline.yml` (Main Orchestrator)**: Single primary entry point triggered by `push`, `pull_request`, and `workflow_dispatch`. Orchestrates `security.yml`, `build.yml`, `deploy.yml`, and `validate.yml` via `workflow_call`.
2. **`security.yml` (Pre-Build Security)**: Reusable workflow containing Dockerfile validation, Hadolint Docker linting, Gitleaks secret scanning, OSV-Scanner dependency SCA, Semgrep SAST, and `kube-score` manifest validation.
3. **`build.yml` (Build, SBOM, Scan & Sign)**: Reusable workflow containing Docker Buildx, Syft CycloneDX SBOM generation, Trivy container vulnerability scan, and Sigstore Cosign keyless signing & ECR push.
4. **`deploy.yml` (IaC & Kubernetes CD)**: Reusable workflow containing Checkov IaC scan, Terraform validation, Kustomize deployment, Kyverno admission violation check, rollout monitoring, automated rollback (`kubectl rollout undo`), and `/health` probe validation.
5. **`validate.yml` (Post-Deploy Validation & DAST)**: Reusable workflow containing smoke testing, OWASP ZAP baseline DAST scanning, SARIF uploading, automated GitHub Issue creation on findings, and consolidated Step Summary generation.

### Verification Status
- **Pipeline Architecture**: All workflow files validated and syntactically clean.
- **Security Policy Alignment**: All security gates, scanners, flags, and policy checks preserved 100% without weakening.
- **AWS & Infrastructure**: No `terraform apply` or live AWS execution performed (guarded by secret presence and plan-only policies).
