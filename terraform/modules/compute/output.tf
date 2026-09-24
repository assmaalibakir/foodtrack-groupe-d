output "kubernetes_cluster_name" {
  description = "Nom du cluster"
  value       = google_container_cluster.primary.name
}

output "kubernetes_cluster_endpoint" {
  description = "IP du plan de contrôle (Master) du cluster GKE"
  value       = google_container_cluster.primary.endpoint
}

output "bastion_ip" {
  description = "IP interne de la VM Bastion"
  value       = google_compute_instance.bastion.network_interface[0].network_ip
}
