#!/usr/bin/env bash
# Arrete le script sur une erreur, une variable absente ou un pipe en echec.
set -Eeuo pipefail

# Le premier argument designe l'environnement cible.
ENVIRONMENT="${1:?Usage : creer-secrets-k8s.sh dev|test|prod}"

# Refuse toute valeur autre que les trois environnements connus.
case "$ENVIRONMENT" in
  dev|test|prod) ;;
  *)
    echo "Environnement invalide : $ENVIRONMENT" >&2
    exit 1
    ;;
esac

# Les valeurs sensibles doivent etre fournies par la session appelante.
: "${INGEST_TOKEN:?La variable INGEST_TOKEN est obligatoire}"
: "${CACHE_PASSWORD:?La variable CACHE_PASSWORD est obligatoire}"

# Le namespace est construit a partir de l'environnement valide.
NAMESPACE="foodtrack-${ENVIRONMENT}"

# Verifie que le namespace existe avant de creer le Secret.
kubectl get namespace "$NAMESPACE" > /dev/null

# Genere le manifeste en memoire puis l'applique sans l'enregistrer sur disque.
kubectl create secret generic foodtrack-api-config \
  --namespace "$NAMESPACE" \
  --from-literal=INGEST_TOKEN="$INGEST_TOKEN" \
  --from-literal=CACHE_PASSWORD="$CACHE_PASSWORD" \
  --dry-run=client \
  --output yaml |
kubectl apply -f -

# Redemarre les workloads qui consomment les valeurs du Secret.
kubectl rollout restart deployment/api-capteurs \
  --namespace "$NAMESPACE"

kubectl rollout restart statefulset/cache-releves \
  --namespace "$NAMESPACE"

# Attend la fin des deux redemarrages avant de confirmer le succes.
kubectl rollout status deployment/api-capteurs \
  --namespace "$NAMESPACE" \
  --timeout=180s

kubectl rollout status statefulset/cache-releves \
  --namespace "$NAMESPACE" \
  --timeout=180s

echo "Secret appliqué dans $NAMESPACE"
