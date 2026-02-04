terraform {
    required_providers{
        google = {
            source = "hashicorp/google"
            version = "6.8.0"
        }
    }
}

provider "google" {
    credentials = file("terraform.json")
    project = "lab1-486208" 
    region  = "us-central1"
    zone    = "us-central1-a"
}
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
resource "google_compute_instance" "vm_instance" {
    name = "terraform-lab1"
    machine_type = "e2-micro"
    zone         = "us-central1-a"


    boot_disk {
        initialize_params {
            image = "ubuntu-2204-lts"
	    size = 15
        }
    }
    network_interface{
        network = google_compute_network.vpc_network.name
        access_config {
        
        }
    }
    metadata = {
	ssh-keys = "ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtwldK8t4M3QE/qKaBb2/xIN8hIfIgPC1dL/rt2K5tV"
	}
}

resource "google_compute_firewall" "default" {
    name = "firewall-rule"
    network = google_compute_network.vpc_network.name 
    
    allow {
        protocol = "icmp"
    }
    
    allow {
        protocol = "tcp"
        ports = ["22", "80", "8080", "5432"]
    }
    source_ranges = ["0.0.0.0/0"]
}
