# VaultForge — System Architecture & Platform Overview

## 1. Executive Summary
VaultForge is an enterprise-grade DevSecOps platform demonstrating end-to-end security automation, continuous integration, immutable container deployment, CloudWatch telemetry, and automated vulnerability gating for containerized workloads deployed to Amazon ECS on Fargate.

---

## 2. Enterprise Modular Workflow Architecture

The GitHub Actions pipeline is structured into a production-grade, modular architecture:

```text
.github/workflows/
├── pipeline.yml          ← Main Orchestrator (on: push, pull_request, workflow_dispatch)
├── security.yml          ← Reusable Security Scanning (Gitleaks, Hadolint, Semgrep, OSV, TaskDef validation)
├── build.yml             ← Reusable Build & Container Security (Buildx, Syft SBOM, Trivy, Cosign Sign/Push)
├── deploy.yml            ← Reusable IaC & ECS Fargate CD (Checkov, TaskDef register, Rollout/Stability)
└── validate.yml          ← Reusable Post-Deploy Validation (Smoke tests, OWASP ZAP DAST, SARIF, Summary)
```

```
[ Developer Trigger ] (push / pull_request / workflow_dispatch)
         │
         ▼
 ┌───────────────┐
 │ pipeline.yml  │ ──(1. workflow_call)──► ┌───────────────┐
 │ (Orchestrator)│                         │ security.yml  │ (SAST, SCA, Linters, TaskDef)
 └───────┬───────┘                         └───────────────┘
         │
         ├──(2. workflow_call)───────────► ┌───────────────┐
         │                                 │   build.yml   │ (Docker Buildx, SBOM, Trivy, Cosign)
         │                                 └───────────────┘
         │
         ├──(3. workflow_call)───────────► ┌───────────────┐
         │                                 │  deploy.yml   │ (Checkov, TaskDef, ECS Service Rollout)
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
| **IaC** | Terraform 1.14+ | Provisions AWS ECS Fargate, ECR (immutable tags), ALB, CloudWatch, OIDC IAM roles. |
| **Main Orchestrator** | `pipeline.yml` | Single entry point orchestrating modular reusable workflows via `workflow_call`. |
| **Security Module** | `security.yml` | Gitleaks secrets scan, Hadolint Docker linting, Semgrep SAST, OSV-Scanner dependency SCA, TaskDef JSON validation. |
| **Build Module** | `build.yml` | Docker Buildx, Syft CycloneDX SBOM generation, Trivy container image scan, keyless Cosign signing, ECR push. |
| **Deploy Module** | `deploy.yml` | Checkov IaC scan, Terraform validation, Task Definition registration, ECS Service zero-downtime rollout. |
| **Validation Module**| `validate.yml` | ALB smoke tests, OWASP ZAP DAST scan, SARIF uploads, GitHub issue creation, step summary. |
| **Secrets Scanning** | Gitleaks v8 | Scans Git commits and tree for exposed credentials and tokens. |
| **Linting** | Hadolint v3 | Enforces Dockerfile security best practices. |
| **SAST** | Semgrep | Code vulnerability scanning (OWASP Top 10, Django, Python). |
| **SCA** | OSV-Scanner | Open-source dependency vulnerability discovery. |
| **IaC Security** | Checkov | Terraform template security & compliance scanning. |
| **SBOM & Supply Chain** | Syft & Cosign | Generates CycloneDX SBOMs and keyless OIDC container signatures via Sigstore. |
| **Container Scanner** | Trivy | Image vulnerability scanner for OS packages & dependencies. |
| **Target Workload** | OWASP PyGoat | Intentionally vulnerable Python/Django application target. |
| **Container Orchestrator**| Amazon ECS (Fargate) | Serverless container execution with non-root security context (`10001:10001`) & Task Auto Scaling. |
| **Traffic Routing** | Application Load Balancer | Ingress routing, target group health checking (`/health`), and Task Security Group isolation. |
| **Observability** | CloudWatch & Container Insights| Centralized JSON container log aggregation (`/ecs/vault-forge-app`) and vCPU/RAM performance metrics. |
