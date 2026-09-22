# Artifact Registry pour Docker dans la même région
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "foodtrack-${var.equipe}-images"
  description   = "Dépôt d'images Docker"
  format        = "DOCKER"
}

# Buckets de sauvegarde et d'exports de journaux
resource "google_storage_bucket" "backup" {
  Name                     = "foodtrack-${var.equipe}-backup-${var.environment}"
  location                 = var.region
  force_destroy            = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "logs_export" {
  name                     = "foodtrack-${var.equipe}-logs-${var.environment}"
  location                 = var.region
  force_destroy            = true
  uniform_bucket_level_access = true
}
