# Forge — Internal Developer Platform on Google Cloud

**A platform-engineering project focused on secure delivery, declarative operations, progressive releases, policy enforcement, and operational evidence.**

Forge brings together the core building blocks of an Internal Developer Platform (IDP): infrastructure as code, identity-aware CI/CD, GitOps reconciliation, canary delivery, admission control, Kubernetes observability, and workload cost attribution. The project is designed around a practical engineering question:

> Can the platform demonstrate that its controls work—not just show that the configuration exists?

The repository includes implementation artifacts, operational procedures, architecture decisions, troubleshooting records, and evidence captured from the running environment.

[Architecture](#architecture) · [Verified capabilities](#verified-capabilities) · [Technology stack](#technology-stack) · [Getting started](#getting-started) · [Documentation](#documentation)

---

## Platform at a glance

| Capability | Implementation |
|---|---|
| Cloud infrastructure | Terraform, Google Kubernetes Engine (GKE) Autopilot, VPC, Artifact Registry |
| CI/CD identity | GitLab CI with Google Cloud Workload Identity Federation |
| Image build and storage | Cloud Build and Artifact Registry with immutable image tags |
| Deployment reconciliation | Argo CD |
| Progressive delivery | Argo Rollouts with staged canary analysis |
| Admission controls | Kyverno policies |
| Metrics and reliability signals | Prometheus, kube-state-metrics, OpenTelemetry Collector |
| Cost visibility | OpenCost and Google Cloud budget alerts |
| Developer portal | Backstage and golden-path scaffolding |
| Engineering governance | Architecture Decision Records, operational runbooks, evidence index |

## Why this project matters

A delivery platform is more than a pipeline that turns source code into a container image. A dependable platform must also manage identity, preserve a declarative source of truth, release changes progressively, detect unhealthy deployments, apply guardrails before workloads enter the cluster, and make operational behavior observable.

Forge explores those responsibilities as one integrated system. Its emphasis is on **verifiable platform behavior**:

- **Identity without long-lived CI credentials.** GitLab uses Workload Identity Federation to obtain Google Cloud access without storing a service-account key in the pipeline.
- **Reconciliation, not configuration alone.** Argo CD continuously compares cluster state with Git and can correct tested forms of drift.
- **Health-gated releases.** Argo Rollouts advances through staged canary weights and uses Prometheus-backed analysis to inform rollout decisions.
- **Preventive policy enforcement.** Kyverno evaluates workload admission rules; the `latest` image-tag policy is enforced at creation time.
- **Operational visibility.** Prometheus scrape health, Kubernetes-level reliability queries, and OpenCost namespace attribution provide concrete signals for investigation.
- **Engineering traceability.** Architecture decisions, debugging notes, operating instructions, and screenshots make implementation choices and verification steps reviewable.

## Architecture

![Forge Developer Platform Architecture](docs/evidence/Forge_%20Developer%20Platform%20Architecture.png)

### Delivery flow

1. A code change is pushed to the canonical GitHub repository and mirrored to GitLab for CI execution.
2. GitLab authenticates to Google Cloud using Workload Identity Federation rather than a long-lived service-account key.
3. Cloud Build builds the image and publishes it to Artifact Registry using an immutable tag.
4. Argo CD reconciles Kubernetes resources from the declared Git state.
5. Argo Rollouts progressively advances the application through canary stages, using Prometheus analysis as a health signal.
6. Kyverno evaluates applicable admission policies when Kubernetes resources are created.

## Verified capabilities

The project distinguishes a configured integration from a behavior that has been exercised and observed. The following results are documented in the repository's evidence and operational records.

| Capability | Verification result |
|---|---|
| GKE infrastructure | Running regional cluster with private nodes confirmed through Google Cloud inspection |
| Infrastructure as code | Terraform plan reported no changes against the provisioned environment at the time of verification |
| CI identity | Workload Identity Federation configuration inspected; no static GCP service-account key used by CI |
| IAM scope | CI identity's project role assignments inspected; no Owner or Editor role in the recorded verification |
| GitOps drift correction | A test workload was manually scaled down and Argo CD restored its declared replica count |
| Canary progression | Rollout weight progression observed at 20%, 50%, and 100% |
| Automated rollout abort | An intentionally invalid image tag caused the canary to abort while stable pods remained running during the observed test |
| Admission policy | A pod using `nginx:latest` was rejected by Kyverno before creation |
| Metrics collection | Prometheus target health was inspected and active scrape targets were observed |
| Pod self-healing | Deleting a managed pod resulted in its controller creating a replacement |
| Cost attribution | OpenCost returned computed namespace-level cost data for a sampled observation window |
| Budget guardrail | Google Cloud budget alerts configured at 50%, 90%, 100%, and 150% of the configured $10 budget |

These checks demonstrate specific behaviors in the tested environment; they are not a claim of production workload history or a substitute for repeatable automated integration tests. The supporting evidence index maps captured artifacts to the corresponding claims.

## Technology stack

| Layer | Technology | Role in Forge |
|---|---|---|
| Infrastructure | Terraform, GCS remote state, GKE Autopilot, VPC | Declarative provisioning and managed Kubernetes infrastructure |
| CI/CD | GitLab CI/CD, Workload Identity Federation, Cloud Build | Pipeline orchestration and short-lived cloud identity |
| Container registry | Artifact Registry | Storage of built images with immutable tags |
| GitOps | Argo CD | Desired-state reconciliation and drift correction |
| Progressive delivery | Argo Rollouts | Staged canary releases and analysis-driven rollout decisions |
| Policy | Kyverno | Kubernetes admission-time guardrails |
| Metrics | Prometheus, kube-state-metrics | Scraping and Kubernetes-level reliability signals |
| Telemetry | OpenTelemetry Collector | Telemetry collection and export configuration |
| FinOps | OpenCost, Google Cloud budgets | Namespace-level cost attribution and spend alerts |
| Developer experience | Backstage | Developer portal and golden-path service scaffolding |

## Security and operational design

### Identity and access

- Workload Identity Federation is used for CI-to-Google-Cloud authentication, avoiding a stored service-account key in the pipeline.
- The CI identity's role assignments were inspected as part of verification.
- Artifact Registry uses immutable image tags to reduce the risk of silently replacing an image behind an existing tag.

### Admission policy

Kyverno provides admission-time policy evaluation. The `disallow-latest-tag` policy is configured in enforcement mode. The `require-app-label` and `restrict-image-registries` policies are configured in audit mode, allowing policy findings to be evaluated before enforcement is tightened.

### Delivery safety

Argo Rollouts stages traffic through canary weights and uses Prometheus-backed analysis. The repository documents a failure test in which an invalid image tag caused the rollout to abort while the stable version remained available during the observed test window.

### Observability boundaries

Backstage's `/metrics` endpoint was checked and did not return Prometheus-format application metrics. Consequently, the documented SLOs use Kubernetes-level signals rather than application request latency or end-user experience measurements. The OpenTelemetry Collector is configured with a debug exporter; traces are not retained in a dedicated queryable tracing backend.

## Engineering investigation: diagnosing Workload Identity Federation and Cloud Build

One of the project's most useful engineering outcomes came from investigating a CI build failure that appeared to be a bucket-level permission problem.

**Symptom:** `gcloud builds submit` failed with a bucket-access error for the CI identity. Adding bucket-scoped object permissions did not resolve it.

**Diagnosis:** Inspecting the raw HTTP response with `--log-http` revealed a missing `storage.buckets.list` permission. That permission could not be satisfied by a bucket-scoped grant. The investigation also identified complications with Cloud Build's automatically managed upload bucket and the automatic source-upload path when using a federated identity.

**Resolution:** The workflow was changed to use a dedicated uniform-IAM bucket, explicitly package and upload the source archive with `tar` and `gcloud storage cp`, and submit the already-uploaded source object to Cloud Build. The required project-level permission was granted to make the bucket-list operation possible.

**Process improvement:** The permission change was validated through service-account impersonation before relying on a full pipeline run. The detailed incident record and related investigations are available in [the debugging history](docs/engineering/debugging-history.md).

This is an example of the project's engineering approach: inspect the underlying failure, distinguish the visible symptom from the actual permission boundary, validate the fix, and preserve the reasoning for future operators.

## Reliability objectives and scope

The repository defines Kubernetes-level reliability objectives that match the current architecture.

| Signal | Target | Interpretation |
|---|---|---|
| Availability | 99% over 30 days | A deliberately conservative target for the current single-rollout, two-replica design |
| Restart stability | 0 restarts per hour | Complements availability by detecting unstable workloads |

These are platform-level objectives, not measured application-level SLOs. Forge has not been load-tested and has not served real user traffic. Node-failure resilience has not been tested; the existing cluster's resource headroom made an unplanned disruption an inappropriate test without additional capacity and a controlled test plan.

## Cost visibility

OpenCost has been used to retrieve computed namespace-level cost attribution from the cluster. One recorded sample covered approximately 87.8 hours for most namespaces and reported $57.15 month-to-date at the time of collection. This is a **point-in-time sample**, not a continuous cost trend or a monthly forecast.

A Google Cloud budget guardrail is configured at $10 with alerts at 50%, 90%, 100%, and 150%. Actual charges depend on the resources provisioned and the time they remain active. Review the cloud billing account and current budget configuration before running the environment.

## Developer experience

Forge includes Backstage and a golden-path template for scaffolding a service. The template demonstrates the starting point for a standardized developer workflow. The repository-publishing step is not yet automated end to end, so the current implementation should be understood as **developer-portal scaffolding**, rather than a complete self-service service-provisioning lifecycle.

## Getting started

Forge provisions cloud infrastructure and can incur charges. Review the [operations guide](docs/operations/getting-started.md) before applying Terraform or deploying resources.

### Prerequisites

- Google Cloud project with the required APIs and permissions enabled
- Terraform and Google Cloud CLI (`gcloud`)
- `kubectl` and access to the target GKE cluster
- Access to the GitHub and GitLab repositories used by the delivery workflow
- A configured Google Cloud billing account and budget controls

### Provisioning entry point

The repository's operations guide contains the full start, verify, smoke-test, and destroy procedures, including expected command output. The basic cluster access sequence documented for the project is:

```bash
cd terraform

terraform apply -auto-approve \
  -target=google_container_cluster.forge \
  -target=google_compute_router_nat.forge_nat \
  -target=google_compute_router.forge_router

gcloud container clusters get-credentials forge-cluster \
  --region=us-central1 \
  --project=forge-platform-11124
```

The Terraform targets above are a staged provisioning entry point, not a replacement for the complete documented lifecycle. Follow the [getting-started guide](docs/operations/getting-started.md) for the intended order of operations, verification, and teardown. Confirm that the project ID and active Google Cloud account are correct before running commands.

## Repository layout

```text
forge/
├── terraform/              # Cloud infrastructure as code
├── kubernetes/              # Rollout, Service, monitoring and analysis manifests
├── platform/backstage/      # Backstage portal, templates and build configuration
├── gitops/                  # Argo CD-managed application state
├── policies/                # Kyverno admission policies
├── observability/           # SLO queries and dashboard configuration
└── docs/
    ├── architecture/        # System overview and architecture documentation
    ├── decisions/           # Architecture Decision Records (ADR-001–ADR-017)
    ├── operations/          # Start, verify, test and destroy procedures
    ├── security/            # Security control documentation
    ├── reliability/         # SLOs and reliability assumptions
    ├── engineering/         # Debugging history and technical debt
    └── evidence/            # Screenshot evidence and index
```

## Documentation

| Document | Purpose |
|---|---|
| [System architecture](docs/architecture/system-overview.md) | Architecture, components, and responsibilities |
| [Getting started](docs/operations/getting-started.md) | Start, verify, smoke-test, and destroy procedures |
| [Security controls](docs/security/security-controls.md) | Implemented, configured, and planned security controls |
| [Observability](docs/observability/observability.md) | Metrics, telemetry, and observability implementation |
| [SLOs and reliability](docs/reliability/slo.md) | Reliability objectives, formulas, and measurement boundaries |
| [Debugging history](docs/engineering/debugging-history.md) | Incidents, root causes, fixes, and lessons learned |
| [Technical debt](docs/engineering/technical-debt.md) | Remaining engineering work and rationale |
| [Evidence index](docs/evidence/README.md) | Captured screenshots mapped to the claims they support |
| [Plain-language overview](docs/for-everyone.md) | Non-specialist explanation of the platform |
| [Architecture decisions](docs/decisions/) | ADR-001 through ADR-017 |

## Current scope and next engineering steps

The project has a functioning, behaviorally tested foundation across infrastructure, CI/CD identity, GitOps, progressive delivery, admission policy, Kubernetes-level observability, and cost attribution. The next steps toward a more complete platform are:

1. Complete automated repository publishing from the Backstage golden path.
2. Persist the Backstage catalog in a durable database and move beyond guest-only authentication.
3. Confirm Grafana dashboard rendering and end-to-end Slack alert delivery.
4. Review Artifact Registry vulnerability scan findings and document remediation.
5. Introduce and validate network policies, image signing, and SBOM generation.
6. Add a controlled resilience test plan with sufficient cluster capacity before testing node disruption.
7. Add repeatable automated integration tests for the delivery and policy behaviors documented here.

These items are presented as a forward engineering plan so reviewers can distinguish verified behavior from configured integrations and planned controls.

## Evidence and reproducibility

The repository includes 22 captured evidence artifacts covering cluster state, rollout health, CI execution, Workload Identity Federation, IAM, Terraform planning, Argo CD reconciliation, canary progression and abort, Kyverno enforcement, Prometheus targets, SLO queries, cost attribution, pod recovery, and budget configuration.

See the [evidence index](docs/evidence/README.md) for the artifact inventory and the specific claim each item supports. Evidence reflects the environment at the time it was captured; repeat the documented checks when validating a later deployment.

---

**Project focus:** Platform Engineering · DevSecOps · Kubernetes · GitOps · Progressive Delivery · Infrastructure as Code · Observability · FinOps


## Evidence gallery

<details>
<summary><strong>View captured platform evidence</strong></summary>

The screenshots below provide visual evidence for selected infrastructure, delivery, security, observability, reliability, and cost checks. The [evidence index](docs/evidence/README.md) maps each artifact to the claim it supports.

### Infrastructure and delivery

![GKE cluster nodes](docs/evidence/01-cluster-nodes.png)

![Backstage rollout healthy](docs/evidence/02-backstage-rollout-healthy.png)

![Backstage pods and service](docs/evidence/03-backstage-pods-service.png)

![GitLab pipeline success](docs/evidence/04-gitlab-pipeline-success.png)

![Cloud Build history](docs/evidence/05-cloudbill-history.png)

![Artifact Registry images](docs/evidence/06-artifacts-registry-images.png)

### Identity and infrastructure validation

![Workload Identity Federation pool and provider](docs/evidence/07-wif-pool-provide.png)

![IAM least-privilege configuration](docs/evidence/08-iam-least-privilege.png)

![Terraform clean plan](docs/evidence/09-terraform-clean-plan.png)

### GitOps and progressive delivery

![Argo CD application health](docs/evidence/10-argocd-app-health.png)

![GitOps self-heal sequence](docs/evidence/11-gitops-self-heal-sequence.png)

![Canary rollout progression](docs/evidence/12-canary-progression.png)

![Canary automatic rollback](docs/evidence/13-canary-auto-rollback.png)

### Policy enforcement and observability

![Kyverno policy list](docs/evidence/14-kyverno-policy-list.png)

![Kyverno admission denied](docs/evidence/15-kyverno-admission-denied.png)

![Prometheus targets up](docs/evidence/16-prometheus-targets-up.png)

![SLO PromQL live result](docs/evidence/17-slo-promql-live-result.png)

![Grafana SLO dashboard](docs/evidence/18-grafana-slo-dashboard.png)

### Cost and recovery

![OpenCost cost breakdown](docs/evidence/19-opencost-cost-breakdown.png)

![Pod failure self-healing](docs/evidence/20-pod-failure-selfheal.png)

![Google Cloud budget alert](docs/evidence/22-gcp-budget-alert.png)

</details>
