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
variable "environment" {
  type        = string
  description = "Environnement (dev, test, prod)"
}