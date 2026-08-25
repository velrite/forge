# ADR-001: Platform Foundation and Core Technology Stack

## Status
Accepted

## Context
Forge needs a technology stack capable of demonstrating real
platform-engineering practice: developer self-service, GitOps deployment,
security-by-default, observability, and SLO-driven progressive delivery,
on GCP, without AI/ML/GPU components.

## Decision
- Runtime: GKE (Autopilot vs Standard decided in ADR-003, Phase 2)
- Developer portal: Backstage
- CI/CD: GitLab CI/CD
- GitOps: Argo CD
- IaC: Terraform
- Observability: Prometheus + Grafana + OpenTelemetry

## Alternatives Rejected
- Cloud Run instead of GKE: lacks namespaces, RBAC, NetworkPolicies, PDBs
  — would remove the platform-engineering surface area this project
  exists to demonstrate.
- GitHub Actions instead of GitLab CI/CD: mandated out; also carries a
  larger third-party supply-chain surface via the Actions marketplace.
- Direct `kubectl apply`/`helm upgrade` from CI instead of GitOps: would
  require cluster-mutating credentials to live in CI — unacceptable
  under this project's regulated-infra framing.
- Self-managed Kubernetes instead of GKE: control-plane operations would
  consume build effort without serving the stated learning objective.

## Consequences
Forge itself becomes a system with its own SLOs (Backstage, Argo CD
availability), tracked from Phase 9 onward. GitOps is the only path to
cluster state changes for the rest of the build.

## Revisit Conditions
If GKE Standard shows meaningfully better cost/performance once real
usage data exists (Phase 12, FinOps).
