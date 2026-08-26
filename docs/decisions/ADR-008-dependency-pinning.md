# ADR-008: Pin Scaffolding Tools to Specific Versions, Never @latest

## Status
Accepted

## Context
Scaffolding Backstage with `create-app@latest` pulled in a transitive
dependency (nunjitsu@0.6.1) published 2 days prior, still inside npm's
automated post-publish malware-scan quarantine window. The package
itself was verified legitimate (real maintainer, GitHub OIDC-published,
matches a known Backstage core contributor) - the problem was floating
on the newest possible dependency tree, not a security compromise.

## Decision
Pin @backstage/create-app to a specific stable release (0.9.1 -
verified via direct registry query, not search-engine cache, to be a
true stable tag published 8+ days prior, not a -next prerelease or
nightly build). This same principle applies going forward: Forge's own
golden-path templates (Phase 5) must pin dependency versions
explicitly, never float on @latest, especially for anything that will
be used to scaffold other people's services.

## Alternatives Rejected
- Waiting out the quarantine window on nunjitsu@0.6.1: would have
  worked eventually, but leaves the underlying problem (floating on
  @latest) to recur on the next scaffold or rebuild.
- Disabling/bypassing the quarantine check: rejected outright - this
  is a real supply-chain security control, not a false-positive to be
  silenced.

## Consequences
Every future rescaffold or dependency bump for Forge's platform tooling
must explicitly choose a version, verified against the live registry
(npm view, not search results, which can be stale or cached) - not
default to @latest.

## Revisit Conditions
When bumping Backstage's version deliberately (a planned upgrade, not
an accidental side effect of a fresh scaffold).
