# Technical Debt

Each item: current state, actual risk, why it exists, recommended fix.
Nothing here is hidden or minimized.

## Golden-Path Publish Step Is Incomplete

**Current state:** Backstage's scaffolder template can generate a new
service's source tree locally but cannot publish it as a new Git
repository.
**Risk:** The core "developer self-service" claim of an Internal
Developer Platform is not actually true end-to-end yet — a developer
still needs manual steps to get a new service into a real repository.
**Why it exists:** Deferred (ADR-010) specifically because it required
deciding which Git host to publish to and wiring a real credential,
and the project's own CI/CD work took priority.
**Recommended fix:** Add a `publish:github` (or `publish:gitlab`) step
to the template, backed by the same kind of scoped, non-key-file
credential pattern used everywhere else in this project.

## Grafana Dashboard Rendering Unconfirmed

**Current state:** A dashboard ConfigMap is applied and labeled for
Grafana's sidecar auto-discovery. Whether Grafana actually renders it
with live data has never been checked.
**Risk:** Low — this is a visualization convenience layer, not a data
source. The underlying PromQL is independently confirmed working via
direct query.
**Why it exists:** Deprioritized in favor of confirming the underlying
metrics pipeline first.
**Recommended fix:** Log into Grafana directly, confirm the dashboard
appears and panels render, or fix the sidecar configuration if not.

## Slack Alerting Delivery Unconfirmed

**Current state:** Alertmanager is configured with a Slack webhook
receiver. A test alert was fired via Alertmanager's API; delivery to
the actual Slack channel was never confirmed by the operator.
**Risk:** Medium — if this platform were ever relied on for real
incident response, an unconfirmed alert path is effectively no alert
path.
**Why it exists:** An earlier attempt to wire Gmail SMTP was abandoned
after repeated terminal-capture failures with the required App
Password; the pivot to Slack was made but the final confirmation step
was never completed.
**Recommended fix:** Fire one more test alert and visually confirm it
lands in the configured channel before relying on this for anything.

## No Application-Level Observability for Backstage

**Current state:** All SLOs and dashboards reflect Kubernetes-level
signals only (pod/replica health), not application-level request
latency or error rate.
**Risk:** Low for this project's current scope; would become a real
gap if this platform hosted services with actual user traffic.
**Why it exists:** Backstage does not ship a Prometheus metrics plugin
by default, and adding one was judged out of scope for a
platform-engineering project (Backstage is a third-party tool being
operated, not application code being maintained).
**Recommended fix:** Documented as a clear scope boundary (ADR-015)
rather than worked around.

## Node-Failure Resilience Never Tested

**Current state:** Pod-failure and dependency-failure resilience were
tested and confirmed. A full node-failure/drain test was deliberately
not performed.
**Risk:** Real but judged acceptable for this project's scale — a
2-node cluster already running close to its memory ceiling risks a
genuine, extended outage if a drain fails to reschedule everything onto
the single remaining node, for the sake of a demo screenshot.
**Why it exists:** A deliberate risk/reward call, not an oversight.
**Recommended fix:** Test in a lower-stakes window, ideally with a
temporarily larger node pool, if this evidence is ever specifically
required.

## A Previous, Incorrect Cost Report Remains in the Repository

**Current state:** An early FinOps attempt matched the wrong Compute
Engine SKUs (Spot/Sole-Tenancy/Commitment pricing, none applicable to
an on-demand Autopilot cluster) and was committed before the error was
caught.
**Risk:** Low, but a reviewer who finds it without the superseded
marker could reasonably question the project's numeric rigor.
**Why it exists:** Kept for the record rather than deleted, per this
project's general preference for leaving real mistakes visible rather
than erasing them — but it should be unambiguous which report is
authoritative.
**Recommended fix:** The file has been marked superseded at the top;
confirm that marker is present and points to the correct OpenCost-based
report.
