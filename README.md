# Forge — Internal Developer Platform

Forge is a production-grade Internal Developer Platform (IDP) on GCP that
lets developers go from "I need a new service" to a deployed, observed,
secured, cost-attributed production service without hand-building
infrastructure.

## Status
Phase 1 — GCP project bootstrapped, APIs enabled, Terraform state backend
created, initial threat model documented. No GKE cluster yet.

## Structure
- terraform/    — infrastructure as code
- kubernetes/   — raw K8s manifests (where Helm isn't the right fit)
- helm/         — Helm charts (golden path service chart, platform charts)
- gitops/       — Argo CD Application manifests, desired-state repo content
- platform/     — Backstage config, golden path templates
- observability/— Prometheus, Grafana, OpenTelemetry config
- security/     — policy-as-code, admission control
- policies/     — OPA/Gatekeeper or Kyverno policies
- tests/        — pipeline and infra tests
- docs/         — architecture, ADRs, security, reliability, operations, runbooks, troubleshooting
