# VaultForge — Security & Compliance Architecture

## 1. Shift-Left Security Pipeline

Security controls are embedded directly into every stage of the software delivery lifecycle:

```
[ Code Commit ] ──► [ Gitleaks Secret Scan ] ──► [ Hadolint Docker Lint ] ──► [ Semgrep SAST / OSV SCA ]
                                                                                      │
                                                                                      ▼
[ Cosign Image Sign ] ◄── [ Trivy Container Scan ] ◄── [ Syft SBOM Generation ] ◄── [ Docker Buildx ]
         │
         ▼
[ ECR Repository ] ──► [ Kyverno Admission Enforce ] ──► [ Falco eBPF Runtime ] ──► [ ZAP DAST Scan ]
```

---

## 2. Security Gate Specifications

| Gate | Stage | Tool | Blocking Condition | Bypass / Exemption |
|---|---|---|---|---|
| **Secret Scan** | Pre-build | Gitleaks | Exposed credentials in Git history | Allowlist via `.gitleaks.toml` |
| **Dockerfile Lint** | Pre-build | Hadolint | Severe Dockerfile bad practices | Ignore rules in Hadolint config |
| **SAST** | Pre-build | Semgrep | Critical severity OWASP findings | Repo variable `ALLOW_CRITICAL_CVES=true` |
| **Dependency SCA** | Pre-build | OSV-Scanner | Vulnerable Python packages | OSV ignore config |
| **Manifest Security** | Pre-build | kube-score | Critical scoring violations | Fix manifest specifications |
| **Container CVE** | Post-build | Trivy | Critical severity OS/package CVEs | Repo variable `ALLOW_CRITICAL_CVES=true` |
| **Supply Chain** | Post-build | Cosign | Unsigned / unverified image digest | N/A (Mandatory) |
| **Admission Gate** | Deploy | Kyverno | Policy violation on `kubectl apply` | N/A (Policy `validationFailureAction: Enforce`) |

---

## 3. Least-Privilege IAM & OIDC Federation

- **Zero Long-Lived Credentials**: Static AWS access keys are eliminated. All AWS interactions authenticate via GitHub OIDC identity provider (`token.actions.githubusercontent.com`).
- **Scoped IAM Roles**:
  - **CI Push Role**: Scope restricted strictly to ECR login, tag, and push operations for `vault-forge-app`.
  - **CD Deploy Role**: Scope restricted strictly to EKS `kubeconfig` update and deployment operations in namespace `vault-forge`.
  - **Terraform Bootstrap Role**: Scoped strictly to Terraform S3 backend and EKS/ECR module provisioning.

---

## 4. Kubernetes Hardening Standards

- **`runAsNonRoot: true`**: Pods refuse execution as UID 0.
- **`runAsUser: 10001`**: Custom non-root user ID above 10,000 to prevent host UID collisions.
- **`readOnlyRootFilesystem: true`**: Immutable root filesystem prevents unauthorized write persistence.
- **`allowPrivilegeEscalation: false`**: Blocks `setuid` binaries inside containers.
- **`capabilities.drop: ["ALL"]`**: Drops all Linux kernel capabilities.
- **`seccompProfile.type: RuntimeDefault`**: Restricts system calls.
- **NetworkPolicy**: Default-deny ingress/egress with explicit rules for DNS (UDP/TCP 53), HTTPS (TCP 443), and Ingress NGINX (TCP 8000).
