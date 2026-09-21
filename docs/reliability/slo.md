# Reliability — SLOs and Error Budget

## Source of Truth for These SLIs

Backstage exposes no Prometheus-format application metrics (`/metrics`
returns HTML, not a scrapeable metrics endpoint — confirmed via direct
`curl -i`, not assumed). SLOs here are therefore computed from
**Kubernetes-level signals** via kube-state-metrics, not from
application-level request latency or error rate. This is a real,
deliberate scope limitation (ADR-015), stated plainly rather than
implied to be more than it is.

## SLO 1 — Availability

**Target: 99% over a rolling 30-day window.**

This target was chosen, not defaulted. The platform runs a single
Rollout with 2 replicas, effectively single-zone in practice, with no
multi-region or multi-zone redundancy design. A 99.9% target would
misrepresent an architecture with no built-in redundancy against a
zone-level failure. 99% (~7.3 hours/month of allowed unavailability) is
the honest target for this design, not an aspirational one.

**SLI query:**
```promql
kube_deployment_status_replicas_available{deployment="backstage",namespace="forge-platform"}
/
kube_deployment_spec_replicas{deployment="backstage",namespace="forge-platform"}
Error budget (remaining, as a percentage):
(
  avg_over_time(
    (kube_deployment_status_replicas_available{deployment="backstage",namespace="forge-platform"}
     / kube_deployment_spec_replicas{deployment="backstage",namespace="forge-platform"})[30d:5m]
  ) - 0.99
) / (1 - 0.99) * 100
100% = full budget remaining.
0% = SLO exactly met, no margin.
Negative = SLO violated.
SLO 2 — Restart Stability
Frequent restarts are a leading indicator of instability even when SLO 1's
ratio still looks acceptable (a pod that crashes and restarts quickly can
still show as "available" in a coarse sampling window).
increase(kube_pod_container_status_restarts_total{namespace="forge-platform",pod=~"backstage.*"}[1h])
Target: 0 restarts/hour under normal operation.
What This Does Not Cover — Explicitly
Request-level latency or error rate for Backstage itself. Not
measured. Not claimed.
Dependency health as observed from Backstage's perspective (e.g.
database query latency). Not applicable — the catalog store is
in-process SQLite.
End-user-perceived availability. What is measured is Kubernetes'
view of replica availability, which is a reasonable proxy but not
the same thing.
Progressive Delivery as a Reliability Mechanism
Canary analysis (Argo Rollouts, AnalysisTemplate) uses a live query
against the same replica-readiness signal above, evaluated during each
canary step. A failing analysis triggers automatic rollout abort with
zero manual intervention — demonstrated behaviorally, not just
configured (see docs/evidence/13-canary-auto-rollback.png).
