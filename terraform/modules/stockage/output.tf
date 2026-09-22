output "artifact_repository_id" {
  description = "Identifiant du dépôt Artifact Registry"
  value       = google_artifact_registry_repository.docker_repo.id
}

output "artifact_repository_url" {
  description = "URL complète du dépôt Docker pour le push/pull d'images"
  value       = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.docker_repo.repository_id}"
}

output "backup_bucket_name" {
  description = "Nom du bucket de sauvegarde"
  value       = google_storage_bucket.backup.name
}

output "logs_bucket_name" {
  description = "Nom du bucket d'export de journaux"
  value       = google_storage_bucket.logs_export.name
}
