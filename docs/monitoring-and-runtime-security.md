# VaultForge — Monitoring & Observability Architecture

## 1. Observability Stack Architecture

Observability for Amazon ECS Fargate is fully defined as code via Terraform and AWS CloudWatch:

- **CloudWatch Log Group**: Dedicated log group `/ecs/vault-forge-app` with 30-day retention storing JSON stdout/stderr container logs.
- **Container Insights**: Enabled on `aws_ecs_cluster.app` for vCPU, Memory, Network, and Task-level performance telemetry.
- **ALB Metrics**: Automatic monitoring of Application Load Balancer HTTP 2xx/4xx/5xx response codes, target response time, and active connection counts.
- **Service Auto Scaling**: Metric alarms tracking CPU average utilization (70%) and Memory average utilization (80%).

---

## 2. CloudWatch Metric & Alarm Matrix

| Metric Name | Namespace | Threshold | Action / Target |
|---|---|---|---|
| `HTTPCode_Target_5XX_Count` | `AWS/ApplicationELB` | > 5 count over 5m | CloudWatch Alarm -> SNS Notification |
| `TargetResponseTime` | `AWS/ApplicationELB` | P95 > 2s for 5m | CloudWatch Alarm -> SNS Notification |
| `CPUUtilization` | `AWS/ECS` | > 70% | Target Tracking Scaling (Scale Out) |
| `MemoryUtilization` | `AWS/ECS` | > 80% | Target Tracking Scaling (Scale Out) |

---

## 3. Container Runtime Hardening Controls

Security controls for container execution on Fargate:

- **Non-Root Execution**: Container process runs as non-root user `10001:10001`.
- **Read-Only Root Filesystem**: `readonlyRootFilesystem = true` prevents unauthorized filesystem modifications.
- **Scratch Volume Isolation**: Temporary file writes are restricted to an isolated `emptyDir` volume mounted at `/tmp`.
- **Network Isolation**: ECS tasks operate inside an `awsvpc` security group permitting inbound HTTP traffic **strictly from the ALB security group** on port 8000. Direct public ingress to tasks is blocked.

---

## 4. Incident Response Runbook

### Incident 1: High 5xx Error Rate / ALB Health Check Failure
1. Inspect CloudWatch logs for container error tracebacks:
   `aws logs tail /ecs/vault-forge-app --follow`
2. Verify ECS Task status and health check events:
   `aws ecs describe-services --cluster vault-forge --services vault-forge-app`
3. Trigger manual rollback to a previous Task Definition revision if necessary.
