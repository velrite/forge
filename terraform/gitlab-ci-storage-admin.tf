# gcloud builds submit unconditionally checks the DEFAULT {PROJECT}_cloudbuild
# bucket at startup, regardless of --gcs-source-staging-dir/--gcs-log-dir
# overrides. That check requires storage.buckets.list, which ONLY exists on
# roles/storage.admin or roles/viewer at the PROJECT level - no bucket-scoped
# grant can satisfy it. Confirmed via --log-http raw diagnostic, not guessed.
resource "google_project_iam_member" "gitlab_ci_storage_admin" {
  project = "forge-platform-11124"
  role    = "roles/storage.admin"
  member  = "serviceAccount:gitlab-ci-forge@forge-platform-11124.iam.gserviceaccount.com"
}
