resource "google_container_cluster" "forge" {
  name     = "forge-cluster"
  location = "us-central1"
  project  = "forge-platform-11124"

  enable_autopilot = true

  network    = google_compute_network.forge_vpc.id
  subnetwork = google_compute_subnetwork.forge_subnet.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "forge-pods"
    services_secondary_range_name = "forge-services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  workload_identity_config {
    workload_pool = "forge-platform-11124.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR"
  }

  deletion_protection = false

  depends_on = [google_compute_router_nat.forge_nat]
}

output "cluster_name" {
  value = google_container_cluster.forge.name
}

output "cluster_endpoint" {
  value     = google_container_cluster.forge.endpoint
  sensitive = true
}

output "cluster_location" {
  value = google_container_cluster.forge.location
}
