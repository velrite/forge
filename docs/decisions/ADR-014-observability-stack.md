# ADR-014: Prometheus/Grafana/OTel Stack, Email Alerting Deferred

## Status
Accepted

## Decision
kube-prometheus-stack (Prometheus, Grafana, Alertmanager, kube-state-metrics)
installed via Helm, node-exporter and all kube-system control-plane
scrapers disabled (GKE Autopilot manages that namespace and those
components directly - not scrapeable regardless of RBAC, and Autopilot
blocks direct kube-system writes by policy). OpenTelemetry Collector
(contrib image, required for the prometheus exporter) receives OTLP
metrics/traces; traces currently only logged via the debug exporter,
not yet persisted to a trace backend - a real, documented gap.

## Deferred: Alertmanager Email Notifications
Gmail SMTP requires an App Password (distinct from account password),
and repeated attempts to capture it via terminal `read` were corrupted
by session/buffer issues unrelated to the credential itself. Deferred
rather than continuing to burn time on it.

## Revisit Conditions
When alerting is actually needed: prefer a Slack incoming webhook over
SMTP - no App Password, no terminal-capture friction, faster to wire
into Alertmanager's receivers config. Revisit trace persistence
(Tempo or Cloud Trace) alongside SLO work in Phase 9, since SLO burn
rate often benefits from trace-level detail.
