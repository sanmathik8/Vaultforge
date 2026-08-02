# VaultForge — System Architecture & Platform Overview

## 1. Executive Summary
VaultForge is a enterprise-grade DevSecOps platform demonstrating end-to-end security automation, continuous integration, immutable deployment, runtime threat detection, and continuous observability for containerized workloads.

---

## 2. Architectural Layers

```
                               ┌──────────────────────────────────────────────┐
                               │             GitHub Actions CI/CD             │
                               │   (OIDC Federation - Least Privilege Role)   │
                               └──────────────────────┬───────────────────────┘
                                                      │
                       ┌──────────────────────────────┴──────────────────────────────┐
                       ▼                                                             ▼
         ┌───────────────────────────┐                                 ┌───────────────────────────┐
         │     Security Gates        │                                 │     Build & Sign          │
         │ Gitleaks, Hadolint,      │                                 │ Docker Buildx, Syft SBOM, │
         │ Semgrep, OSV, kube-score  │                                 │ Cosign Keyless OIDC Sign  │
         └─────────────┬─────────────┘                                 └─────────────┬─────────────┘
                       │                                                             │
                       └──────────────────────────────┬──────────────────────────────┘
                                                      ▼
                                       ┌──────────────────────────────┐
                                       │     Amazon ECR (Immutable)   │
                                       └──────────────┬───────────────┘
                                                      │
                                                      ▼
                                       ┌──────────────────────────────┐
                                       │     Amazon EKS Cluster       │
                                       │  (Private Subnets, KMS Enc)  │
                                       └──────────────┬───────────────┘
                                                      │
       ┌──────────────────────────────────────────────┼──────────────────────────────────────────────┐
       ▼                                              ▼                                              ▼
┌──────────────────────────────┐            ┌──────────────────────────────┐            ┌──────────────────────────────┐
│  Kyverno Policy Admission    │            │     Kubernetes Workload      │            │   Falco Runtime Security     │
│  (Block Priv, Non-Root,      │            │ (PyGoat App, HPA, PDB, NP)   │            │   (eBPF Engine DaemonSet)    │
│   Resource Limits, Signatures│            └──────────────┬───────────────┘            └──────────────┬───────────────┘
└──────────────────────────────┘                           │                                           │
                                                           ▼                                           ▼
                                            ┌──────────────────────────────┐            ┌──────────────────────────────┐
                                            │ kube-prometheus-stack        │            │ Falcosidekick Webhook        │
                                            │ (Prometheus, Grafana, Alert) │            │ (Alerting & Incident Response│
                                            └──────────────────────────────┘            └──────────────────────────────┘
```

---

## 3. Component Responsibilities

| Layer | Technology | Primary Function |
|---|---|---|
| **IaC** | Terraform 1.14+ | Provisions AWS EKS, ECR (immutable tags), KMS encryption, OIDC IAM roles. |
| **CI Orchestrator** | GitHub Actions | Executes pipeline workflows (`pipeline.yml`, `ci-security.yml`, `cd-deploy.yml`). |
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
- **`kubernetes/overlays/prod/`**: Production environment configuration (3-10 replicas HPA, production environment approval gate).
