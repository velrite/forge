# The final missing piece: storage.buckets.list is a PROJECT-level
# permission - it cannot be granted via any single bucket's IAM policy,
# which is why every prior bucket-scoped grant (objectAdmin,
# storage.admin - on TWO separate buckets) never touched it.
# Confirmed as the exact root cause via --log-http diagnostic.

resource "google_project_iam_member" "gitlab_ci_storage_viewer" {
  project = "forge-platform-11124"
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:gitlab-ci-forge@forge-platform-11124.iam.gserviceaccount.com"
}
