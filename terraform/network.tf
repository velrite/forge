resource "google_compute_network" "forge_vpc" {
  name                    = "forge-vpc"
  auto_create_subnetworks = false
  project                 = "forge-platform-11124"
}

resource "google_compute_subnetwork" "forge_subnet" {
  name          = "forge-subnet"
  ip_cidr_range = "10.10.0.0/20"
  region        = "us-central1"
  network       = google_compute_network.forge_vpc.id
  project       = "forge-platform-11124"

  secondary_ip_range {
    range_name    = "forge-pods"
    ip_cidr_range = "10.20.0.0/14"
  }

  secondary_ip_range {
    range_name    = "forge-services"
    ip_cidr_range = "10.30.0.0/20"
  }

  private_ip_google_access = true
}

resource "google_compute_router" "forge_router" {
  name    = "forge-router"
  region  = "us-central1"
  network = google_compute_network.forge_vpc.id
  project = "forge-platform-11124"
}

resource "google_compute_router_nat" "forge_nat" {
  name                               = "forge-nat"
  router                             = google_compute_router.forge_router.name
  region                             = "us-central1"
  project                            = "forge-platform-11124"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
