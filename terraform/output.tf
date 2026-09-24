# --- Outputs Réseau ---
output "vpc_id" {
  description = "Nom du réseau VPC principal"
  value       = module.reseau.vpc_id
}

output "subnet_id" {
  description = "ID du sous-réseau principal"
  value       = module.reseau.subnet_id
}

# --- Outputs Compute / GKE ---
output "gke_cluster_name" {
  description = "Nom du cluster Kubernetes (GKE)"
  value       = module.compute.kubernetes_cluster_name
}

output "gke_cluster_endpoint" {
  description = "IP publique/interne de l'API Server GKE"
  value       = module.compute.kubernetes_cluster_endpoint
  sensitive   = true 
}

output "bastion_ip" {
  description = "Adresse IP interne de la VM Bastion"
  value       = module.compute.bastion_ip
}

# --- Outputs Stockage ---
output "backup_bucket_name" {
  description = "Nom du bucket de sauvegarde"
  value       = module.stockage.backup_bucket_name
}

output "logs_bucket_name" {
  description = "Nom du bucket d'export de journaux"
  value       = module.stockage.logs_bucket_name
}

# --- Outputs Wif-github ---
output "wif_provider_name" {
  description = "Nom complet du fournisseur OIDC. A copier dans la variable GitHub WIF_PROVIDER"
  value       = module.wif-github.wif_provider_name
}

output "ci_service_account_email" {
  description = "Adresse du compte de service du pipeline. A copier dans la variable GitHub CI_SERVICE_ACCOUNT"
  value       = module.wif-github.ci_service_account_email
}

output "principal_set" {
  description = "Identite federee autorisee a emprunter le compte de service. Utile pour diagnostiquer un refus d echange de jeton"
  value       = module.wif-github.principal_set
}

output "project_number" {
  description = "Numero du projet, present dans le nom du pool et dans les messages d erreur IAM"
  value       = module.wif-github.project_number
}