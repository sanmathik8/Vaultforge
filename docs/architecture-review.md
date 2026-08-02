# Architecture Review — Fixes Applied

Source review covered 9 areas (architecture, missing components, tool
choice, automation, Kubernetes, AWS, observability, readiness scoring,
final verdict). This document tracks what changed as a result.

| # | Finding | Fix | Where |
|---|---|---|---|
| 1 | Long-lived AWS keys implied for ECR/Terraform access | GitHub OIDC federation, two least-privilege roles (CI push-only, CD deploy-only) | `terraform/modules/oidc`, `.github/workflows/ci-security.yml`, `cd-deploy.yml` |
| 2 | No concurrency control → possible race on simultaneous pushes | `concurrency` block on every workflow, scoped per ref/overlay | all workflow files |
| 3 | Terraform apply coupled to every app push | Moved to `infra-bootstrap.yml`, manual `workflow_dispatch` + PR-triggered plan only, with its own environment-gated apply | `.github/workflows/infra-bootstrap.yml` |
| 4 | SARIF uploaded once at the end (lost if an earlier gate failed) | Each scanner uploads its own SARIF immediately after it runs | `ci-security.yml`, `cd-deploy.yml` |
| 5 | No PodDisruptionBudget; Metrics Server present but no HPA object | Added `poddisruptionbudget.yaml` and `hpa.yaml` | `kubernetes/base/` |
| 6 | No environment approval gate before deploy; ECR missing lifecycle policy / immutable tags | `environment: production` gate on `cd-deploy.yml`; `IMAGE_TAG_MUTABILITY=IMMUTABLE` + lifecycle policy on ECR | `cd-deploy.yml`, `terraform/modules/ecr` |
| — | Alertmanager/Falco installed but no receiver wired (automation-gap finding) | Webhook receivers set in both Helm values files | `monitoring/kube-prometheus-stack/values.yaml`, `runtime-security/falco/values.yaml` |

## What was deliberately left out

Per the review's own recommendation: no second policy engine alongside
Kyverno, no service mesh, no GitOps controller (Argo CD/Flux) unless a
future review specifically asks for progressive-delivery — none of these
add proportional value at this project's scope and would just be tools
added for their own sake.
