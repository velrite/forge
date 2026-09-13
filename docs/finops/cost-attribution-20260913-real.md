# Phase 12 — Real Cost Attribution (OpenCost, real GCP pricing + live usage) — 2026-09-13T01:36:44Z

## Source
OpenCost, deployed in-cluster, backed by the existing kube-prometheus-stack Prometheus instance. This replaces the earlier list-price-only estimates (see ADR-018) with actual per-namespace cost computed from real usage and Google's real GCP pricing.

## Existing GCP Billing Budget (confirmed real, already configured)
$10/month, thresholds at 50%/90%/100%/150% of spend.

## Per-namespace cost, month-to-date
```
NAMESPACE           CPU_COST    RAM_COST    TOTAL_COST  HOURS_TRACKED  
kube-system         15.9614     9.3198      25.2812     87.9           
argocd              9.6677      5.1833      14.8510     87.8           
observability       9.5528      4.8093      14.3621     87.8           
forge-platform      1.0583      0.2844      1.3427      87.8           
forge-demo          0.5540      0.0928      0.6468      87.8           
gke-managed-cim     0.2915      0.0473      0.3388      87.8           
kyverno             0.1857      0.0373      0.2230      23.5           
gke-gmp-system      0.0305      0.0305      0.0610      87.8           
argo-rollouts       0.0371      0.0062      0.0434      23.5           
opencost            0.0001      0.0000      0.0001      0.0            

TOTAL MONTH-TO-DATE (all namespaces): $57.1500
```
