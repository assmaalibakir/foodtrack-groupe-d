variable "project" {
  type        = string
  description = "ID du projet GCP"
  default     = "foodtrack-equipe-d"
}

variable "region" {
  type        = string
  default     = "europe-west4"
}

variable "zone" {
  type        = string
  default     = "europe-west4-b"
}

variable "environment" {
  type        = string
  description = "Environnement (dev, test, prod)"
}
