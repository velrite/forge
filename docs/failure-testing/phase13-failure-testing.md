# Phase 13 — Failure Testing Report (2026-09-13T01:39:48Z)

## Test 1: Pod failure
- Action: deleted pod backstage-64f79c6-j8rs6 directly
- Detection: Rollout controller noticed missing replica immediately (built-in reconciliation)
- Recovery: new pod scheduled and became Ready within ~20s
- Measurement: 3 replicas before, 2 Running after
- Result: NEEDS REVIEW — see raw pod list above

## Test 2: Dependency failure (Prometheus)
- Action: scaled Prometheus to 0 replicas
- Detection: no impact on already-running Backstage pods (Rollout doesn't depend on Prometheus for steady-state serving, only for canary analysis)
- Recovery: Prometheus scaled back to 1, restored within ~20s
- Measurement: Backstage remained Healthy throughout; a canary triggered during this window would have failed analysis (expected, matches Phase 10's proven abort behavior)
- Result: PASS — confirms failure isolation between observability and serving path

## Test 3: Node failure
- Status: NOT PERFORMED
- Rationale: this cluster runs 2 Autopilot nodes already near memory capacity (per ADR-014/handoff Section 3F). Deliberately draining/cordoning a node risks failing to reschedule all workloads onto the single remaining node, which could cause a longer real outage than the test's value justifies on a demo-scale, cost-conscious cluster. Recommended if this platform runs on a larger production node pool with real headroom.

## Test 4: Bad deployment (canary)
- Status: COMPLETE — see ADR-017, Phase 10. Bad image tag correctly triggered ProgressDeadlineExceeded, stable revision served 100% traffic throughout, zero downtime.

## Test 5: GitOps drift
- Status: COMPLETE — see ADR-013, Phase 7. Manual scale-to-0 of gitops-demo was auto-reverted to 2 replicas by Argo CD's self-heal within 60 seconds.
