#!/bin/bash

# Arrete le script si une commande echoue
# -e : stoppe en cas d'erreur
# -u : stoppe si une variable inexistante est utilisee
# -o pipefail : detecte les erreurs dans les commandes avec des pipes
set -euo pipefail

# Nom du bucket contenant les exports de logs
# Cette valeur sera remplacee quand le vrai bucket sera connu
BUCKET_NAME="A_REMPLACER"

# Nombre de jours de conservation
RETENTION_DAYS=30

# Calcule la date limite
# Les fichiers plus anciens que cette date pourront etre supprimes
LIMIT_DATE=$(date -d "-${RETENTION_DAYS} days" +"%Y-%m-%d")

# Affiche la date limite utilisee
echo "Suppression des exports de logs anterieurs au ${LIMIT_DATE}"

# Liste les objets du bucket avec leur date
# Puis filtre ceux qui sont plus anciens que la date limite
gcloud storage ls -l "gs://${BUCKET_NAME}/**" | \
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
    # Supprime chaque fichier trop ancien
    echo "Suppression de : ${file}"
    gcloud storage rm "${file}"
done

# Affiche un message de fin
echo "Purge terminee"