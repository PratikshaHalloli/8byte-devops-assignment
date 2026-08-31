# Monitoring & Logging

## Metrics — kube-prometheus-stack

Deployed via Helm: Prometheus, Grafana, Alertmanager, node-exporter, kube-state-metrics.

### Install
\`\`\`bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f monitoring/prometheus-grafana-values.yaml
\`\`\`

Covers infrastructure metrics — CPU/memory per node and per pod/container, via node-exporter and kube-state-metrics.

## Logs — Loki + Promtail

### Install
\`\`\`bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install loki-stack grafana/loki-stack \
  -n monitoring \
  -f monitoring/loki-values.yaml
\`\`\`

Promtail runs as a DaemonSet on every node and ships container stdout/stderr logs to Loki — covers application and system/pod logs.

## Accessing Grafana

\`\`\`bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
\`\`\`

Open http://localhost:3000. Get the admin password:
\`\`\`bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d
\`\`\`

Add Loki as a Grafana datasource (Connections → Data sources → Add → Loki, URL: \`http://loki-stack:3100\`) to query logs alongside metrics.

## Dashboards

1. **Kubernetes / Compute Resources / Cluster** (built into the chart) — cluster-wide node CPU, memory, disk, network.
2. **Kubernetes / Views / Pods** — per-container CPU usage, memory usage, and CPU throttling, filterable by namespace/pod/job. Used here to monitor the \`monitoring\` namespace workloads (Prometheus, Grafana, Loki, kube-state-metrics).

## Known gaps

- App-level metrics (request rate, error rate, latency from the Node.js app) and RDS-level metrics are not yet scraped by Prometheus. Would need \`prom-client\` instrumentation added to \`app/index.js\` exposing a \`/metrics\` endpoint, plus a \`postgres_exporter\` for the database.
- No access-log capture at an ingress layer, since the app is exposed via a plain \`LoadBalancer\` Service rather than an Ingress controller.
