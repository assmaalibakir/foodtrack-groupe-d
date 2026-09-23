# VPC principal sans sous-réseaux automatiques
resource "google_compute_network" "vpc" {
  name                    = "foodtrack-${var.equipe}-vpc"
  auto_create_subnetworks = false
}

# Subnet avec plages secondaires pour pods et services
resource "google_compute_subnetwork" "subnet" {
  name          = "foodtrack-${var.equipe}-subnet"
  ip_cidr_range = "10.0.0.0/20"
  region        = var.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name  = "k8s-pods"
    ip_cidr_range = "10.16.0.0/12"
  }

  secondary_ip_range {
    range_name  = "k8s-services"
    ip_cidr_range = "10.32.0.0/20"
  }
}

# Cloud Router & NAT pour la sortie internet des pods
resource "google_compute_router" "router" {
  name    = "foodtrack-${var.equipe}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "foodtrack-${var.equipe}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  nat_ip_allocate_option             = "AUTO_ONLY"
}

# Pare-feu restreint ciblant le tag du bastion
resource "google_compute_firewall" "allow_ssh_bastion" {
  name    = "foodtrack-${var.equipe}-bastion"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["bastion-node"]
  source_ranges = ["35.235.240.0/20"] # IAP GCP
}
