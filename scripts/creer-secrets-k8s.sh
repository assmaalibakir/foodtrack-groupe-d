#!/usr/bin/env bash
set -Eeuo pipefail

ENVIRONMENT="${1:?Usage : creer-secrets-k8s.sh dev|test|prod}"

case "$ENVIRONMENT" in
  dev|test|prod) ;;
  *)
    echo "Environnement invalide : $ENVIRONMENT" >&2
    exit 1
    ;;
esac

: "${INGEST_TOKEN:?La variable INGEST_TOKEN est obligatoire}"
: "${CACHE_PASSWORD:?La variable CACHE_PASSWORD est obligatoire}"

NAMESPACE="foodtrack-${ENVIRONMENT}"

kubectl get namespace "$NAMESPACE" > /dev/null

kubectl create secret generic foodtrack-api-config \
  --namespace "$NAMESPACE" \
  --from-literal=INGEST_TOKEN="$INGEST_TOKEN" \
  --from-literal=CACHE_PASSWORD="$CACHE_PASSWORD" \
  --dry-run=client \
  --output yaml |
kubectl apply -f -

kubectl rollout restart deployment/api-capteurs \
  --namespace "$NAMESPACE"

kubectl rollout restart statefulset/cache-releves \
  --namespace "$NAMESPACE"

kubectl rollout status deployment/api-capteurs \
  --namespace "$NAMESPACE" \
  --timeout=180s

kubectl rollout status statefulset/cache-releves \
  --namespace "$NAMESPACE" \
  --timeout=180s

echo "Secret appliqué dans $NAMESPACE"
