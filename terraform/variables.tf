variable "project" {
  type        = string
  description = "ID du projet GCP"
  default     = "form-gke-eleve04-42a1"
}

variable "region" {
  type    = string
  default = "europe-west4"
}

variable "zone" {
  type    = string
  default = "europe-west4-b"
}

variable "environment" {
  type        = string
  description = "Environnement (dev, test, prod)"
  default = "dev" # Évite que Trivy ne plante si aucune valeur n'est fournie
}

variable "equipe" {
  type    = string
  default = "d"
}
