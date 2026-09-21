# Forge — Internal Developer Platform

Forge is a self-service Internal Developer Platform (IDP) on Google
Kubernetes Engine (Autopilot), demonstrating a real GitOps delivery
path — GitLab CI/CD → Argo CD → Argo Rollouts — with policy-as-code
enforcement, Kubernetes-level SLOs, and per-namespace cost attribution.

**Status: Core platform deployed and behaviorally verified.** The
developer portal (Backstage), zero-stored-credential CI/CD, GitOps
drift correction, canary delivery with automated rollback, and
admission-time policy enforcement have all been demonstrated on real
infrastructure — not just configured. See `docs/evidence/` for the
captured proof behind each claim, and `docs/engineering/technical-debt.md`
for exactly what has not yet been verified or built.

## What Forge Does

A developer scaffolds a new service from Backstage. GitLab CI tests,
scans, and builds it, authenticating to GCP with zero stored
credentials (Workload Identity Federation). The image is pushed to an
immutable-tag Artifact Registry. Argo CD continuously reconciles the
live cluster to match what's declared in Git — including reverting
unauthorized manual changes automatically, demonstrated live, not
assumed. New versions roll out gradually via Argo Rollouts, with a
failing canary automatically aborted with zero manual intervention.
Kyverno enforces supply-chain and tagging policy at admission time.

This is a platform-engineering project. It does not run a production
workload with real user traffic — see "What Forge Does Not Do" below.

## What Forge Does Not Do (Stated Plainly)

- Does not serve application-level metrics for Backstage — only
  Kubernetes-level health (pod/replica status), by design. See
  `docs/reliability/slo.md`.
- Does not yet support publishing a scaffolded service to a real Git
  repository end-to-end — the golden-path template stops at local
  generation. See `docs/engineering/technical-debt.md`.
- Does not have confirmed Grafana dashboard rendering or confirmed
  Slack alert delivery — both are configured, neither is verified yet.
- Does not run network policies, image signing, or SBOM generation —
  planned, not built.

Scoping and gaps are documented on purpose, not discovered by a
reviewer later — see `docs/engineering/technical-debt.md` for the full,
honest list.

## Structure

- `terraform/` — infrastructure as code
- `kubernetes/` — raw K8s manifests (where Helm isn't the right fit)
- `helm/` — Helm charts (golden-path service chart, platform charts)
- `gitops/` — Argo CD Application manifests, desired-state repo content
- `platform/` — Backstage config, golden-path templates
- `observability/` — Prometheus, Grafana, OpenTelemetry config
- `security/` — policy-as-code, admission control
- `policies/` — Kyverno policies
- `tests/` — pipeline and infra tests
- `docs/` — architecture, ADRs, security, reliability, operations,
  runbooks, troubleshooting

## Documentation

Full engineering documentation, evidence, and operational runbooks:
[docs/index.md](docs/index.md)
