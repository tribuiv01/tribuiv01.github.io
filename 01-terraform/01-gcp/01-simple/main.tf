provider "google" {
  project = "prj-tribvcloud"
  region  = "asia-southeast1"
  zone    = "asia-southeast1-a"
}

resource "google_compute_instance" "vm_instance" {
  name         = "demo-vm"
  machine_type = "e2-medium"

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = "apt-get update && apt-get install -y nginx"
  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_file)}"
  }

  tags = ["http-server"]

  # Thêm service account configuration
  service_account {
    # Sử dụng email của service account
    email  = google_service_account.vm_service_account.email
    
    # Định nghĩa các scopes cần thiết
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write"
    ]
  }
}

resource "google_compute_firewall" "default" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "22", "3000","8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_service_account" "vm_service_account" {
  account_id   = "vm-service-account"
  display_name = "Service Account for VM"
}
