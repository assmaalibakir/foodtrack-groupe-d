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
    # Le nom du bucket est passé lors du 'terraform init -backend-config=...' ou renseigné ici
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

  region      = var.region
  equipe      = var.equipe
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

  region      = var.region
  zone        = var.zone
  equipe      = var.equipe
}

# --- Module wif-github ---
module "wif-github" {
  source = "./modules/wif-github"

  project      = var.project
  github_owner = "assmaalibakir"
  github_repo  = "foodtrack-groupe-d"
}