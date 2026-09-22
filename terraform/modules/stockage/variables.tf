variable "project" { 
  type    = string
  default = "foodtrack-equipe-d"
}
variable "equipe" {
  type    = string
  default = "d"
}
variable "region" {
    type    = string
    default = "europe-west4"
}
variable "environment" {
  type        = string
  description = "Environnement (dev, test, prod)"
}