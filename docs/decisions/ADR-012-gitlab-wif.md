# ADR-012: GitLab CI Authenticates to GCP via Workload Identity Federation

## Status
Accepted

## Context
GitLab CI needs to push images to Artifact Registry. No service account
key file should exist anywhere, per every prior ADR's stance.

## Decision
Created a Workload Identity Pool trusting GitLab.com's OIDC issuer,
scoped via attribute_condition to the "velrite" namespace only - not
any GitLab.com project anywhere. A dedicated service account
(gitlab-ci-forge) is bound to this pool via workloadIdentityUser, and
scoped to artifactregistry.writer on the forge-images repo only -
matching the same least-privilege pattern as every other CI identity
in this project (ADR-004, ADR-006).

## Consequences
GitLab CI jobs authenticate via a short-lived OIDC token per job,
exchanged for a GCP access token through this federation - no stored
secret in GitLab at all, not even encrypted. This is a stronger
security posture than a stored key or PAT would be.

## Cost Impact
Zero - IAM and identity federation resources are not billed.

## Revisit Conditions
If GitLab CI ever needs access to resources beyond forge-images (a
second repo, GKE deploy permissions for real GitOps in Phase 7),
add scoped bindings for those specifically rather than broadening
this service account's existing role.

## Update: Full Working Chain (resolved after extended debugging)
The complete IAM chain required for gcloud builds submit under WIF
impersonation, beyond the base WIF trust binding:
- roles/cloudbuild.builds.editor (project level)
- roles/serviceusage.serviceUsageConsumer (project level)
- roles/storage.admin (project level - required for storage.buckets.list,
  which gcloud builds submit checks unconditionally regardless of
  --gcs-source-staging-dir/--gcs-log-dir overrides; no bucket-scoped
  role can satisfy this, confirmed via --log-http diagnostic)
- roles/iam.serviceAccountUser on the default Compute Engine service
  account specifically (Cloud Build's default build-runtime identity)
- cloudbuild.yaml logging option must be GCS_ONLY, not
  CLOUD_LOGGING_ONLY, when using --gcs-log-dir explicitly

Verified end-to-end via local impersonation test before trusting a
live pipeline run - STATUS: SUCCESS confirmed locally first, then
confirmed again via a real GitLab pipeline run, first fully green
pipeline achieved.
