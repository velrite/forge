# ADR-013: Argo CD for GitOps, Demonstrated Self-Healing Drift Correction

## Status
Accepted

## Context
Per ADR-005, Argo CD manages golden-path-generated application
workloads (not platform infrastructure like Backstage, which stays
kubectl-managed). Phase 5's golden path has no published service yet
(ADR-010), so a standalone demo workload was created specifically to
prove the GitOps mechanism end-to-end ahead of a real service existing.

## Decision
- Argo CD installed via kubectl (standard upstream manifest, per
  ADR-005's bootstrap exception - Argo CD cannot GitOps-manage its own
  installation)
- CLI-only workflow throughout (argocd CLI), no browser UI dependency
- GitHub (private repo) as the source of truth, credentials registered
  via argocd repo add (username + PAT, same least-privilege pattern as
  every other credential in this build)
- sync-policy automated, --self-heal, --auto-prune on the demo app

## Verification
Deliberately scaled the deployment to 0 replicas by hand (kubectl scale,
bypassing Git). Argo CD detected the drift and reverted it to the
Git-declared 2 replicas within 60 seconds, with zero manual
intervention. Confirmed via kubectl (0/0 -> 2/2) and argocd app get
(Sync Status: Synced, Health Status: Healthy).

## Known Gap
The applicationsets.argoproj.io CRD failed to apply (kubectl annotation
size limit on a CRD this large) - the core Application CRD applied
successfully and is all this phase needs. Revisit if ApplicationSets
(fleet-style, multi-app management) becomes necessary - likely fixable
via kubectl apply --server-side or splitting the CRD application.

## Revisit Conditions
Once Phase 5's golden path gets a real publish-to-GitLab step
(ADR-010), point a real Argo CD Application at an actual generated
service instead of (or alongside) this demo workload.
