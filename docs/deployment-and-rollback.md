# VaultForge — Deployment & Automated Rollback Strategy

## 1. Continuous Deployment Flow

The VaultForge CD pipeline (`deploy.yml`) handles zero-downtime container deployments to Amazon ECS Fargate.

```
[ Image Digest Output ] ──► [ Cosign Signature Verify ] ──► [ Render Task Definition ]
                                                                      │
                                                                      ▼
[ ALB Health Check ] ◄── [ ECS Rolling Deployment ] ◄── [ Register TaskDef & Update Service ]
         │
         ▼
[ OWASP ZAP DAST Scan ] ──► [ GitHub Issue Creation (if DAST findings) ] ──► [ Pipeline Summary ]
```

---

## 2. Zero-Downtime Rolling Deployment Strategy

- **ECS Rolling Deployment Parameters**:
  - `deployment_maximum_percent = 200`: Allows up to 200% of desired tasks to run concurrently during rollout.
  - `deployment_minimum_healthy_percent = 100`: Guarantees 100% healthy capacity (minimum 2 tasks) is maintained throughout the deployment cycle.
- **ALB Health Check Guard**: New tasks are added to the Application Load Balancer target group only after passing the `/health` HTTP probe (port 8000, 15s interval, 3 consecutive successes required).

---

## 3. Automated Rollback & Recovery Runbook

### Automatic Rollback Mechanism
When `aws ecs wait services-stable` fails or times out:

1. Step `Update ECS Service` exits with status `failure`.
2. Amazon ECS automatically reverts traffic routing on the ALB to the previously active Task Definition revision.
3. The workflow job logs an explicit failure to prevent unverified code promotions.

### Manual Rollback Procedure
If post-deployment anomalies occur after workflow completion:

```bash
# 1. List registered Task Definition revisions
aws ecs list-task-definitions --family-prefix vault-forge-app

# 2. Update service to use a previous known-good Task Definition revision (e.g. revision 3)
aws ecs update-service \
  --cluster vault-forge \
  --service vault-forge-app \
  --task-definition vault-forge-app:3 \
  --force-new-deployment

# 3. Wait for ECS service stabilization
aws ecs wait services-stable --cluster vault-forge --services vault-forge-app
```
