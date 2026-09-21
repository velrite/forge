# Debugging History

Real incidents encountered while building this platform, in the format
used for production postmortems. All occurred during development, not
against any production traffic — stated explicitly, not implied
otherwise.

---

## Incident: Cloud Build Rejects Source Upload Under Workload Identity Federation

**Symptom:** `gcloud builds submit` under a WIF-impersonated identity
failed repeatedly with `The user is forbidden from accessing the bucket`,
even after granting broad-looking storage roles.

**Investigation:** Granting `roles/storage.objectAdmin`, then
`roles/storage.objectViewer` on the target bucket, both failed
identically. A raw `--log-http` diagnostic on the actual failing request
revealed the real error underneath the wrapper message: `does not have
storage.buckets.list access`.

**Root cause:** `storage.buckets.list` is a **project-level-only**
permission — it cannot be granted via any bucket-scoped IAM policy,
which is exactly why every bucket-scoped grant attempted before this
point had no effect. Separately, `gcloud builds submit`'s automatic
local-directory upload path has an independent, confirmed permission
check under WIF identities that does not reliably succeed even with
correct IAM.

**Resolution:** Granted `roles/storage.admin` at the **project** level
(the minimal predefined role carrying `storage.buckets.list`). Bypassed
the automatic local-upload path entirely — source is packaged and
uploaded manually (`tar` + `gcloud storage cp`), then `gcloud builds
submit` is pointed at the already-uploaded GCS object rather than a
local directory.

**Verification:** A local reproduction using `--impersonate-service-account`
was used to confirm the fix before trusting a full GitLab pipeline
run — this local-repro-first pattern was adopted for every subsequent
IAM fix in this build.

**Preventive control:** The full required IAM chain is documented in
`docs/decisions/ADR-012` rather than left implicit in Terraform alone.

---

## Incident: Artifact Registry Rejects a Second Push to the Same Tag

**Symptom:** A second Cloud Build run pushing to `backstage:latest`
failed with `manifest invalid: cannot update tag latest. The repository
has enabled tag immutability`.

**Root cause:** Tag immutability (a deliberate security control set up
earlier in the project, ADR-004) and a floating `:latest` tag in the
build pipeline were always going to collide on the first rebuild — the
first push only succeeded because the tag did not exist yet.

**Resolution:** Every build now generates a unique tag (timestamp, later
commit SHA) via a Cloud Build substitution. The Kubernetes manifest
referencing the image was updated to match, and deployment moved from a
floating-tag `kubectl rollout restart` to an explicit `kubectl set
image` / `argo rollouts set image` referencing the exact new tag.

**Preventive control:** Documented as a permanent pattern (ADR-011) —
no future golden-path service template should use a floating tag.

---

## Incident: Prometheus Never Scrapes Backstage Despite Correct ServiceMonitor

**Symptom:** A `ServiceMonitor` matching Backstage's Service by label
was applied, but Prometheus's target list showed the target as
`dropped`, not `active`.

**Investigation:** Inspected Prometheus's actual generated scrape config
directly (`/api/v1/status/config`) rather than re-guessing at the
`ServiceMonitor` spec. The real relabel rule required
`__meta_kubernetes_service_label_app` — a **Service-level** metadata
label.

**Root cause:** The Service manifest set `spec.selector.app: backstage`
(which pods to route to) but never set `metadata.labels.app: backstage`
on the Service object itself. These are two different things, and only
the second one satisfies the relabel rule.

**Resolution:** Added `metadata.labels.app: backstage` to the Service.
Target moved from `dropped` to `active` within one scrape interval.

**Preventive control:** Documented explicitly in
`docs/architecture/system-overview.md` and this history, since it is a
non-obvious Kubernetes/Prometheus interaction likely to recur on any
future service onboarded to this platform.

---

## Incident: Argo Rollouts / Argo CD CRDs Fail to Apply via Plain `kubectl apply`

**Symptom:** `CustomResourceDefinition.apiextensions.k8s.io "rollouts.argoproj.io"
is invalid: metadata.annotations: Too long: may not be more than 262144
bytes`.

**Root cause:** `kubectl apply`'s client-side apply mechanism stores the
entire previous configuration as an annotation on the object for
three-way-merge diffing. Some CRDs (Argo CD's `ApplicationSet`, Argo
Rollouts' `Rollout` and related CRDs) are large enough to exceed
Kubernetes' hard annotation-size limit under this mechanism.

**Resolution:** Installed via `kubectl apply --server-side
--force-conflicts`, which does not use the client-side annotation
mechanism.

**Preventive control:** Documented as the required install method for
any future large CRD in this project, rather than something to
rediscover.

---

## Incident: Argo Rollouts AnalysisTemplate Returns No Data, Then a Type Error

**Symptom, first form:** `metric result is nil or empty` — the
canary analysis step failed with no usable data.

**Root cause:** The initial query targeted
`kube_pod_labels{label_rollouts_pod_template_hash="..."}`, a label that
was not reliably populated by kube-state-metrics for this workload.

**Fix attempt 1:** Switched to a deployment-level readiness ratio query.
This returned real data.

**Symptom, second form:** `could not evaluate successCondition "result
>= 1": invalid operation: >= (mismatched types []float64 and int)`.

**Root cause:** Argo Rollouts' Prometheus provider always returns
results as an array, even for a single aggregate value — comparing an
array to a bare integer is a type error, not a data problem.

**Fix:** Changed the `successCondition` to index the array explicitly
(`result[0] >= 1`).

**Verification:** Confirmed via a full canary run reaching `Phase:
Successful` with a real measured value, then confirmed again via a
deliberate bad-image test correctly triggering automatic abort.

---

## Incident: Cluster Memory Pressure Causes Repeated `Pending` Pods

**Symptom:** Multiple unrelated installs (OpenTelemetry Collector, Argo
Rollouts controller, OpenCost) each independently hit `FailedScheduling:
Insufficient memory` on first install.

**Root cause:** A 2-node GKE Autopilot cluster running Backstage, Argo
CD (7 pods), the full Prometheus stack, Kyverno (4 controllers), Argo
Rollouts, and OpenCost simultaneously operates close to its practical
memory ceiling. `kubectl top nodes` consistently showed low percentage
utilization even while pods sat `Pending` — because Kubernetes schedules
against **requested** memory, not **actual** usage, and the sum of
every component's requests had already claimed most of what the small
node pool reports as allocatable.

**Resolution, case by case:** Trimmed non-critical components' resource
requests where reasonable; scaled the non-essential `forge-demo` GitOps
demo workload to zero replicas as a temporary headroom-freeing measure
during installs; in some cases simply waited for Autopilot's own
node-provisioning to catch up.

**Preventive control:** This pattern (check `kubectl describe pod`
`Events:` for the real reason before assuming any new failure is
novel) is now the first diagnostic step for any new `Pending` pod on
this cluster, documented in `docs/operations/getting-started.md`.
