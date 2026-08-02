# VaultForge — Monitoring & Runtime Security Infrastructure

## 1. Observability Stack Architecture

Observability and runtime threat detection are fully defined as code:

- **Prometheus**: Automatically discovers scrape targets via `ServiceMonitor` resources in namespace `vault-forge`.
- **Alertmanager**: Evaluates `PrometheusRule` definitions and routes high-severity alerts to configured webhook endpoints (`webhook-critical` and `webhook-default`).
- **Grafana**: Automatically provisions pre-configured dashboard JSONs (`app-golden-signals.json` and `pipeline-security-trend.json`) via ConfigMap mounting.
- **Falco eBPF DaemonSet**: Kernel-level intrusion detection system running as a Kubernetes DaemonSet using the modern eBPF driver.

---

## 2. Prometheus Alert Routing Matrix

| Alert Name | Severity | Condition | Action / Target |
|---|---|---|---|
| `VaultForgeHighErrorRate` | Critical | HTTP 5xx error rate > 5% for 2m | Alertmanager -> Webhook Critical |
| `VaultForgeHighLatency` | Warning | P95 latency > 2s for 5m | Alertmanager -> Webhook Default |
| `VaultForgePodRestarting` | Critical | Container restart rate > 0 for 1m | Alertmanager -> Webhook Critical |
| `FalcoUnexpectedEgress` | Warning | Outbound network connection outside egress policy | Falcosidekick -> Webhook |

---

## 3. Falco Custom Rules

Custom eBPF rules are defined in [`runtime-security/falco/values.yaml`](file:///D:/VaultForge/runtime-security/falco/values.yaml):

```yaml
customRules:
  vault-forge-rules.yaml: |-
    - rule: Unexpected outbound connection from vault-forge-app
      desc: Detect the app container making connections outside expected egress
      condition: >
        outbound and container.name = "vault-forge-app"
        and not fd.sip in (allowed_egress_ips)
      output: >
        Unexpected egress from vault-forge-app (command=%proc.cmdline connection=%fd.name)
      priority: WARNING
      tags: [network, vault-forge]
```

---

## 4. Incident Response Runbooks

### Incident 1: Falco Runtime Intrusion Alert
1. Identify the pod name and node IP from the Falco JSON payload (`container.id`, `k8s.pod.name`).
2. Isolate the affected pod by applying network containment or deleting the pod:
   `kubectl delete pod <pod-name> -n vault-forge`
3. Inspect container logs and audit events for spawned shell processes or unexpected network sockets.

### Incident 2: High Error Rate / CrashLoopBackOff Alert
1. Inspect deployment rollout status:
   `kubectl rollout status deployment/vault-forge-app -n vault-forge`
2. Fetch logs for crashing container:
   `kubectl logs -n vault-forge -l app=vault-forge-app --tail=100 --previous`
3. Trigger automated rollback if a recent image rollout caused the instability:
   `kubectl rollout undo deployment/vault-forge-app -n vault-forge`
