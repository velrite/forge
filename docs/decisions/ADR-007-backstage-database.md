# ADR-007: Backstage Database - SQLite In-Memory for Demo Phase

## Status
Accepted

## Context
create-app generated a production config defaulting to Postgres via
environment variables we haven't provisioned (no Cloud SQL instance
exists). The dev config already uses better-sqlite3 in-memory.

## Decision
Use better-sqlite3 in-memory for both dev and production config at this
phase. Catalog data does not persist across pod restarts.

## Alternatives Rejected
- Cloud SQL Postgres now: real production choice, but adds a billable
  always-on resource (Cloud SQL has no meaningful free tier) before
  this platform has any real users or data worth persisting.

## Consequences
Every time the Backstage pod restarts, the catalog resets to whatever
`catalog.locations` defines (currently the generated example data).
This is explicitly a demo-phase limitation, not an oversight.

## Revisit Conditions
Before Forge has any real developer-facing usage, or before Phase 5's
golden-path template registrations need to survive a restart.
