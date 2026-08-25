# Forge Initial Threat Model (Phase 1)

Scope: GCP project, Terraform state bucket, IAM boundary. Intentionally
incomplete — extended each phase as new components (GKE, Backstage,
GitLab, Argo CD) are added.

## Assets
- Terraform state (describes, and could enable reconstruction of, all infra)
- GCP project IAM bindings
- (Future) container images, secrets, cluster credentials

## Threats
- Compromised local/CI credentials granting project-level access
- Terraform state bucket deleted or corrupted without recovery path
- Overly broad IAM roles granted out of convenience

## Attack Surfaces (current)
- Whoever holds gcloud auth credentials for this project
- The Terraform state bucket's IAM bindings

## Trust Boundaries
- Cloud Shell session (user-authenticated) <-> GCP project APIs
- (Future, Phase 6) GitLab CI runner <-> GCP project APIs — Workload
  Identity Federation planned, not key files

## Controls Implemented So Far
- Dedicated project (blast-radius isolation from other projects)
- Object versioning on state bucket (recovery from accidental deletion)
- Uniform bucket-level access (no legacy ACL sprawl)
- No service account key files created

## Residual Risk
- Single Cloud Shell user currently holds effective project-owner
  access — acceptable for solo-builder phase, must be revisited before
  any second contributor or CI system gets access (Phase 6).
