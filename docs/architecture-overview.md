# VaultForge — System Architecture & Platform Overview

## 1. Executive Summary
VaultForge is a enterprise-grade DevSecOps platform demonstrating end-to-end security automation, continuous integration, immutable deployment, runtime threat detection, and continuous observability for containerized workloads.

---

## 2. Enterprise Modular Workflow Architecture

The GitHub Actions pipeline is structured into a production-grade, modular architecture:

```text
.github/workflows/
├── pipeline.yml          ← Main Orchestrator (on: push, pull_request, workflow_dispatch)
├── security.yml          ← Reusable Security Scanning (Gitleaks, Hadolint, Semgrep, OSV, kube-score)
├── build.yml             ← Reusable Build & Container Security (Buildx, Syft SBOM, Trivy, Cosign Sign/Push)
├── deploy.yml            ← Reusable IaC & Kubernetes Deployment (Checkov, Kustomize, Kyverno, Rollout/Undo)
└── validate.yml          ← Reusable Post-Deploy Validation (Smoke tests, OWASP ZAP DAST, SARIF, Summary)
```

```
[ Developer Trigger ] (push / pull_request / workflow_dispatch)
         │
         ▼
 ┌───────────────┐
 │ pipeline.yml  │ ──(1. workflow_call)──► ┌───────────────┐
 │ (Orchestrator)│                         │ security.yml  │ (SAST, SCA, Linters, kube-score)
 └───────┬───────┘                         └───────────────┘
         │
         ├──(2. workflow_call)───────────► ┌───────────────┐
         │                                 │   build.yml   │ (Docker Buildx, SBOM, Trivy, Cosign)
         │                                 └───────────────┘
         │
         ├──(3. workflow_call)───────────► ┌───────────────┐
         │                                 │  deploy.yml   │ (Checkov, Kustomize, Kyverno, Rollback)
         │                                 └───────────────┘
         │
         └──(4. workflow_call)───────────► ┌───────────────┐
                                           │ validate.yml  │ (Smoke test, OWASP ZAP DAST, Summary)
                                           └───────────────┘
```

---

## 3. Component Responsibilities

| Layer | Technology | Primary Function |
|---|---|---|
| **IaC** | Terraform 1.14+ | Provisions AWS EKS, ECR (immutable tags), KMS encryption, OIDC IAM roles. |
| **Main Orchestrator** | `pipeline.yml` | Single entry point orchestrating modular reusable workflows via `workflow_call`. |
| **Security Module** | `security.yml` | Gitleaks, Hadolint, Semgrep SAST, OSV-Scanner, kube-score manifest validation. |
| **Build Module** | `build.yml` | Docker Buildx, Syft SBOM, Trivy image scan, keyless Cosign signing, ECR push. |
| **Deploy Module** | `deploy.yml` | Checkov IaC scan, Terraform validation, Kustomize apply, Kyverno admission, auto-rollback. |
| **Validation Module**| `validate.yml` | Smoke tests, OWASP ZAP DAST scan, SARIF uploads, GitHub issue creation, step summary. |
| **Secrets Scanning** | Gitleaks v8 | Scans Git commits and tree for exposed credentials and tokens. |
| **Linting** | Hadolint v3 | Enforces Dockerfile security best practices. |
| **SAST** | Semgrep | Code vulnerability scanning (OWASP Top 10, Django, Python). |
| **SCA** | OSV-Scanner | Open-source dependency vulnerability discovery. |
| **IaC Security** | Checkov | Terraform template security & compliance scanning. |
| **Manifest Security** | kube-score | Static analysis of rendered Kubernetes manifests. |
| **SBOM & Supply Chain** | Syft & Cosign | Generates CycloneDX SBOMs and keyless OIDC container signatures via Sigstore. |
| **Container Scanner** | Trivy | Image vulnerability scanner for OS packages & dependencies. |
| **Admission Control** | Kyverno | Enforces cluster policies (non-root, privileged block, limits, signature check). |
| **Target Workload** | OWASP PyGoat | Intentionally vulnerable Python/Django application target. |
| **Deployment Engine** | Kustomize & kubectl | Manages environment overlays (`dev` and `prod`) with zero-downtime rollouts. |
| **Observability** | kube-prometheus-stack | Auto-discovers scrape targets, routes alert notifications, provisions Grafana dashboards. |
| **Runtime Security** | Falco eBPF | Kernel-level eBPF intrusion detection DaemonSet. |

---

## 4. Environment Overlay Strategy

- **`kubernetes/base/`**: Core workload manifests (`Deployment`, `Service`, `NetworkPolicy`, `HPA`, `PodDisruptionBudget`, `ServiceAccount`, `RBAC`, `ServiceMonitor`).
- **`kubernetes/overlays/dev/`**: Development environment configuration (2 replicas min, dev annotations).
- **`kubernetes/overlays/prod/`**: Production environment configuration (3-10 replicas HPA, production environment).

---

## 5. Architectural Agility & Targeted Migration Blueprint

VaultForge's modular architecture cleanly separates **Supply Chain Security & Build** from **Container Runtime Deployment**. Should future business requirements or career preferences warrant migrating the container execution layer from Amazon EKS to **Amazon ECS (Fargate)**, the platform requires **zero pipeline redesign**:

```
                  ┌─────────────────────────────────────────────────────────┐
                  │                 VaultForge Security & CI                │
                  │   Gitleaks ──► Hadolint ──► Semgrep ──► OSV ──► Syft     │
                  │          Buildx ──► Trivy ──► Cosign ──► ECR            │
                  └────────────────────────────┬────────────────────────────┘
                                               │ (Signed ECR Image Digest)
                                               │
                       ┌───────────────────────┴───────────────────────┐
                       ▼                                               ▼
         ┌───────────────────────────┐                   ┌───────────────────────────┐
         │   Target Runtime A (EKS)  │                   │Target Runtime B (ECS/Fargate)│
         │  Kustomize / kubectl      │                   │  TaskDef / ALB / ecs-deploy│
         │  Kyverno / Falco / Prom   │                   │  AWS App Mesh / CloudWatch│
         └───────────────────────────┘                   └───────────────────────────┘
```

### Components Preserved 100% During Migration
- **CI & Security Pipeline**: `security.yml`, `build.yml`, Gitleaks, Hadolint, Semgrep, OSV-Scanner, Syft SBOM, Trivy, Cosign, SARIF uploads.
- **Identity & Authentication**: GitHub OIDC federation and IAM role structure.
- **Registry Platform**: Amazon ECR (Immutable tags, scan on push, lifecycle rules).
- **Orchestration Engine**: `pipeline.yml` interface and `validate.yml` DAST/smoke testing.

### Components Swapped at Deployment Layer
- **Terraform Module**: Swap `modules/eks` with `modules/ecs_fargate` (Cluster, TaskDefinition, ALB, SecurityGroups).
- **CD Workflow**: Update `deploy.yml` step to issue `aws ecs update-service --force-new-deployment` instead of `kubectl apply -k`.
