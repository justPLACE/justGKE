provider "google" {
  project = var.project_id
  region  = var.location
}

resource "google_compute_network" "network" {
  name                    = "network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.region
  network       = google_compute_network.network.id
  secondary_ip_range {
    range_name    = "cluster-range"
    ip_cidr_range = "192.168.1.0/24"
  }

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "192.168.64.0/22"
  }
}

resource "google_container_cluster" "cluster" {
  name                      = var.cluster_name
  location                  = var.location
  remove_default_node_pool  = true
  default_max_pods_per_node = 110
  logging_service           = "none"
  monitoring_service        = "none"
  initial_node_count        = 1

  network    = google_compute_network.network.id
  subnetwork = google_compute_subnetwork.subnetwork.id

  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.subnetwork.secondary_ip_range.0.range_name
    services_secondary_range_name = google_compute_subnetwork.subnetwork.secondary_ip_range.1.range_name
  }
}

resource "google_container_node_pool" "pool" {
  name           = var.node_pool_name
  location       = var.location
  project        = var.project_id
  version        = var.worker_nodes_version
  cluster        = google_container_cluster.cluster.name
  node_locations = var.node_locations
  node_count     = var.worker_nodes_count

  node_config {
    disk_size_gb = var.worker_nodes_disk_size
    machine_type = var.worker_node_type
    preemptible  = false
    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    ]
  }
}
