# Cấu hình provider Google Cloud
provider "google" {
  project = "prj-tribvcloud"
  region  = "asia-southeast1"  # Khu vực Singapore, bạn có thể thay đổi theo nhu cầu
}

# Tạo VPC network cho GKE
resource "google_compute_network" "gke_network" {
  name                    = "gke-network"
  auto_create_subnetworks = false
}

# Tạo subnet cho GKE
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = "asia-southeast1"
  network       = google_compute_network.gke_network.id

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# Tạo cluster GKE
resource "google_container_cluster" "primary" {
  name     = "my-gke-cluster"
  location   = "asia-southeast1-a"
  
  # Xóa default node pool sau khi tạo cluster
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.gke_network.name
  subnetwork = google_compute_subnetwork.gke_subnet.name

  deletion_protection = false

  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-ranges"
    services_secondary_range_name = "services-range"
  }

  # Cấu hình private cluster (tùy chọn)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Cấu hình master authorized networks (tùy chọn)
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"  # Cho phép truy cập từ mọi nơi, nên thay đổi trong môi trường production
      display_name = "all"
    }
  }
}

# Tạo node pool riêng
resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  location   = "asia-southeast1-a"
  
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/compute",
    ]

    labels = {
      env = "production"
    }

    machine_type = "e2-medium"
    disk_size_gb = 50
    disk_type    = "pd-standard"
    preemptible  = false

    metadata = {
      disable-legacy-endpoints = "true"
    }

    tags = ["gke-node"]
  }
}

# Output
output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Host"
  sensitive   = true
}
