# ADR-006: Backstage Build via Cloud Build, Not Cloud Shell

## Status
Accepted

## Context
Backstage's official documentation states a minimum of 20GB disk and
6GB memory to build the app with a full `yarn install`. Cloud Shell's
persistent home directory is capped at 5GB. Building locally risks
filling the disk mid-install.

## Decision
Scaffold Backstage's source with `--skip-install` in Cloud Shell
(lightweight, template files only). Build the actual Docker image via
Google Cloud Build, which runs `yarn install` and the production build
on dedicated infrastructure, then pushes directly to Artifact Registry.

## Alternatives Rejected
- Local yarn install in Cloud Shell: rejected - real risk of filling
  the 5GB persistent disk and corrupting the shell environment.
- Provisioning a larger Compute Engine VM just to build: rejected -
  Cloud Build already solves this with no persistent VM to manage or
  pay for when idle.

## Consequences
Cloud Build's service account needs write access to the forge-images
Artifact Registry repo - granted narrowly (this repo only), following
the same least-privilege pattern as ADR-004's CI pusher account.

## Cost Impact
Cloud Build has a free tier (120 build-minutes/day); a single Backstage
build is well within that. Effectively $0 for this project's usage.

## Revisit Conditions
Once GitLab CI/CD exists (Phase 6), reconsider whether Backstage's own
image should build there instead, for pipeline consistency. Not urgent -
Backstage rebuilds infrequently compared to golden-path services.
