# ADR-016: Kyverno for Policy-as-Code

## Status
Accepted

## Context
GKE Autopilot already enforces several standard policy-as-code
examples itself (blocks privileged containers, auto-injects resource
requests/limits) - writing those same policies would be redundant.

## Decision
Kyverno installed (plain YAML policies, no separate policy language,
consistent with this build's preference for reducing surface area for
new mistakes). Three policies, chosen for non-redundant, project-specific
value:
- disallow-latest-tag (Enforce/preventive) - direct lesson from ADR-011's
  tag immutability incident, now codified as a blocking rule
- require-app-label (Audit/detective) - ownership/observability tracing,
  not enforced by Autopilot
- restrict-image-registries (Audit/detective) - supply-chain control,
  scoped to forge-platform namespace

## Consequences
Preventive vs detective distinction is explicit per-policy via
validationFailureAction (Enforce vs Audit) - not applied uniformly,
matching the project's stated requirement to distinguish the two.

## Revisit Conditions
Move require-app-label and restrict-image-registries to Enforce once
all existing workloads are confirmed compliant (currently Audit to
avoid breaking already-running components during rollout).
