Observability
Stack
kube-prometheus-stack (Prometheus, Grafana, Alertmanager,
kube-state-metrics) via Helm, plus an OpenTelemetry Collector
(contrib image — required specifically because the prometheus
exporter does not exist in the core OTel image).
What GKE Autopilot Changes Here
The standard kube-prometheus-stack chart attempts to scrape
control-plane components (etcd, scheduler, controller-manager,
CoreDNS, kube-proxy) by creating Services inside kube-system.
Autopilot manages that namespace directly and rejects external writes
to it (GKE Warden authz: denied by managed-namespaces-limitation) —
and more fundamentally, Google runs those components, not this
project, so they were never meaningfully scrapeable regardless of
permissions. All of these scrape targets are explicitly disabled in
the Helm values. node-exporter is also disabled — it requires
hostPath access, which Autopilot's pod security policy blocks
outright.
What Is Actually Observable
Kubernetes-level metrics (pod status, deployment replica counts,
restart counts) via kube-state-metrics — confirmed live and scraping
(docs/evidence/16).
The SLO computed from the above — confirmed via a live PromQL
query returning a real value (docs/evidence/17).
Per-namespace cost attribution via OpenCost, computed from actual
GCP list pricing against actual resource requests — confirmed with
real, non-uniform numbers across namespaces (docs/evidence/19).
What Is Not Observable (Stated Plainly)
Application-level metrics for Backstage. No request rate,
latency, or error-rate data exists for the application itself — only
its Kubernetes-level health. See docs/reliability/slo.md.
Traces. The OTel Collector receives OTLP trace data and routes it
to a debug exporter, which writes to the collector's own pod logs.
There is no trace storage or query backend (e.g. Tempo, Cloud Trace)
wired in. Traces exist transiently in logs, not as queryable data.
Alerting delivery. A Slack webhook receiver was configured in
Alertmanager. Delivery to the channel has not been confirmed as of
this writing — marked Not Verified, not Working.
Grafana dashboard rendering. A dashboard ConfigMap (labeled for
the Grafana sidecar's auto-discovery) has been applied. Whether
Grafana actually picked it up and renders real panel data has not
been confirmed. Marked Not Verified.
How an Engineer Would Actually Diagnose a Problem Here Today
Given the above, the real diagnostic path is: kubectl for pod/event
state first, then a direct Prometheus query (via port-forward) for any
Kubernetes-level metric, then OpenCost for cost-shape anomalies. Grafana
and Slack are not yet reliable parts of that path — this is stated here
so an operator doesn't waste time trusting a dashboard that has never
been confirmed to render correctly.
