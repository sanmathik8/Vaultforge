# Grafana dashboards (provisioned as code)

Place dashboard JSON exports here. They're loaded into Grafana via the
`vault-forge-dashboards` ConfigMap referenced in
`monitoring/kube-prometheus-stack/values.yaml`, so dashboards update
automatically on ConfigMap change — no manual import in the Grafana UI.

Suggested starting dashboards:
- app-golden-signals.json (latency, traffic, errors, saturation for vault-forge-app)
- pipeline-security-trend.json (Trivy/Semgrep finding counts over time, pulled from the reports/ history)
