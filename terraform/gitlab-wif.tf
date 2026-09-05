resource "google_iam_workload_identity_pool" "gitlab" {
  project                   = "forge-platform-11124"
  workload_identity_pool_id = "gitlab-pool"
  display_name              = "GitLab CI Pool"
  description                = "Trusts GitLab.com CI/CD JWTs, scoped to one namespace"
}

resource "google_iam_workload_identity_pool_provider" "gitlab" {
  project                            = "forge-platform-11124"
  workload_identity_pool_id          = google_iam_workload_identity_pool.gitlab.workload_identity_pool_id
  workload_identity_pool_provider_id = "gitlab-provider"
  display_name                       = "GitLab.com OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.namespace"  = "assertion.namespace_path"
    "attribute.project"    = "assertion.project_path"
    "attribute.ref"        = "assertion.ref"
  }

  # SECURITY: only tokens from the velrite namespace are trusted - not
  # any GitLab.com project anywhere. This is the actual security boundary.
  attribute_condition = "assertion.namespace_path == \"velrite-group\""

  oidc {
    issuer_uri = "https://gitlab.com"
  }
}

resource "google_service_account" "gitlab_ci" {
  project      = "forge-platform-11124"
  account_id   = "gitlab-ci-forge"
  display_name = "GitLab CI - Forge pipeline (Workload Identity, no key file)"
}

resource "google_service_account_iam_member" "gitlab_wif_binding" {
  service_account_id = google_service_account.gitlab_ci.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.gitlab.name}/attribute.namespace/velrite"
}

resource "google_artifact_registry_repository_iam_member" "gitlab_ci_pusher" {
  project    = "forge-platform-11124"
  location   = "us-central1"
  repository = "forge-images"
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.gitlab_ci.email}"
}

output "gitlab_ci_service_account" {
  value = google_service_account.gitlab_ci.email
}

output "gitlab_wif_provider_resource_name" {
  value = google_iam_workload_identity_pool_provider.gitlab.name
}
