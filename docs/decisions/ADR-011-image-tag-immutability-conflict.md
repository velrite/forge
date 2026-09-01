# ADR-011: Resolve Conflict Between Tag Immutability (ADR-004) and Floating :latest

## Status
Accepted

## Context
ADR-004 enabled immutable tags on the Artifact Registry repo - a real
supply-chain control preventing a tag from being silently repointed
after the fact. Phase 4's Cloud Build config pushed to a floating
:latest tag as an accepted, documented simplification. The first push
succeeded (tag didn't exist yet); the second push failed with
"manifest invalid: cannot update tag latest. The repository has
enabled tag immutability" - the two decisions were always going to
collide on the first rebuild.

## Decision
Every build now tags the image uniquely (a timestamp, passed as a
Cloud Build substitution at submit time) instead of :latest. The
Kubernetes Deployment is updated to reference the specific new tag via
`kubectl set image`, not a rollout restart against a static tag.

## Alternatives Rejected
- Disabling tag immutability: rejected - it's a real security control,
  not the actual problem.
- Deleting and recreating the :latest tag each build: rejected -
  defeats the purpose of immutability entirely, just via a workaround.

## Consequences
Every deployment change is now traceable to an exact, never-reused
image tag - a real improvement, not just a workaround. This is the
correct long-term pattern and matches what Phase 6's GitLab CI will do
with commit-SHA tagging anyway; this phase just gets there first,
manually.

## Revisit Conditions
None - this is the permanent pattern going forward, including for
golden-path-generated services from Phase 6 onward.
