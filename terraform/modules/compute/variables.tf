variable "project" { 
  type    = string
  default = "form-gke-eleve04-42a1"
}
variable "equipe" {
  type    = string
  default = "d"
}
variable "region" {
  type    = string
  default = "europe-west4"
}
variable "zone" {
  type    = string
  default = "europe-west4-b"
}
variable "vpc_id" {
  type    = string
  default = "foodtrack-d-vpc"
}
variable "subnet_id" {
  type    = string
  default = "foodtrack-d-subnet"
}
variable "pods_ip_name" {
  type    = string
  default = "k8s-pods"
}
variable "services_ip_name" {
  type    = string
  default = "k8s-services"
}
variable "bastion_tag" {
  type    = string
  default = "foodtrack-d-bastion"
}
