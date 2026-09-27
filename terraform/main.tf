terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Configuration du backend distant GCS (Bucket créé au préalable via gcloud)
  backend "gcs" {
    bucket = "foodtrack-d-tfstate-form-gke-eleve04-42a1"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone

  # Force l'utilisation d'endpoints REST sur IPv4 si nécessaire
  user_project_override = true
}

# --- Module Réseau ---
module "reseau" {
  source = "./modules/reseau"

  region = var.region
  equipe = var.equipe
}

# --- Module Stockage ---
module "stockage" {
  source = "./modules/stockage"

  project     = var.project
  region      = var.region
  environment = var.environment
  equipe      = var.equipe
}

# --- Module Compute (GKE & Bastion) ---
module "compute" {
  source = "./modules/compute"

  region           = var.region
  zone             = var.zone
  equipe           = var.equipe
  vpc_id           = module.reseau.vpc_id
  subnet_id        = module.reseau.subnet_id
  pods_ip_name     = module.reseau.pods_ip_name
  services_ip_name = module.reseau.services_ip_name
  bastion_tag      = module.reseau.bastion_tag
}

# --- Module wif-github ---
module "wif-github" {
  source = "./modules/wif-github"

  project      = var.project
  github_owner = "assmaalibakir"
  github_repo  = "foodtrack-groupe-d"
}