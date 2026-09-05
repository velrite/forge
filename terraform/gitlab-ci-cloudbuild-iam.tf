# Least-privilege grants for gitlab-ci-forge to actually submit Cloud
# Builds - artifactregistry.writer (ADR-012) was necessary but not
# sufficient; Cloud Build itself requires these two additional grants.

resource "google_project_iam_member" "gitlab_ci_cloudbuild_editor" {
  project = "forge-platform-11124"
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:gitlab-ci-forge@forge-platform-11124.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "gitlab_ci_serviceusage" {
  project = "forge-platform-11124"
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:gitlab-ci-forge@forge-platform-11124.iam.gserviceaccount.com"
}

# Scoped to the specific Cloud Build staging bucket only - not
# project-wide storage access.
resource "google_storage_bucket_iam_member" "gitlab_ci_cloudbuild_bucket" {
  bucket = "forge-platform-11124_cloudbuild"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:gitlab-ci-forge@forge-platform-11124.iam.gserviceaccount.com"
}
