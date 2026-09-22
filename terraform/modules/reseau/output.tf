output "network_name" {
  description = "Nom du réseau VPC"
  value       = google_compute_network.vpc.id
}

output "subnet_name" {
  description = "Nom du sous-réseau"
  value       = google_compute_subnetwork.subnet.id
}
output "pods_ip_name" { value = "k8s-pods" }
output "services_ip_name" { value = "k8s-services" }
output "bastion_tag" { value = "bastion-node" }
