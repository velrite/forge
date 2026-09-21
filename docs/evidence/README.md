# Evidence Index

Every image below is real captured output from this project's own
deployed environment — no mockups, no invented command output. Each
entry states the exact claim it supports and its evidence strength
(CRITICAL / STRONG / SUPPORTING), consistent with the rest of this
documentation's honesty standard.

| # | Evidence | Proves | Strength |
|---|---|---|---|
| 01 | 

![Cluster Nodes](01-cluster-nodes.png)

 | GKE Autopilot cluster is real, private, regional, healthy | CRITICAL |
| 02 | 

![Backstage Rollout Healthy](02-backstage-rollout-healthy.png)

 | Backstage runs as a canary-capable Argo Rollout, not a plain Deployment | CRITICAL |
| 03 | 

![Backstage Pods and Service](03-backstage-pods-service.png)

 | Correct replica count and Service label wiring | STRONG |
| 04 | 

![GitLab Pipeline Success](04-gitlab-pipeline-success.png)

 | Full CI/CD pipeline executes and passes end-to-end | CRITICAL |
| 05 | 

![Cloud Build History](05-cloudbuild-history.png)

 | Independent, GCP-side confirmation of the image build | STRONG |
| 06 | 

![Artifact Registry Images](06-artifact-registry-images.png)

 | Unique image tags, no reused `:latest` | STRONG |
| 07 | 

![WIF Pool and Provider](07-wif-pool-provider.png)

 | CI authenticates with zero stored secrets, scoped trust condition | CRITICAL |
| 08 | 

![IAM Least Privilege](08-iam-least-privilege.png)

 | CI identity holds scoped roles, not Owner/Editor | STRONG |
| 09 | 

![Terraform Clean Plan](09-terraform-clean-plan.png)

 | Infrastructure fully declared, zero drift | SUPPORTING |
| 10 | 

![Argo CD App Health](10-argocd-app-health.png)

 | Real GitOps sync, not a manual deployment | CRITICAL |
| 11 | 

![GitOps Self-Heal Sequence](11-gitops-self-heal-sequence.png)

 | Automatic drift correction, demonstrated live | CRITICAL |
| 12 | 

![Canary Progression](12-canary-progression.png)

 | Real staged rollout (20% -> 50% -> 100%) | CRITICAL |
| 13 | 

![Canary Automatic Rollback](13-canary-auto-rollback.png)

 | Bad deploy caught and blocked automatically, zero downtime | CRITICAL |
| 14 | 

![Kyverno Policy List](14-kyverno-policy-list.png)

 | Explicit Enforce vs. Audit policy design | STRONG |
| 15 | 

![Kyverno Admission Denied](15-kyverno-admission-denied.png)

 | Policy actually blocks, does not just log | CRITICAL |
| 16 | 

![Prometheus Targets Up](16-prometheus-targets-up.png)

 | Real metric scraping, not a dashboard pointed at nothing | STRONG |
| 17 | 

![SLO PromQL Live Result](17-slo-promql-live-result.png)

 | Availability SLI computed from live cluster state | STRONG |
| 18 | 

![Grafana SLO Dashboard](18-grafana-slo-dashboard.png)

 | Dashboard renders real panel data (verify before treating as proof — see technical debt) | SUPPORTING |
| 19 | 

![OpenCost Cost Breakdown](19-opencost-cost-breakdown.png)

 | Real, computed per-namespace cost, not invented figures | CRITICAL |
| 20 | 

![Pod Failure Self-Heal](20-pod-failure-selfheal.png)

 | Kubernetes reschedules a killed pod automatically | STRONG |
| 21 | 

![ADR Commit History](21-adr-commit-history.png)

 | Decisions recorded contemporaneously over real time, not retrofitted | SUPPORTING |
| 22 | 

![GCP Budget Alert](22-gcp-budget-alert.png)

 | A real cost guardrail is configured, not just discussed | SUPPORTING |

## How to Read This Index

Items marked CRITICAL are load-bearing for a specific architectural
claim made elsewhere in this documentation — if one of these is
missing or wrong, the corresponding claim should be treated as
unverified until it is recaptured. Items marked SUPPORTING corroborate
but are not, on their own, sufficient proof of a capability.
