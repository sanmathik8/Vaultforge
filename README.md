# VaultForge

Framework-agnostic DevSecOps reference pipeline: secure build → scan → sign
→ deploy → runtime-monitor, tested against OWASP PyGoat as the target app.

Everything for this project lives inside this single root directory — no
sibling `.github/`, `terraform/`, or `app/` folders outside `VaultForge/`.

```text
VaultForge/
├── .github/
│   ├── workflows/
│   │   ├── pipeline.yml          # orchestrator: calls ci-security.yml then cd-deploy.yml
│   │   ├── ci-security.yml       # reusable: build, scan, sign, push (OIDC)
│   │   ├── cd-deploy.yml         # reusable: environment-gated deploy + DAST
│   │   └── infra-bootstrap.yml   # manual-only: Terraform plan/apply for EKS/ECR/OIDC
│   └── actions/graceful-exit/    # composite action for clear failure messages
├── app/                          # target application (OWASP PyGoat)
├── terraform/
│   ├── bootstrap/                # root module wiring the three sub-modules below
│   └── modules/{oidc,ecr,eks}/
├── kubernetes/
│   ├── base/                     # Deployment, Service, RBAC, NetworkPolicy, PDB, HPA
│   └── overlays/{dev,prod}/      # Kustomize overlays, prod requires environment approval
├── security/
│   └── kyverno-policies/         # admission policies: non-root, no-privileged, resource limits, signature verification
├── monitoring/
│   ├── kube-prometheus-stack/    # Helm values, Alertmanager receiver wired
│   └── dashboards/               # Grafana dashboards provisioned as code
├── runtime-security/
│   └── falco/                    # Helm values, DaemonSet runtime monitoring, Slack alerting wired
├── scripts/                      # smoke-test.sh and other pipeline helper scripts
├── docs/
│   └── architecture-review.md    # maps each review finding to the fix applied
├── reports/                      # generated scan reports land here (gitignored contents, tracked folder)
├── samples/                      # example manifests / config for onboarding new agents to this repo
├── README.md
└── LICENSE
```

## Before contributing (for humans or AI agents)

1. Read `docs/architecture-review.md` first — it explains *why* things are
   structured this way, not just what's here.
2. Everything belongs under this root. If a suitable folder already exists
   for what you're adding, use it — don't create a parallel one.
3. Terraform for cluster/registry infra (`terraform/`) is intentionally
   decoupled from the app deploy pipeline — it runs only via
   `infra-bootstrap.yml`, never on a routine app push.
4. Production deploys (`kubernetes/overlays/prod`) require a GitHub
   Environment approval — see the `environment:` key in `cd-deploy.yml`.

## Required repo secrets / variables

| Name | Used by | Purpose |
|---|---|---|
| `AWS_ECR_PUSH_ROLE_ARN` | ci-security.yml | OIDC role, ECR push only |
| `AWS_EKS_DEPLOY_ROLE_ARN` | cd-deploy.yml | OIDC role, EKS deploy only |
| `AWS_TERRAFORM_ROLE_ARN` | infra-bootstrap.yml | OIDC role, infra apply |
| `ECR_REPOSITORY_URL` | ci-security.yml | Target ECR repo (from `terraform output`) |
| `EKS_CLUSTER_NAME` | cd-deploy.yml | Target cluster name |
| `ALLOW_CRITICAL_CVES` (var) | ci-security.yml | Bypass Trivy/Semgrep gates for demo targets with known intentional vulns (e.g. PyGoat) |
