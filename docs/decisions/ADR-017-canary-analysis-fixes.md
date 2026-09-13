# ADR-017: Canary AnalysisTemplate Fixes and Rollback Verification

## Context
The Backstage canary AnalysisTemplate ("pods-ready" metric) failed with two
distinct root causes, resolved sequentially:

1. The query `kube_deployment_status_replicas_ready{deployment="backstage"}`
   returned no data because Backstage runs as an Argo Rollout, not a
   Deployment — Argo Rollouts manages ReplicaSets directly and never creates
   a Deployment object, so no such metric series can ever exist.
2. After switching to `sum(kube_pod_status_ready{namespace="forge-platform",condition="true"})`,
   the successCondition `result >= 1` still errored with
   "mismatched types []float64 and int" — the Prometheus provider always
   returns results as an array, even for a single aggregate value.
   Fixed with `result[0] >= 1`.

## Decision
Use namespace-scoped pod-ready counts (not per-Deployment metrics) for
Rollout-managed workloads, and always index into `result[0]` for
Prometheus-provider successConditions in this cluster.

## Verification
- Canary reached Status: Healthy, Step 6/6, with a Successful AnalysisRun.
- Deliberate bad-tag rollback test performed: canary pod entered
  ImagePullBackOff, Rollout correctly failed to progress past
  progressDeadlineSeconds, stable revision continued serving 100% traffic
  throughout with zero downtime.
