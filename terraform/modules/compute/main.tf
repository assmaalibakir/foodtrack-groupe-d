# Cluster GKE (mode VPC natif et suppression du node pool par défaut)
resource "google_container_cluster" "primary" {
  name                     = "foodtrack-${var.equipe}-cluster"
  location                 = var.zone
  remove_default_node_pool = true
  initial_node_count       = 1

  # Permet de débloquer le 'terraform destroy'[cite: 10]
  deletion_protection = false

  network    = var.vpc_id
  subnetwork = var.subnet_id

  ip_allocation_policy {
    cluster_secondary_range_name  = "k8s-pods"
    services_secondary_range_name = "k8s-services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0" # À restreindre à votre IP / CIDR Bastion
      display_name = "Authorized-Access"
    }
  }
}

# Node Pool personnalisé (pd-standard + e2-medium)
resource "google_container_node_pool" "primary_nodes" {
  name       = "foodtrack-${var.equipe}-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    machine_type = "e2-medium"
    disk_type    = "pd-standard"
    disk_size_gb = 50

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# Bastion de petite taille
resource "google_compute_instance" "bastion" {
  name         = "foodtrack-${var.equipe}-bastion"
  machine_type = "e2-micro"
  zone         = var.zone

  tags = [var.bastion_tag]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = var.subnet_id
  }
}
