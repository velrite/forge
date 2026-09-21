# Engineering Maturity Assessment

An honest self-assessment, not a sales pitch. Organized by what a
skeptical reviewer would actually want to know.

## Genuinely Strong, With Behavioral Evidence

- Zero-stored-credential CI/CD authentication (Workload Identity
  Federation), correctly scoped, demonstrated via a real green pipeline.
- GitOps drift correction — demonstrated live, not just configured
  (`self-heal: true` in a YAML file proves nothing on its own; the
  actual before/drift/after sequence does).
- Progressive delivery with automated rollback — demonstrated with a
  deliberately broken image, showing zero downtime to the stable
  revision.
- Admission-time policy enforcement — demonstrated by a real rejected
  `kubectl apply`, not a policy that only logs.
- Infrastructure as code with zero drift, verified via `terraform plan`
  returning "no changes" against a real, running cluster.

## Production-Shaped, Not Production-Proven

- Observability stack (real metrics, unconfirmed dashboard rendering
  and unconfirmed alert delivery — see Technical Debt).
- Cost attribution (real computed numbers, but derived from a project
  with a handful of lightly-loaded namespaces, not validated against
  sustained real-world traffic patterns).

## Incomplete

- Developer self-service is not actually end-to-end: scaffolding works,
  publishing a new service to a real repository does not.
- No application-level tracing pipeline exists beyond ephemeral
  debug-log output.

## What Would Genuinely Break at 10x Scale

- **The 2-node Autopilot footprint.** Already runs close to its memory
  ceiling with the current, single-team workload set. Ten times the
  workloads would require either a larger node pool policy or genuine
  autoscaling tuning, not just "add more replicas."
- **Single-replica, in-memory Backstage catalog.** Fine for a demo;
  would not survive real multi-team usage without a real database
  backend (the project's own ADR-007 states this explicitly as a
  revisit condition, not a surprise).
- **Kubernetes-level-only SLOs.** Would stop being sufficient the
  moment real users depend on Backstage's actual request-serving
  behavior rather than just its pod health.

## What Evidence Is Genuinely Missing

Vulnerability scan output has never been pulled and reviewed, despite
scanning being enabled. Grafana and Slack delivery are configured but
unconfirmed. These are named explicitly rather than implied to be fine.
