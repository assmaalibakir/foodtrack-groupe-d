#!/bin/bash

# Arrete le script si une commande echoue
set -euo pipefail

# Configuration du cluster
CLUSTER_NAME="foodtrack-d-cluster"
NODE_POOL_NAME="foodtrack-d-pool"
ZONE="europe-west4-b"

# Configuration normale de l'autoscaling
MIN_NODES=1
MAX_NODES=5

# Action demandee : stop ou start
ACTION="${1:-}"

if [[ -z "${ACTION}" ]]; then
    echo "Usage : $0 stop|start"
    exit 1
fi

if [[ "${ACTION}" == "stop" ]]; then

    echo "Desactivation de l'autoscaling"

    gcloud container clusters update "${CLUSTER_NAME}" \
        --node-pool="${NODE_POOL_NAME}" \
        --no-enable-autoscaling \
        --zone="${ZONE}" \
        --quiet

    echo "Reduction du node pool a 0"

    gcloud container clusters resize "${CLUSTER_NAME}" \
        --node-pool="${NODE_POOL_NAME}" \
        --num-nodes=0 \
        --zone="${ZONE}" \
        --quiet

    echo "Node pool arrete"

elif [[ "${ACTION}" == "start" ]]; then

    echo "Redemarrage du node pool avec 1 noeud"

    gcloud container clusters resize "${CLUSTER_NAME}" \
        --node-pool="${NODE_POOL_NAME}" \
        --num-nodes=1 \
        --zone="${ZONE}" \
        --quiet

    echo "Reactivation de l'autoscaling"

    gcloud container clusters update "${CLUSTER_NAME}" \
        --node-pool="${NODE_POOL_NAME}" \
        --enable-autoscaling \
        --min-nodes="${MIN_NODES}" \
        --max-nodes="${MAX_NODES}" \
        --zone="${ZONE}" \
        --quiet

    echo "Node pool redemarre"
    echo "Autoscaling actif : ${MIN_NODES} a ${MAX_NODES} noeuds"

else

    echo "Action invalide : ${ACTION}"
    echo "Utiliser : stop ou start"
    exit 1

fi