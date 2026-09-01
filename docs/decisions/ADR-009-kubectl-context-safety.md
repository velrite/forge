# ADR-009: Explicit kubectl Context Verification Before Every Cluster Operation

## Status
Accepted

## Context
During Phase 4 deployment, kubectl's active context was still pointed at
an unrelated cluster (atlas-dev, project velrite-tf-test) from earlier
work in this Cloud Shell environment. `kubectl apply` was run without
verifying context first, creating a namespace/Deployment/Service on the
wrong cluster in the wrong project.

Root cause: gcloud project context (`gcloud config get-value project`)
and kubectl cluster context (`kubectl config current-context`) are two
separate pieces of state, set independently. Verifying one does not
verify the other. Cloud Shell session resets compound this - a session
can retain stale kubectl credentials from unrelated prior work.

## Decision
Every kubectl, helm, or other cluster-mutating command in this project
is preceded by an explicit context check:
`kubectl config current-context | grep -q "forge-cluster"`
No cluster-mutating command runs without this check passing first.

## Impact / Remediation
The accidental namespace was deleted from atlas-dev after verifying
its contents (one Deployment, one Service, nothing pre-existing was
overwritten - kubectl apply only creates/updates named resources, it
cannot affect unrelated existing objects). Confirmed clean via
`kubectl get namespace forge-platform` returning NotFound on atlas-dev
post-cleanup.

## Consequences
Every future phase's kubectl-based instructions include this guard
explicitly, not assumed. This becomes especially important from Phase
7 onward once Argo CD is also capable of targeting clusters.

## Revisit Conditions
If Forge ever manages more than one real cluster intentionally (e.g.
a staging/prod split), this check needs to become context-aware rather
than a single hardcoded name.
