#!/bin/bash

# Arrete le script si une commande echoue
# -e : stoppe en cas d'erreur
# -u : stoppe si une variable inexistante est utilisee
# -o pipefail : detecte les erreurs dans les commandes avec des pipes
set -euo pipefail

# Nom du cluster GKE
CLUSTER_NAME="foodtrack-d-cluster"

# Nom du node pool
NODE_POOL_NAME="foodtrack-d-pool"

# Zone du cluster
ZONE="europe-west4-b"

# Action demandee : stop ou start
ACTION="${1:-}"

# Verifie qu'une action a bien ete fournie
if [[ -z "${ACTION}" ]]; then
    echo "Usage : $0 stop|start"
    exit 1
fi

# Arret du node pool
if [[ "${ACTION}" == "stop" ]]; then

    echo "Arret du node pool ${NODE_POOL_NAME}"

    gcloud container clusters resize "${CLUSTER_NAME}" \
        --node-pool="${NODE_POOL_NAME}" \
        --num-nodes=0 \
        --zone="${ZONE}" \
        --quiet

    echo "Node pool arrete"

# Redemarrage du node pool
elif [[ "${ACTION}" == "start" ]]; then

    echo "Redemarrage du node pool ${NODE_POOL_NAME}"

    gcloud container clusters resize "${CLUSTER_NAME}" \
        --node-pool="${NODE_POOL_NAME}" \
        --num-nodes=1 \
        --zone="${ZONE}" \
        --quiet

    echo "Node pool redemarre"

# Si l'action n'est ni stop ni start
else
    echo "Action invalide : ${ACTION}"
    echo "Utiliser : stop ou start"
    exit 1
fi