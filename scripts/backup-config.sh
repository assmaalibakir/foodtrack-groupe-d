#!/bin/bash

# Arrete le script si une commande echoue
# -e : stoppe en cas d'erreur
# -u : stoppe si une variable inexistante est utilisee
# -o pipefail : detecte les erreurs dans les commandes avec des pipes
set -euo pipefail

# Nom du bucket de sauvegarde
BUCKET_NAME="foodtrack-d-backup-dev"

# Dossier temporaire utilise pour preparer la sauvegarde
BACKUP_DIR="/tmp/foodtrack-backup"

# Date et heure utilisees dans le nom de l'archive
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# Nom final de l'archive
ARCHIVE_NAME="foodtrack-config-${TIMESTAMP}.tar.gz"

# Supprime un ancien dossier temporaire s'il existe deja
rm -rf "${BACKUP_DIR}"

# Cree le dossier temporaire
mkdir -p "${BACKUP_DIR}"

# Sauvegarde les fichiers Kubernetes
if [ -d "k8s" ]; then
    cp -r k8s "${BACKUP_DIR}/"
fi

# Sauvegarde les fichiers Terraform
if [ -d "terraform" ]; then
    cp -r terraform "${BACKUP_DIR}/"
fi

# Sauvegarde les fichiers de documentation
if [ -d "docs" ]; then
    cp -r docs "${BACKUP_DIR}/"
fi

# Cree une archive compressee avec les fichiers sauvegardes
tar -czf "/tmp/${ARCHIVE_NAME}" -C "${BACKUP_DIR}" .

# Envoie l'archive dans le bucket Google Cloud Storage
gcloud storage cp "/tmp/${ARCHIVE_NAME}" "gs://${BUCKET_NAME}/"

# Affiche un message de confirmation
echo "Sauvegarde terminee : gs://${BUCKET_NAME}/${ARCHIVE_NAME}"

# Supprime les fichiers temporaires
rm -rf "${BACKUP_DIR}"
rm -f "/tmp/${ARCHIVE_NAME}"