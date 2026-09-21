# Getting Started — Start, Verify, Test, Destroy

All commands assume `gcloud` is authenticated and `kubectl`/`helm`/`argocd`/
`kubectl-argo-rollouts` are on PATH. Run the identity check below first, in
every session — it catches the two most common failure causes (wrong active
GCP project, stale kubectl context) before they cascade into unrelated
errors.

## 0. Session Identity Check (run first, every session)

```bash
gcloud auth list --filter=status:ACTIVE --format="value(account)"
gcloud config set project forge-platform-11124
gcloud config get-value project
Expected result: an active account email printed by the first command;
forge-platform-11124 printed by the third. If the first command prints
nothing, run gcloud auth login before continuing.
1. Start (bring the cluster up)
The cluster and its Cloud NAT are the only components in this project that
cost money while running (~$1/day) — everything else (VPC, Artifact
Registry, IAM, Argo CD, Prometheus, Kyverno definitions) costs nothing
whether the cluster is up or down. Start here:
cd terraform
terraform apply -auto-approve \
  -target=google_container_cluster.forge \
  -target=google_compute_router_nat.forge_nat \
  -target=google_compute_router.forge_router
cd ..

gcloud container clusters get-credentials forge-cluster \
  --region=us-central1 --project=forge-platform-11124

kubectl config current-context
Expected result: Terraform reports Apply complete! Resources: 3 added. kubectl config current-context prints a string containing
forge-cluster. Cluster creation takes 5–10 minutes on a cold start.
Note: a full cluster teardown/rebuild removes all workloads
(Backstage, Argo CD, Prometheus, Kyverno, OpenCost). They must be
reapplied — this is not a pause/resume, it is a real rebuild. See
Section 4 for reapplying workloads after a rebuild.
2. Verify Core Components Are Healthy
kubectl get nodes
kubectl get pods -n forge-platform
kubectl get pods -n argocd
kubectl get pods -n observability
kubectl get pods -n kyverno
kubectl get pods -n opencost
Expected result: all pods across all five namespaces show STATUS: Running with READY at full count (e.g. 1/1, 2/2). Note: on a
freshly rebuilt cluster this can take several minutes for every pod to
schedule — Autopilot provisions node capacity on demand, and this
cluster runs close to its memory ceiling with the full stack deployed.
If a pod is stuck Pending, check kubectl describe pod <name> -n <namespace> and look at the Events: section before assuming
something is broken.
3. Smoke Test (confirms the platform is actually functioning, not just running)
export PATH=$HOME/bin:$PATH

echo "--- Backstage Rollout health ---"
kubectl argo rollouts get rollout backstage -n forge-platform --watch=false

echo "--- Argo CD sync state ---"
kubectl port-forward svc/argocd-server -n argocd 8080:443 > /tmp/argocd-pf.log 2>&1 &
sleep 5
ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login localhost:8080 --username admin --password "$ARGOCD_PWD" --insecure > /dev/null 2>&1
argocd app list
pkill -f "port-forward.*argocd-server" 2>/dev/null

echo "--- Kyverno policy enforcement ---"
cat > /tmp/policy-test-latest.yaml << 'YAMLEOF'
apiVersion: v1
kind: Pod
metadata:
  name: policy-test-latest
  namespace: forge-demo
spec:
  containers:
    - name: test
      image: nginx:latest
YAMLEOF
kubectl apply -f /tmp/policy-test-latest.yaml || echo "(rejection above is EXPECTED and correct)"

echo "--- Prometheus scrape health ---"
kubectl port-forward svc/kube-prometheus-stack-prometheus -n observability 9090:9090 > /tmp/prom-pf.log 2>&1 &
sleep 5
curl -s "http://localhost:9090/api/v1/targets" | python3 -c "
import json,sys
d=json.load(sys.stdin)
up = sum(1 for t in d['data']['activeTargets'] if t['health']=='up')
total = len(d['data']['activeTargets'])
print(f'{up}/{total} Prometheus targets healthy')
"
pkill -f "port-forward.*prometheus-operated" 2>/dev/null
Expected result, section by section:
Backstage Rollout: Status: Healthy, Step: 6/6, two ready replicas.
Argo CD: forge-demo listed with SYNC STATUS: Synced (if this app
has been intentionally scaled down for memory management, Healthy
may instead show Missing — that is a known, deliberate state, not a
failure; see docs/engineering/technical-debt.md).
Kyverno: the kubectl apply command must fail with an admission
webhook error naming disallow-latest-tag. If it succeeds and creates
the pod, the policy is not enforcing — investigate before proceeding.
Prometheus: a ratio close to or at 1/1 (all discovered targets
healthy). A lower ratio warrants checking which target is down before
assuming the whole platform is unhealthy.
4. Reapplying Workloads After a Full Cluster Rebuild
If the cluster was torn down (Section 5) and rebuilt (Section 1), every
workload must be reapplied — Kubernetes objects do not survive a cluster
deletion, only Terraform's record of what infrastructure to recreate does.
kubectl apply -f kubernetes/backstage/namespace.yaml
kubectl apply -f kubernetes/backstage/servicemonitor.yaml
kubectl apply -f kubernetes/backstage/analysistemplate.yaml
kubectl apply -f kubernetes/backstage/rollout.yaml
kubectl apply -f kubernetes/backstage/service.yaml

kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml -n argocd --server-side --force-conflicts
kubectl apply -n argo-rollouts --server-side --force-conflicts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
Prometheus, Grafana, Kyverno, and OpenCost are Helm releases — reinstall
via the helm upgrade --install commands documented in
docs/decisions/ (ADR-014, ADR-016) and docs/engineering/debugging-history.md,
which include the specific flag sets required for this cluster's
Autopilot/memory constraints.
5. Destroy (stop billing cleanly)
cd terraform
terraform destroy -target=google_container_cluster.forge \
  -target=google_compute_router_nat.forge_nat \
  -target=google_compute_router.forge_router
cd ..
Expected result: Terraform will print a plan showing 3 resources to
destroy and prompt Enter a value:. Type yes directly on your
keyboard as its own action — do not paste it as part of a larger block,
this has previously caused the confirmation to be silently dropped.
On completion: Destroy complete! Resources: 3 destroyed.
Verify independently, not just by trusting the Terraform output:
gcloud container clusters list --format="table(name,location,status)"
Expected result: empty output — no rows. This is the authoritative
confirmation that billing has stopped, independent of what Terraform
itself reports.
