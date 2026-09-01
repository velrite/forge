# Forge Operations Runbook

Practical, tested procedures for running Forge day to day. Every entry
here was validated against a real failure encountered during the build
- not written speculatively.

## Session Startup Checklist (run at the start of every work session)

Cloud Shell resets shell variables, active gcloud account, and
sometimes kubectl context between sessions. Always run this first:

    export PROJECT_ID="forge-platform-11124"
    export REGION="us-central1"
    gcloud config set project "$PROJECT_ID"
    gcloud auth list
    kubectl config current-context

Expected: project prints correctly, an account shows ACTIVE, context
shows `gke_forge-platform-11124_us-central1_forge-cluster`. If auth
shows no ACTIVE account, run `gcloud auth login` before anything else.

## Safety Guard Pattern (use before every cluster-mutating command)

Wrap in a subshell so a failed check can't close your terminal:

    (
      if [ "$(gcloud config get-value project 2>/dev/null)" != "forge-platform-11124" ]; then
        echo "!!! STOP - wrong project !!!"; exit 1
      fi
      if ! kubectl config current-context | grep -q "forge-cluster"; then
        echo "!!! STOP - wrong cluster !!!"; exit 1
      fi
      # risky commands go here
    )

## Bringing the Cluster Up / Down (cost control)

Cluster + Cloud NAT are the only ongoing cost while idle (~$1/day).
Tear down when done for the day:

    cd ~/forge/terraform
    terraform destroy -target=google_container_cluster.forge -target=google_compute_router_nat.forge_nat -target=google_compute_router.forge_router

Bring back up (a few minutes, no config changes needed):

    cd ~/forge/terraform
    terraform plan -out=restore.tfplan   # review before applying
    terraform apply "restore.tfplan"
    gcloud container clusters get-credentials forge-cluster --region=us-central1 --project=forge-platform-11124

## Rebuilding and Redeploying Backstage

Images are tagged uniquely (never :latest - Artifact Registry has tag
immutability enabled, see ADR-011). Always:

    cd ~/forge/platform/backstage
    TAG=$(date +%Y%m%d-%H%M%S)
    gcloud builds submit --config=cloudbuild.yaml --substitutions=_TAG="$TAG" .
    # wait for STATUS: SUCCESS, then:
    kubectl set image deployment/backstage backstage="us-central1-docker.pkg.dev/forge-platform-11124/forge-images/backstage:${TAG}" -n forge-platform
    kubectl rollout status deployment/backstage -n forge-platform --timeout=180s
    # update kubernetes/backstage/deployment.yaml to match, commit it

## Accessing Backstage

No Ingress exists yet - access via port-forward + Cloud Shell Web Preview:

    kubectl port-forward -n forge-platform svc/backstage 7007:7007

Then Web Preview -> port 7007. Direct curl to /api/catalog/* will
return AuthenticationError - this is correct backend behavior, not a
bug; use the browser for UI-facing checks.
