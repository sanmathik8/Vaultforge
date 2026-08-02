# VaultForge

Framework-agnostic DevSecOps reference platform: secure build → scan → sign
→ deploy → runtime-monitor, tested against OWASP PyGoat as the target app on Amazon ECS Fargate.

Everything for this project lives inside this single root directory — no
sibling `.github/`, `terraform/`, or `app/` folders outside `VaultForge/`.

```text
VaultForge/
├── .github/
│   ├── workflows/
│   │   ├── pipeline.yml          # orchestrator: calls security.yml, build.yml, deploy.yml, validate.yml
│   │   ├── security.yml          # reusable: SAST (Semgrep), SCA (OSV), linters (Hadolint, Gitleaks)
│   │   ├── build.yml             # reusable: Buildx, Syft SBOM, Trivy scan, Cosign sign, ECR push
│   │   ├── deploy.yml            # reusable: Checkov IaC scan, ECS Fargate rolling deployment
│   │   ├── validate.yml          # reusable: Smoke tests, OWASP ZAP DAST scan, SARIF uploads
│   │   └── infra-bootstrap.yml   # manual-only: Terraform plan/apply for ECS/ECR/OIDC
│   └── actions/graceful-exit/    # composite action for clear failure messages
├── app/                          # target application (OWASP PyGoat)
├── ecs/                          # ECS Fargate task definition templates
│   └── task-definition.json      # Fargate task definition with non-root & read-only root FS
├── terraform/
│   ├── bootstrap/                # root module wiring oidc, ecr, and ecs_fargate sub-modules
│   └── modules/{oidc,ecr,ecs_fargate}/
├── scripts/                      # smoke-test.sh and pipeline helper scripts
├── docs/                         # comprehensive system & operational documentation
├── reports/                      # generated scan reports land here
└── README.md
```

## Before contributing (for humans or AI agents)

1. Read `docs/architecture-overview.md` first — it explains *why* things are
   structured this way, not just what's here.
2. Everything belongs under this root. If a suitable folder already exists
   for what you're adding, use it — don't create a parallel one.
3. Terraform for infrastructure (`terraform/`) is intentionally
   decoupled from the app deploy pipeline — it runs only via
   `infra-bootstrap.yml`, never on a routine app push.

## Single-Secret Architecture & Dynamic Infrastructure Discovery

VaultForge operates on an **Enterprise Single-Secret Policy**. Infrastructure metadata (ECR Repository URI, ECS Cluster Name, ECS Service Name, ALB DNS Name) is discovered automatically from AWS APIs after OpenID Connect (OIDC) authentication. **Developers do not copy infrastructure URLs into GitHub Secrets.**

### GitHub Configuration Matrix

| Name | Type | Purpose | How Value is Obtained |
|---|---|---|---|
| `AWS_ROLE_TO_ASSUME` | Secret | IAM Role ARN for OIDC authentication | From `terraform output cd_deploy_role_arn` |
| `AWS_TERRAFORM_ROLE_ARN` | Secret | IAM Role ARN for manual IaC bootstrap | From `terraform output terraform_role_arn` |
| `ALLOW_CRITICAL_CVES` | Variable | Bypass Trivy/Semgrep gates for PyGoat lab target | Set to `true` in GitHub Repository Variables |
| `ECR_REPOSITORY_URL` | **Discovered** | Target ECR Repository URI | Auto-resolved from AWS Caller Identity & STS |
| `ECS_CLUSTER_NAME` | **Discovered** | Target Amazon ECS Cluster | Auto-discovered via AWS ECS API (`aws ecs list-clusters`) |
| `ALB_DNS_NAME` | **Discovered** | Target Application Load Balancer Endpoint | Auto-discovered via AWS ELBv2 API (`aws elbv2 describe-load-balancers`) |
