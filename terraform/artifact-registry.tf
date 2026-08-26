resource "google_project_service" "artifact_registry" {
  project            = "forge-platform-11124"
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "container_scanning" {
  project            = "forge-platform-11124"
  service            = "containerscanning.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "container_analysis" {
  project            = "forge-platform-11124"
  service            = "containeranalysis.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "forge_images" {
  project       = "forge-platform-11124"
  location      = "us-central1"
  repository_id = "forge-images"
  description   = "Forge platform container images - golden path services"
  format        = "DOCKER"

  docker_config {
    immutable_tags = true
  }

  depends_on = [google_project_service.artifact_registry]
}
