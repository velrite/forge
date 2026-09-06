# Dedicated Cloud Build source-staging bucket, uniform IAM (not the
# legacy-ACL auto-managed {PROJECT}_cloudbuild bucket, which does not
# reliably honor IAM grants for WIF/external-account identities).

resource "google_storage_bucket" "gitlab_ci_source" {
  project                     = "forge-platform-11124"
  name                        = "forge-platform-11124-gitlab-ci-source"
  location                    = "us-central1"
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket_iam_member" "gitlab_ci_source_admin" {
  bucket = google_storage_bucket.gitlab_ci_source.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:gitlab-ci-forge@forge-platform-11124.iam.gserviceaccount.com"
}

output "gitlab_ci_source_bucket" {
  value = google_storage_bucket.gitlab_ci_source.name
}
