Security Controls
Each control below is marked Implemented (behaviorally verified),
Configured (in place, not yet behaviorally tested), or Planned
(discussed, not built). No control is described as more mature than its
actual verification status.
Identity and Access — Implemented
GitLab CI authenticates to GCP with zero stored credentials.
Workload Identity Federation: GitLab issues a short-lived OIDC token per
pipeline run; GCP's Security Token Service exchanges it for access,
scoped by an explicit trust condition:
assertion.namespace_path == "velrite-group"
This is not a wildcard trust — only tokens asserting membership in this
specific GitLab namespace are accepted. No service-account key file
exists anywhere in this pipeline. Verified via a real, green pipeline
run authenticating and pushing an image (docs/evidence/04, 07).
The CI service account is least-privilege, not project-Owner/Editor.
Exact role set (verified via gcloud projects get-iam-policy):
roles/cloudbuild.builds.editor, roles/serviceusage.serviceUsageConsumer,
roles/storage.admin (project-scoped — required specifically because
gcloud builds submit checks storage.buckets.list, a permission that
does not exist at bucket-level scope; this was confirmed via a raw
--log-http diagnostic, not assumed), plus roles/iam.serviceAccountUser
scoped to one specific service account (Cloud Build's default runtime
identity), and roles/artifactregistry.writer scoped to one specific
repository.
Supply Chain — Implemented
Immutable image tags. Artifact Registry is configured to reject a
second push to an already-used tag. This was not a planned feature that
happened to also catch a real mistake — it caught one live, during this
build, when a floating :latest tag was pushed a second time and the
registry correctly refused it. Every subsequent build uses a unique
tag (commit SHA or timestamp).
Admission-time tag policy (Kyverno, Enforce mode). A pod referencing
:latest is rejected before creation, not logged-and-allowed. Verified
by deliberately attempting to create such a pod and observing the
rejection (docs/evidence/15).
Supply Chain — Configured, Not Behaviorally Verified
Container vulnerability scanning. Artifact Registry's scanning is
enabled on the repository. No scan result has been pulled and reviewed
as part of this project's evidence to date. Marked Configured, not
Implemented, until that gap is closed.
Policy-as-Code — Implemented (mixed enforcement modes, by design)
Three Kyverno ClusterPolicy objects:
Policy
Mode
Rationale
disallow-latest-tag
Enforce
Direct codification of a real incident (see above)
require-app-label
Audit
Ownership/observability tracing; not enforced yet to avoid breaking already-running workloads during rollout
restrict-image-registries
Audit
Supply-chain scoping; same rollout-safety reasoning
The Enforce/Audit split is a deliberate engineering choice, not an
oversight — blocking every rule immediately, before confirming existing
workloads comply, risks an unplanned outage for the sake of policy
purity.
Runtime Platform Defaults — Implemented (inherited, not built)
GKE Autopilot enforces a baseline pod security posture directly
(blocks privileged containers, auto-injects resource requests) —
these are Google-managed defaults, not something this project
configured, and are documented as such rather than claimed as original
work.
Secrets Management — Implemented (partial)
No credential used by this project (GitHub/GitLab tokens, GCP auth) is
committed to source control. GitOps publishing credentials for Backstage
are stored as a Kubernetes Secret, created imperatively via
kubectl create secret with the value piped in from a hidden terminal
prompt — never written to a file, never logged.
Planned, Not Built
Network policies restricting pod-to-pod traffic within the cluster.
Image signing/attestation (e.g. cosign).
SBOM generation.
These are real gaps, listed in docs/engineering/technical-debt.md, not
silently omitted.
