# Forge SLOs - PromQL Reference

## SLO 1: Backstage Availability - 99% over 30 days
Reasoning: single-replica, single-zone, solo-builder demo platform.
99.9% would misrepresent an architecture with no redundancy. 99%
(~7.3 hours/month allowed downtime) is honest for this design.

Query (instantaneous availability ratio):
    kube_deployment_status_replicas_available{deployment="backstage",namespace="forge-platform"}
    /
    kube_deployment_spec_replicas{deployment="backstage",namespace="forge-platform"}

Query (30-day average, the actual SLI):
    avg_over_time(
      (kube_deployment_status_replicas_available{deployment="backstage",namespace="forge-platform"}
       / kube_deployment_spec_replicas{deployment="backstage",namespace="forge-platform"})[30d:5m]
    )

## Error Budget (remaining, as a percentage)
    (
      avg_over_time(
        (kube_deployment_status_replicas_available{deployment="backstage",namespace="forge-platform"}
         / kube_deployment_spec_replicas{deployment="backstage",namespace="forge-platform"})[30d:5m]
      ) - 0.99
    ) / (1 - 0.99) * 100

Interpretation: 100% = full budget remaining, 0% = budget exhausted
(SLO exactly met), negative = SLO violated.

## SLO 2: Restart Stability
Reasoning: frequent restarts are a leading indicator of instability
even when the SLO 1 ratio still looks fine (a fast-crashing pod that
restarts quickly can still show 1/1 available).

Query (restarts in the last hour):
    increase(kube_pod_container_status_restarts_total{namespace="forge-platform",pod=~"backstage.*"}[1h])

Target: 0 restarts/hour under normal operation. Any non-zero value
warrants investigation, even though it does not directly violate SLO 1.
