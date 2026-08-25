# ADR-002: Terraform Remote State in GCS

## Status
Accepted

## Context
Local Terraform state has no durability, no locking, no audit trail —
unacceptable for anything beyond a scratch project.

## Decision
Use a GCS bucket as the Terraform backend, with object versioning
enabled and uniform bucket-level access (no legacy per-object ACLs).

## Alternatives Rejected
- Local state: no recovery path, no team-safety, no audit trail.
- Terraform Cloud: adds a third-party dependency and cost with no
  benefit over the native GCS backend for a single-cloud GCP project.

## Consequences
The state bucket becomes a critical dependency. Losing it without
version history means losing track of real infrastructure — versioning
is the mitigation, not optional hardening.

## Revisit Conditions
If Forge becomes multi-cloud, reconsider a provider-agnostic state
backend (Terraform Cloud/Spacelift) for unified state.
