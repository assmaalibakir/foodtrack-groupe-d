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

# Copie ici les fichiers de configuration a sauvegarder
# Cette partie sera completee quand le depot final sera pret
# Exemple :
# cp -r ../manifests "${BACKUP_DIR}/"
# cp -r ../terraform "${BACKUP_DIR}/"

# Cree une archive compressee avec le contenu du dossier temporaire
tar -czf "/tmp/${ARCHIVE_NAME}" -C "${BACKUP_DIR}" .

# Envoie l'archive dans le bucket Google Cloud Storage
gcloud storage cp "/tmp/${ARCHIVE_NAME}" "gs://${BUCKET_NAME}/"

# Affiche un message de confirmation
echo "Sauvegarde terminee : gs://${BUCKET_NAME}/${ARCHIVE_NAME}"

# Supprime les fichiers temporaires
rm -rf "${BACKUP_DIR}"
rm -f "/tmp/${ARCHIVE_NAME}"