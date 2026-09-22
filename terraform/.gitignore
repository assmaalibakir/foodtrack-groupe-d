# --- Outputs Réseau ---
output "vpc_name" {
  description = "Nom du réseau VPC principal"
  value       = module.reseau.network_name
}

# --- Outputs Compute / GKE ---
output "gke_cluster_name" {
  description = "Nom du cluster Kubernetes (GKE)"
  value       = module.compute.kubernetes_cluster_name
}

output "gke_cluster_endpoint" {
  description = "IP publique/interne de l'API Server GKE"
  value       = module.compute.kubernetes_cluster_endpoint
  sensitive   = true # Masque l'IP dans les logs de sortie si souhaité
}

output "bastion_ip" {
  description = "Adresse IP interne de la VM Bastion"
  value       = module.compute.bastion_ip
}

# --- Outputs Stockage ---
output "storage_bucket_name" {
  description = "Nom du bucket GCS applicatif créé"
  value       = module.stockage.bucket_name
}
