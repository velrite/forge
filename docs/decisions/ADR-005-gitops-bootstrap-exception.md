# ADR-005: GitOps Bootstrap Exception for Platform Infrastructure

## Status
Accepted

## Context
ADR-001 established GitOps (Argo CD) as the only path to cluster state
changes. Argo CD itself does not exist until Phase 7, creating a
chicken-and-egg problem for anything that must run before it
(Backstage, Argo CD's own installation, later the observability stack).

## Decision
Platform infrastructure - Backstage, Argo CD's own bootstrap, and any
other foundational platform component - is applied via Terraform/kubectl
directly. Starting Phase 7, ONLY golden-path-generated application
workloads (the services developers create) flow through GitOps. This
split is permanent, not a temporary shortcut to be closed later.

## Alternatives Rejected
- Delaying Backstage until after Argo CD exists (Phase 7): rejected -
  would block demonstrating developer self-service for multiple phases
  with no security benefit, since platform infra isn't
  developer-facing the way application workloads are.
- Bootstrapping Argo CD via Argo CD itself ("app of apps" from day
  zero): rejected as unnecessary complexity for this project's scale -
  a legitimate pattern at larger orgs, overkill here.

## Consequences
Two distinct change-management paths now exist in Forge: Terraform for
platform infra, GitOps for application workloads. This must be
documented clearly for anyone operating Forge, so they know which path
governs which layer.

## Revisit Conditions
If Forge platform infrastructure changes become frequent enough that
GitOps's audit trail/drift-correction properties would meaningfully
reduce operational risk for platform components too.
