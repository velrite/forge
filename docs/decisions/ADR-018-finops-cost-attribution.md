# ADR-018: FinOps Cost Attribution Methodology

## Context
Phase 12 requires cost attribution by service/namespace/team. This project
has no BigQuery billing export configured, so no ground-truth priced dollar
data exists to attribute.

## Decision
Rather than fabricate dollar estimates from public GCP price lists (which
would not reflect actual discounts, commitments, or the project's real
billing account), attribution is done using real, measured signals:
- Live resource usage per namespace (kubectl top)
- Requested CPU/memory per namespace (from live pod specs — the actual
  reservation signal Autopilot bills against)
- Namespace-level labels for team/service ownership, where present

## Consequence
This report has no dollar figures. If real cost accounting is required
later, enable BigQuery billing export first
(https://cloud.google.com/billing/docs/how-to/export-data-bigquery) and
re-run attribution against that export instead of resource requests.
