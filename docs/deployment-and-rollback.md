# VaultForge — Deployment & Automated Rollback Strategy

## 1. Continuous Deployment Flow

The VaultForge CD pipeline (`cd-deploy.yml`) handles workload rollouts to Kubernetes environments (`dev` and `prod`).

```
[ Image Digest Output ] ──► [ Cosign Signature Verify ] ──► [ Kustomize Set Digest ]
                                                                       │
                                                                       ▼
[ Health Check / Smoke ] ◄── [ Automated Rollback (if fail) ] ◄── [ kubectl apply -k ]
         │
         ▼
[ OWASP ZAP DAST Scan ] ──► [ GitHub Issue Creation (if DAST findings) ] ──► [ Deploy Summary ]
```

---

## 2. Zero-Downtime Rolling Strategy

- **RollingUpdate Parameters**:
  - `maxSurge: 25%`: Up to 25% additional pods created during rollout.
  - `maxUnavailable: 0`: Ensures 100% capacity is maintained throughout deployment.
- **Pod Readiness Guard**: Pods are only added to Service load balancer routing after passing the `/health` readiness probe (5s initial delay, 3 consecutive successes required).
- **Pod Disruption Budget**: Guarantees `minAvailable: 1` pod during node drains or cluster upgrades.

---

## 3. Automated Rollback Runbook

### Automatic Rollback Mechanism
When `kubectl rollout status deployment/vault-forge-app -n vault-forge --timeout=180s` fails or times out (due to `ImagePullBackOff`, `CrashLoopBackOff`, or probe failure):

1. Step `Wait for rollout` exits with status `failure`.
2. Step `Rollback on failure` triggers automatically via `if: steps.rollout.outcome == 'failure'`.
3. Executes `kubectl rollout undo deployment/vault-forge-app -n vault-forge`.
4. Reverts the Deployment specification to the previous known-good replica revision instantly.
5. Fails the workflow job with explicit error message to prevent unverified rollouts.

### Manual Rollback Procedure
If post-deployment anomalies occur after workflow completion:

```bash
# 1. View deployment rollout history
kubectl rollout history deployment/vault-forge-app -n vault-forge

# 2. Roll back to the immediately preceding revision
kubectl rollout undo deployment/vault-forge-app -n vault-forge

# 3. Roll back to a specific revision (e.g. revision 2)
kubectl rollout undo deployment/vault-forge-app -n vault-forge --to-revision=2

# 4. Verify deployment health status
kubectl rollout status deployment/vault-forge-app -n vault-forge
```
