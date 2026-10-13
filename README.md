# Forge: Internal Developer Platform on GCP

Forge is a self-service developer platform on Google Kubernetes Engine. I built it to answer one question with evidence instead of claims: can a platform actually catch its own bad deployments and enforce its own rules, or does it just say it does.

**Status:** Core infrastructure, CI/CD, GitOps, progressive delivery, policy enforcement, observability, and FinOps attribution are built and behaviorally verified — see the tables below for exactly what "verified" means for each one. Developer self-service is not complete: the golden-path template can scaffold a service but cannot publish it to a real repository yet ([ADR-010](docs/decisions/ADR-010-golden-path-publish-deferred.md)). Grafana dashboard rendering and Slack alert delivery are configured but unconfirmed. Node-failure resilience was deliberately not tested. Nothing here has served real user traffic.

This is not an AI/ML project. There is no model serving or inference workload anywhere in it.

---

## Engineering Problem

A developer wants to ship a change. Getting it into production safely means testing it, scanning it, building it, storing it somewhere immutable, rolling it out gradually, checking its health while doing so, and automatically pulling it back if something's wrong — without a human babysitting each step, and without the credentials that do all this sitting around as a standing attack surface.

## Architecture

```
Developer
  |  git push
  v
GitHub (canonical)  --mirror-->  GitLab (CI execution)
                                   |  OIDC token (WIF, no static key)
                                   v
                                 Cloud Build
                                   |  unique tag, immutable
                                   v
                                 Artifact Registry
                                   |
                                   v
Argo CD  <--- watches --- GitHub (desired state)
  |  reconciles
  v
Argo Rollouts  --- queries ---> Prometheus (readiness signal)
  |  20% -> analysis -> 50% -> analysis -> 100%
  v
GKE Autopilot (forge-cluster)
  |  every object creation checked
  v
Kyverno (admission)
```

| Layer | What is used |
|---|---|
| Infrastructure | Terraform (GCS state, versioned), GKE Autopilot (regional, private nodes), Artifact Registry (immutable tags) |
| Delivery | GitLab CI/CD, Workload Identity Federation, Cloud Build, Argo CD |
| Progressive delivery | Argo Rollouts, canary 20/50/100, Prometheus-backed analysis |
| Observability | kube-prometheus-stack, OpenTelemetry Collector, OpenCost |
| Security | Kyverno admission policies, least-privilege IAM, no static GCP keys |

---

## The Failure That Took Longest to Actually Fix

I found this one by reading raw HTTP responses, not by trusting the error GCP gave me.

**Symptom.** `gcloud builds submit`, run as the CI service account under Workload Identity Federation, failed with `The user is forbidden from accessing the bucket`. Granting `roles/storage.objectAdmin`, then `roles/storage.objectViewer`, on the target bucket both failed identically.

**What looked fine.** The IAM grants looked progressively more permissive and more correct each time. They weren't touching the actual problem.

**Root cause.** A raw `--log-http` diagnostic on the failing request showed the real error underneath the wrapper text: `does not have storage.buckets.list access`. That permission does not exist at bucket scope — it is project-level only, so no bucket-scoped grant, however broad, could ever satisfy it. Separately, Cloud Build's auto-managed `{project}_cloudbuild` bucket uses legacy ACLs that don't reliably honor IAM for WIF/external-account identities at all, and `gcloud builds submit`'s automatic local-directory upload has its own, independent permission check under WIF that fails even with correct IAM.

**What I did.** Granted `roles/storage.admin` at the project level — the minimal predefined role that actually carries `storage.buckets.list`. Created a dedicated, uniform-IAM bucket instead of relying on the auto-managed one. Bypassed the automatic upload path entirely: package the source with `tar`, upload with `gcloud storage cp`, then point `builds submit` at the already-uploaded object. Confirmed the fix locally with `--impersonate-service-account` before trusting a full pipeline run — this became the standard approach for every IAM fix after this one.

Full writeup: [docs/engineering/debugging-history.md](docs/engineering/debugging-history.md)

---

## What Is Proven

| Capability | Evidence | What it actually shows |
|---|---|---|
| GKE Autopilot cluster real, private, regional | [01](docs/evidence/01-cluster-nodes.png) | `gcloud` describe returns `True True RUNNING` |
| Backstage runs as a canary-capable Rollout, not a plain Deployment | [02](docs/evidence/02-backstage-rollout-healthy.png) | `kubectl argo rollouts get rollout` shows `Status: Healthy`, `Step: 6/6` |
| CI authenticates with zero stored GCP credentials | [07](docs/evidence/07-wif-pool-provide.png) | `attributeCondition` scoped to `velrite-group`, no key/secret field in the output |
| CI identity is least-privilege | [08](docs/evidence/08-iam-least-privilege.png) | `gcloud projects get-iam-policy` shows 5 scoped roles, no Owner/Editor |
| Infrastructure has zero drift | [09](docs/evidence/09-terraform-clean-plan.png) | `terraform plan` returns "No changes" against the real running cluster |
| GitOps drift correction is real, not configured | [11](docs/evidence/11-gitops-self-heal-sequence.png) | `gitops-demo` manually scaled to 0; Argo CD reverted it to 2, confirmed `Synced`/`Healthy` within a 60 s check |
| Canary rollout actually stages traffic | [12](docs/evidence/12-canary-progression.png) | `SetWeight` observed at 20 and 50 before reaching 100 |
| Bad deploy is caught and blocked automatically | [13](docs/evidence/13-canary-auto-rollback.png) | Deliberately invalid tag deployed; status reached `Degraded`/aborted within a 90 s window; stable pods stayed `Running` throughout |
| Admission policy actually blocks, not just logs | [15](docs/evidence/15-kyverno-admission-denied.png) | `kubectl apply` of an `nginx:latest` pod was denied by the admission webhook, pod never created |
| Metrics are real, not a dashboard pointed at nothing | [16](docs/evidence/16-prometheus-targets-up.png) | Prometheus active-target list shows real scrape health |
| Cost attribution is computed, not invented | [19](docs/evidence/19-opencost-cost-breakdown.png) | Real per-namespace OpenCost figures, one pull, ~87.8 h window (see FinOps) |
| Pod failure self-heals | [20](docs/evidence/20-pod-failure-selfheal.png) | Pod deleted directly; replacement scheduled within ~20 s |

---

## Failure Catalogue

Includes my own invalid attempts, not just the clean fixes.

**AnalysisTemplate, two distinct root causes before it worked.** First query targeted `kube_pod_labels{label_rollouts_pod_template_hash="..."}`, which returned no data for this workload — switched to a deployment-level readiness ratio, which returned real data but then failed with a type error (`invalid operation: >= (mismatched types []float64 and int)`), because Argo Rollouts' Prometheus provider always returns an array, even for one value. Fixed by indexing it explicitly (`result[0] >= 1`).

**My own typo stalled a rollback test for 17+ minutes.** I ran `kubectl argo rollouts undo rollout backstage` — an extra word that made the CLI look for a rollout literally named `"rollout"`. It errored and did nothing, and a failed canary pod sat in `ImagePullBackOff` the whole time I thought it was recovering. Fixed by redeploying the known-good tag directly.

**I deleted a pod I incorrectly called orphaned.** It had a real controller, `ReplicaSet backstage-6b74bb5dd9` with `DESIRED: 1`. Deleting it just triggered instant recreation. Caught by checking the actual output instead of trusting a "done" claim; fixed by scaling the real ReplicaSet to 0 directly.

**First FinOps attempt matched the wrong SKUs.** Filtered Google's billing catalog for Autopilot/Compute keywords and matched Spot, Sole-Tenancy, and Commitment pricing — none applicable to an on-demand Autopilot cluster. Caught before anyone relied on the numbers, pivoted to OpenCost for real computed figures. The wrong report is still in the repo, marked superseded, not deleted.

**`kubectl apply` failed on two separate CRDs for the same underlying reason.** Both Argo CD's `ApplicationSet` CRD and Argo Rollouts' `Rollout` CRD exceeded `kubectl`'s client-side apply annotation limit (`262144 bytes`) — not a config error, a hard platform ceiling. Fixed with `--server-side --force-conflicts` both times, once I recognized the pattern.

**Cluster memory pressure caused three separate "new" failures that were the same cause.** OTel Collector, Argo Rollouts controller, and OpenCost each independently hit `Insufficient memory` on first install. `kubectl top nodes` showed low utilization the whole time, because Kubernetes schedules against requested memory, not actual usage.

---

## Security

Implemented: Workload Identity Federation (no static GCP keys anywhere in CI), least-privilege IAM for the CI identity (verified role list, not Owner/Editor), immutable image tags (a real registry rejection enforces this, not just policy), Kyverno admission control with one Enforce policy (`disallow-latest-tag`) and two Audit policies (`require-app-label`, `restrict-image-registries` — deliberately not blocking yet, to avoid breaking already-running workloads during rollout).

**Gaps, stated plainly:** Artifact Registry vulnerability scanning is enabled but no scan result has ever been pulled and reviewed. No network policies restrict pod-to-pod traffic inside the cluster. No image signing or SBOM generation. Backstage runs guest-only auth with an in-memory SQLite catalog that does not survive a pod restart ([ADR-007](docs/decisions/ADR-007-backstage-database.md)).

---

## Observability and SLOs

Backstage's `/metrics` endpoint returns `text/html`, not Prometheus format — confirmed with `curl -i`, not assumed. SLOs here are therefore Kubernetes-level signals via kube-state-metrics, not application request/latency data ([ADR-015](docs/decisions/ADR-015-slo-source-pivot.md)).

| SLO | Target | Why |
|---|---|---|
| Availability | 99% over 30 days | Single Rollout, 2 replicas, no multi-zone redundancy — a 99.9% target would misrepresent the actual architecture |
| Restart stability | 0 restarts/hour | A pod that crash-loops quickly can still look "available" in a coarse availability sample |

Traces are received by the OpenTelemetry Collector and routed to a `debug` exporter — they exist transiently in pod logs, not in any queryable trace backend. Stated here, not left implied.

Full detail: [docs/observability/observability.md](docs/observability/observability.md), [docs/reliability/slo.md](docs/reliability/slo.md)

---

## FinOps

Real OpenCost pull, one sample window (~87.8 hours tracked for most namespaces), total **$57.15** month-to-date:

| Namespace | CPU Cost | RAM Cost | Total |
|---|---|---|---|
| kube-system | $15.9614 | $9.3198 | $25.2812 |
| argocd | $9.6677 | $5.1833 | $14.8510 |
| observability | $9.5528 | $4.8093 | $14.3621 |
| forge-platform | $1.0583 | $0.2844 | $1.3427 |
| forge-demo | $0.5540 | $0.0928 | $0.6468 |
| kyverno | $0.1857 | $0.0373 | $0.2230 |
| argo-rollouts | $0.0371 | $0.0062 | $0.0434 |

A single pull, not a continuous monitor — read it as a snapshot. A GCP budget guardrail is separately configured: $10/month, alerting at 50/90/100/150% of spend ([22](docs/evidence/22-gcp-budget-alert.png)).

A first attempt at this used the wrong GCP SKUs entirely — see Failure Catalogue.

---

## Production-Shaped, Not Production-Claimed

Forge uses production practices: Workload Identity Federation, GitOps with proven self-heal, progressive delivery with proven automated rollback, admission-time policy enforcement, SLOs, and real cost attribution. It has not served real user traffic and was not load-tested.

Out of scope by design: multi-region, node-level failover (deliberately not tested — a 2-node cluster already near its memory ceiling risks a genuine extended outage from a failed test), and any claim of production users.

---

## Known Limitations

- Developer self-service is not end-to-end: the golden-path template scaffolds a service but cannot publish it to a real repository.
- Grafana dashboard rendering was never confirmed after the ConfigMap was applied.
- Slack alert delivery was configured and a test alert was fired; delivery to the channel was never confirmed.
- Vulnerability scanning is enabled; no scan result has been reviewed.
- Backstage's catalog is in-memory SQLite — state does not survive a pod restart.
- No application-level SLOs for Backstage; all reliability signals are Kubernetes-level.
- Node-failure resilience has not been tested.
- An earlier, incorrect FinOps report remains in the repository, marked superseded rather than deleted.

---

## Running It

Bringing the cluster up, verifying it, and tearing it down are documented with exact commands and expected output in [docs/operations/getting-started.md](docs/operations/getting-started.md). The cluster and its Cloud NAT are the only components that cost money while running; everything else costs nothing whether the cluster is up or down.

## Documentation

- [Documentation index](docs/index.md)
- [Architecture](docs/architecture/system-overview.md)
- [Getting started — start, verify, test, destroy](docs/operations/getting-started.md)
- [Security controls](docs/security/security-controls.md)
- [Observability](docs/observability/observability.md)
- [Reliability / SLOs](docs/reliability/slo.md)
- [Debugging history](docs/engineering/debugging-history.md)
- [Lessons learned](docs/engineering/lessons-learned.md)
- [Technical debt](docs/engineering/technical-debt.md)
- [Engineering maturity assessment](docs/engineering/engineering-maturity.md)
- [Evidence index](docs/evidence/README.md)
- [Plain-language explanation](docs/for-everyone.md)
- Architecture Decision Records: [docs/decisions/](docs/decisions/) (ADR-001 through ADR-017)

## Evidence

<details>
<summary><strong>Show all captured screenshots</strong></summary>

**01-cluster-nodes**


![cluster nodes](docs/evidence/01-cluster-nodes.png)



**02-backstage-rollout-healthy**


![backstage rollout healthy](docs/evidence/02-backstage-rollout-healthy.png)



**03-backstage-pods-service**


![backstage pods and service](docs/evidence/03-backstage-pods-service.png)



**04-gitlab-pipeline-success**


![gitlab pipeline success](docs/evidence/04-gitlab-pipeline-success.png)



**05-cloudbill-history**


![cloud build history](docs/evidence/05-cloudbill-history.png)



**06-artifacts-registry-images**


![artifact registry images](docs/evidence/06-artifacts-registry-images.png)



**07-wif-pool-provide**


![wif pool and provider](docs/evidence/07-wif-pool-provide.png)



**08-iam-least-privilege**


![iam least privilege](docs/evidence/08-iam-least-privilege.png)



**09-terraform-clean-plan**


![terraform clean plan](docs/evidence/09-terraform-clean-plan.png)



**10-argocd-app-health**


![argocd app health](docs/evidence/10-argocd-app-health.png)



**11-gitops-self-heal-sequence**


![gitops self heal sequence](docs/evidence/11-gitops-self-heal-sequence.png)



**12-canary-progression**


![canary progression](docs/evidence/12-canary-progression.png)



**13-canary-auto-rollback**


![canary automatic rollback](docs/evidence/13-canary-auto-rollback.png)



**14-kyverno-policy-list**


![kyverno policy list](docs/evidence/14-kyverno-policy-list.png)



**15-kyverno-admission-denied**


![kyverno admission denied](docs/evidence/15-kyverno-admission-denied.png)



**16-prometheus-targets-up**


![prometheus targets up](docs/evidence/16-prometheus-targets-up.png)



**17-slo-promql-live-result**


![slo promql live result](docs/evidence/17-slo-promql-live-result.png)



**18-grafana-slo-dashboard**


![grafana slo dashboard](docs/evidence/18-grafana-slo-dashboard.png)



**19-opencost-cost-breakdown**


![opencost cost breakdown](docs/evidence/19-opencost-cost-breakdown.png)



**20-pod-failure-selfheal**


![pod failure self heal](docs/evidence/20-pod-failure-selfheal.png)



**21-adr-commit-history**


![adr commit history](docs/evidence/21-adr-commit-history.png)



**22-gcp-budget-alert**


![gcp budget alert](docs/evidence/22-gcp-budget-alert.png)



</details>
