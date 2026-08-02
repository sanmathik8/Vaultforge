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
[ ECR Repository ] ──► [ TaskDef Validation ] ──► [ Fargate Execution Hardening ] ──► [ ZAP DAST Scan ]
```

---

## 2. Security Gate Specifications

| Gate | Stage | Tool | Blocking Condition | Bypass / Exemption |
|---|---|---|---|---|
| **Secret Scan** | Pre-build | Gitleaks | Exposed credentials in Git history | Allowlist via `.gitleaks.toml` |
| **Dockerfile Lint** | Pre-build | Hadolint | Severe Dockerfile bad practices | Ignore rules in Hadolint config |
| **SAST** | Pre-build | Semgrep | Critical severity OWASP findings | Repo variable `ALLOW_CRITICAL_CVES=true` |
| **Dependency SCA** | Pre-build | OSV-Scanner | Vulnerable Python packages | OSV ignore config |
| **IaC Security** | Pre-deploy | Checkov | Critical Terraform security violations | Checkov inline skips / flags |
| **Container CVE** | Post-build | Trivy | Critical severity OS/package CVEs | Repo variable `ALLOW_CRITICAL_CVES=true` |
| **Supply Chain** | Post-build | Cosign | Unsigned / unverified image digest | N/A (Mandatory) |
| **TaskDef Syntax** | Pre-deploy | `jq` | Invalid JSON syntax in `task-definition.json` | Fix JSON formatting |

---

## 3. Least-Privilege IAM & OIDC Federation

- **Zero Long-Lived Credentials**: Static AWS access keys are eliminated. All AWS interactions authenticate via GitHub OIDC identity provider (`token.actions.githubusercontent.com`).
- **Minimal Permissions**: Every AWS workflow explicitly sets least-privilege job permissions (`permissions: { id-token: write, contents: read }`).
- **Scoped IAM Roles**:
  - **CI Push Role**: Scope restricted strictly to ECR login, tag, and push operations for `vault-forge-app`.
  - **CD Deploy Role**: Scope restricted strictly to ECS task definition registration and service rollout for `vault-forge-app`.
  - **Terraform Bootstrap Role**: Scoped strictly to Terraform S3 backend and ECS/ECR module provisioning.

---

## 4. Amazon ECS Fargate Container Hardening Standards

- **`user: "10001:10001"`**: Container process runs as non-root user ID 10,000+ to prevent root execution inside the container.
- **`readonlyRootFilesystem: true`**: Immutable root filesystem prevents unauthorized write persistence.
- **Scratch Volume Isolation**: Temporary file writes are restricted to an isolated `emptyDir` volume mounted at `/tmp`.
- **Security Group Isolation**: ECS tasks run inside an `awsvpc` security group permitting inbound HTTP traffic **strictly from the ALB security group** on port 8000. Direct public ingress to tasks is blocked.
- **CloudWatch Log Audit**: All container stdout/stderr streams are encrypted and piped to CloudWatch Log Group `/ecs/vault-forge-app`.

---

## 5. Supply Chain Security & Action Pinning Trade-Offs

- **Action Version Pinning**:
  - Production Enterprise Policy: Important third-party GitHub Actions should ideally be pinned to immutable 40-character git commit SHAs to prevent tag-hijacking supply-chain attacks.
  - Portfolio Architecture Policy: Stable semantic major version tags (e.g., `@v4`, `@v3`, `@0.28.0`) are utilized across the pipeline for readability, automated security patch updates, and maintainability.
- **Job Execution Timeouts**: All workflow jobs enforce strict `timeout-minutes: 30` execution limits to guard against runaway processes or stuck runner pools.
