# ADR-003: GKE Cluster Mode — Autopilot, Regional, Private Nodes

## Status
Accepted

## Context
Phase 0 deferred Autopilot-vs-Standard to this phase. Initial guidance
incorrectly assumed Autopilot could run zonal to save cost — verified
against current GCP documentation: Autopilot clusters are always
regional, with no zonal option. Correcting that here rather than
silently.

## Decision
- Mode: Autopilot (per-pod billing suits Forge's low, spiky demo
  workload; removes node-management burden not relevant to this
  project's learning goals)
- Topology: Regional (the only option for Autopilot; control plane
  replicated across 3 zones in the region — a reliability upside, not
  just a forced cost)
- Nodes: Private (no external IPs), reached via Cloud NAT for egress
- Control plane endpoint: Public (Cloud Shell's ephemeral IP makes
  static authorized-network allowlisting impractical right now) — 
  flagged as residual risk below, not swept under the rug

## Alternatives Rejected
- Standard mode: more operational burden (node pool sizing, upgrades)
  for no benefit at this project's scale.
- Public nodes (no Cloud NAT): saves ~$32/month if left running, but
  gives nodes external IPs — rejected as inconsistent with the
  regulated-infra security posture this project is built around.

## Cost Impact
Cluster management fee: $0 (covered by free-tier credit, one cluster).
Cloud NAT: ~$0.044/hr while running — NOT free-tier covered. Mitigated
by tearing the cluster + NAT down between work sessions (teardown
command provided in Phase 2 execution steps).

## Residual Risk
Control plane endpoint is public. Any credentialed `kubectl` user from
anywhere can attempt to reach it (still requires valid GCP IAM auth to
do anything). Acceptable for solo-builder phase; revisit with master
authorized networks or a bastion/IAP tunnel before this is anything
beyond a personal learning platform.

## Revisit Conditions
If cost of intermittent NAT usage exceeds the value of private nodes
for this project's purposes, revisit public-nodes option.
If this platform ever has a second real user, revisit the public
control plane endpoint immediately.
