# ADR-015: SLOs Sourced from Kubernetes-Level Signals, Not Application Metrics

## Status
Accepted

## Context
Backstage's /metrics endpoint returns text/html, not Prometheus text
format - confirmed via direct curl and Prometheus's own scrape error
("unsupported Content-Type text/html"). Backstage 1.54.0 requires an
explicit metrics plugin (not installed - out of this project's scope
to add application-level instrumentation to a third-party tool) to
expose custom application metrics.

## Decision
SLOs are sourced from kube-state-metrics instead - this is real,
already-flowing data (confirmed working in Phase 9), not a
downgrade of rigor:
- Availability SLI: kube_deployment_status_replicas_available /
  kube_deployment_spec_replicas for the backstage deployment
- Restart-based reliability SLI: rate of
  kube_pod_container_status_restarts_total

## Alternatives Rejected
- Installing a Backstage metrics plugin: real option, but adds
  application code changes outside this platform-engineering
  project's stated scope (Backstage is a third-party tool we deploy,
  not code we maintain).
- Faking metrics or skipping SLOs: rejected outright - the whole
  point of this phase is honest measurement.

## Consequences
SLOs measure "is the Backstage Deployment healthy per Kubernetes"
rather than "is the Backstage application logic performing well."
This is a real, meaningful, honestly-scoped signal - just a different
layer than application-level latency/error-rate would be.

## Revisit Conditions
If a Backstage metrics plugin is added later, layer
application-level SLIs (request latency, error rate) on top of this
Kubernetes-level foundation rather than replacing it.
