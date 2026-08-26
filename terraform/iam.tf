resource "google_service_account" "ci_pusher" {
  project      = "forge-platform-11124"
  account_id   = "forge-ci-pusher"
  display_name = "Forge CI - Artifact Registry pusher (scoped, no key file)"
}

resource "google_artifact_registry_repository_iam_member" "ci_pusher_binding" {
  project    = "forge-platform-11124"
  location   = "us-central1"
  repository = google_artifact_registry_repository.forge_images.repository_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.ci_pusher.email}"
}

output "ci_pusher_service_account_email" {
  value = google_service_account.ci_pusher.email
}

output "artifact_registry_repo_url" {
  value = "us-central1-docker.pkg.dev/forge-platform-11124/forge-images"
}
