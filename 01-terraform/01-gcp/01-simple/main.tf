provider "google" {
  project = "prj-tribvcloud"
  region  = "asia-southeast1"
  zone    = "asia-southeast1-a"
}

resource "google_compute_instance" "vm_instance" {
  name         = "demo-vm"
  machine_type = "e2-medium"

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
}

resource "google_compute_firewall" "default" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "22", "3000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}
