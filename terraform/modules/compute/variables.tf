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
variable "vpc_id" { type = string }
variable "subnet_id" { type = string }
variable "pods_ip_name" { type = string }
variable "services_ip_name" { type = string }
variable "bastion_tag" { type = string }
