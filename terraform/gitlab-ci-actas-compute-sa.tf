# Cloud Build runs the actual build steps as the default Compute Engine
# service account (its default build-runtime identity, unless a custom
# build service account is configured). gitlab-ci-forge needs permission
# to "act as" this specific account to submit builds - scoped to just
# this one service account, not project-wide.

resource "google_service_account_iam_member" "gitlab_ci_actas_compute_sa" {
  service_account_id = "projects/forge-platform-11124/serviceAccounts/623383904945-compute@developer.gserviceaccount.com"
  role                = "roles/iam.serviceAccountUser"
  member              = "serviceAccount:gitlab-ci-forge@forge-platform-11124.iam.gserviceaccount.com"
}
