resource "google_project_service" "cloudbuild" {
  project            = "forge-platform-11124"
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

data "google_project" "forge" {
  project_id = "forge-platform-11124"
}

# GCP provisions the Cloud Build service agent asynchronously after the
# API is enabled - this forces Terraform to wait instead of racing it.
resource "time_sleep" "wait_for_cloudbuild_sa" {
  create_duration = "60s"
  depends_on      = [google_project_service.cloudbuild]
}

resource "google_artifact_registry_repository_iam_member" "cloudbuild_pusher" {
  project    = "forge-platform-11124"
  location   = "us-central1"
  repository = google_artifact_registry_repository.forge_images.repository_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${data.google_project.forge.number}@cloudbuild.gserviceaccount.com"

  depends_on = [time_sleep.wait_for_cloudbuild_sa]
}
