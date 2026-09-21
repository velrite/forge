# Forge — System Overview

## What This Is

Forge is a self-service Internal Developer Platform built on Google Kubernetes
Engine (Autopilot). It provides a developer portal (Backstage), a GitOps
delivery path (GitLab CI/CD -> Argo CD -> Argo Rollouts), and a platform-level
observability, policy, and cost-attribution layer (Prometheus, Kyverno,
OpenCost).

This document describes the system as it is actually deployed, not as
originally planned. Where a capability exists as configuration but has not
been behaviorally verified, it is marked **Not Verified** rather than
described as working.

## Core Infrastructure

| Component | Value |
|---|---|
| GCP Project | `forge-platform-11124` |
| Region | `us-central1` |
| Cluster | `forge-cluster` — GKE Autopilot, regional, private nodes |
| VPC | `forge-vpc` / subnet `forge-subnet` |
| Terraform state | GCS bucket `forge-platform-11124-tfstate`, versioned |
| Image registry | Artifact Registry `forge-images`, immutable tags |
| Source of truth | GitHub (private repo), mirrored to GitLab for CI execution |

Autopilot was chosen over Standard mode because node lifecycle management
(patching, sizing, bin-packing) is not the subject this project is
demonstrating — the platform-engineering surface area (RBAC, GitOps,
progressive delivery, policy enforcement) is the same either way, and
Autopilot removes an entire category of node-management concerns that
would otherwise compete for attention with that surface area. See
`docs/decisions/ADR-003` for the full reasoning.

## Component Map
Developer
| |
v
Backstage (developer portal, forge-platform namespace)
|  scaffolds a service from a template
v
GitLab (CI/CD execution, authenticates to GCP via Workload Identity
Federation — no stored service-account keys)
|  test -> security scan -> build -> push
v
Artifact Registry (forge-images, immutable tags)
| |
v
Argo CD (GitOps controller, watches the GitHub repo)
|  reconciles declared state into the cluster
v
Argo Rollouts (canary controller for the Backstage workload:
20% -> analysis -> 50% -> analysis -> 100%)
| |
v
GKE Autopilot (forge-cluster)
| |
+-- Prometheus / Grafana / OpenTelemetry Collector (observability)
+-- Kyverno (admission-time policy enforcement)
+-- OpenCost (per-namespace cost attribution)
## What Argo CD Manages vs. What It Does Not

Argo CD manages **application workloads** (the `forge-demo` GitOps
application). It does **not** manage the platform components themselves
(Argo CD's own installation, Backstage, Prometheus, Kyverno) — those are
installed via `kubectl`/Helm directly. This is a deliberate bootstrap
exception, not an inconsistency: Argo CD cannot GitOps-manage its own
installation before it exists, and extending that same bootstrap path to
other platform infrastructure keeps the operational model for "how does
platform infra change" consistent and explicit. See ADR-005.

## Deployment Mechanism for Backstage

Backstage runs as an Argo **Rollout**, not a plain Kubernetes Deployment.
This is what enables canary delivery: traffic is shifted in stages
(20% -> 50% -> 100%) with an automated health check (`AnalysisTemplate`)
between stages, backed by a live Prometheus query against
`kube_deployment_status_replicas_ready`. If the analysis fails, the
Rollout controller aborts automatically and traffic stays on the last
known-good revision — this behavior has been demonstrated, not just
configured (see `docs/evidence/`).

## Known Structural Limitations

- **Single replica pair, single zone effectively.** This is not a
  highly-available production deployment. The 99% availability target
  in `docs/reliability/slo.md` reflects this honestly rather than
  claiming 99.9%.
- **Backstage's catalog is SQLite, in-memory.** Catalog state does not
  survive a pod restart. This was a deliberate demo-scope trade-off, not
  an oversight — see ADR-007.
- **Backstage exposes no Prometheus-format metrics.** `/metrics` returns
  HTML, not a metrics plugin's output. SLOs are therefore sourced from
  Kubernetes-level signals (via kube-state-metrics) rather than
  application-level request/latency data. See ADR-015.
