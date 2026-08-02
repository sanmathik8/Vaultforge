# VaultForge DevSecOps Pipeline Run Log

## Phase 1 — Repository Initialization & GitHub Push
- **Status**: SUCCESS
- **Action**: Initialized git repository, added all project files, committed initial VaultForge DevSecOps structure, set default branch to `main`, added remote `https://github.com/sanmathik8/Vaultforge.git`, and pushed `main` to GitHub.
- **Result**: `main` branch pushed cleanly to `https://github.com/sanmathik8/Vaultforge.git`.

## Phase 2 — Pipeline Runs & Fixes Log

### Run 0: Initial Push to Main
- **Branch**: `main`
- **Initial Failures**:
  1. `kube-score` failed due to missing container ephemeral-storage requests/limits, low runAsUser/Group IDs, missing imagePullPolicy, identical readiness/liveness probes, and static replicas conflicting with HPA.
  2. `Gitleaks` failed due to mock training lab tokens in OWASP PyGoat application code (`app/introduction/`).
  3. `VaultForge Pipeline` top-level orchestrator hit startup failure due to required secret constraints on unconfigured AWS roles/ECR repositories.

### Fixes Applied (Iterating on `scratch/fix-pipeline`)
1. **Gitleaks Scan Configuration (`.gitleaks.toml`)**
   - **Fix**: Created `.gitleaks.toml` at repository root allowlisting mock lab tokens in `app/introduction/.*`.
   - **Verification**: Verified locally with `gitleaks detect` (`0 leaks found`).

2. **Kubernetes Manifest Validation (`kube-score`)**
   - **Fixes**:
     - Updated `kubernetes/base/deployment.yaml`:
       - Added `ephemeral-storage` requests (`100Mi`) and limits (`512Mi`).
       - Added `imagePullPolicy: Always`.
       - Updated securityContext to use `runAsUser: 10001`, `runAsGroup: 10001`, `fsGroup: 10001`.
       - Added `podAntiAffinity` rule for host scheduling distribution.
       - Configured `readinessProbe` to `/health` and `livenessProbe` to `/`.
     - Updated `kubernetes/overlays/dev/kustomization.yaml` and `prod/kustomization.yaml`:
       - Removed static `replicas` override from kustomize manifests to allow HPA to control pod scaling.
   - **Verification**: Rendered kustomize manifests and validated with `kube-score score` (All 5 Kubernetes resources passed with 100% green status `✅`).

3. **Application Health Check Endpoint (`app/`)**
   - **Fix**: Added `/health` endpoint returning `{"status": "ok"}` in `app/introduction/views.py` and `app/introduction/urls.py`.
   - **Rationale**: Supports Kubernetes container probes and `scripts/smoke-test.sh`.

4. **Workflow Configuration & Guard Conditions (`.github/workflows/`)**
   - **Fix**: Set `required: false` on secrets in `ci-security.yml` and `cd-deploy.yml` reusable workflows. Added `if` guard conditions to `sign-and-push` and `deploy` jobs to prevent pipeline startup/auth crashes when AWS secrets are unconfigured.

### Current Status
- All CI security scans (Hadolint, Gitleaks, Kube-score) and app configurations are validated and clean.
- Infrastructure Bootstrap (`infra-bootstrap.yml`) is limited to `plan` only (HARD RULE: NO `terraform apply` EVER).
