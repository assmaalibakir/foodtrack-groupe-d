#!/bin/bash

# Arrete le script si une commande echoue
# -e : stoppe en cas d'erreur
# -u : stoppe si une variable inexistante est utilisee
# -o pipefail : detecte les erreurs dans les commandes avec des pipes
set -euo pipefail

# Nom du bucket contenant les exports de logs
BUCKET_NAME="foodtrack-d-logs-dev"

# Nombre de jours de conservation
RETENTION_DAYS=30

# Calcule la date limite
LIMIT_DATE=$(date -d "-${RETENTION_DAYS} days" +"%Y-%m-%d")

echo "Suppression des exports de logs anterieurs au ${LIMIT_DATE}"

# Recupere la liste des objets du bucket
OBJECTS=$(gcloud storage ls -l "gs://${BUCKET_NAME}/**" 2>/dev/null || true)

# Si le bucket est vide, le script se termine proprement
if [ -z "${OBJECTS}" ]; then
    echo "Aucun export de logs present dans le bucket."
    echo "Purge terminee"
    exit 0
fi

# Recherche les fichiers plus anciens que la date limite
echo "${OBJECTS}" | \
awk -v limit="${LIMIT_DATE}" '
{
    if ($2 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}/) {
        file_date = substr($2, 1, 10)

        if (file_date < limit) {
            print $3
        }
    }
}' | while read -r file
do
    if [ -n "${file}" ]; then
        echo "Suppression de : ${file}"
        gcloud storage rm "${file}"
    fi
done

echo "Purge terminee"