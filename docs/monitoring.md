
# Monitoring FoodTrack

## Objectif

L'objectif du monitoring est de surveiller l'état de l'application FoodTrack
et de son environnement de production.

La supervision doit permettre de détecter rapidement un problème de performance,
une indisponibilité ou un dysfonctionnement de l'application.

## Métriques surveillées

Le dashboard de supervision permet de suivre les principales métriques
de l'environnement `foodtrack-prod` :

- Utilisation CPU.
- Utilisation mémoire.
- Nombre de pods prêts.
- Erreurs HTTP.
- Latence des requêtes HTTP.

## Dashboard

Un dashboard de supervision a été créé dans Google Cloud Monitoring.

Il permet de visualiser :

- L'utilisation CPU.
- L'utilisation mémoire.
- Le nombre de pods prêts.
- Les erreurs HTTP.
- La latence des requêtes HTTP.

Les métriques CPU et mémoire sont filtrées sur le namespace `foodtrack-prod`.

Le graphique des pods prêts permet de vérifier que les composants de production
sont disponibles.

La valeur observée est de 5 lorsque tous les composants sont disponibles :
2 pods API, 2 pods portail et 1 pod cache.

Le graphique des erreurs HTTP permet de surveiller les erreurs rencontrées
par le portail.

Le graphique de latence permet de surveiller le temps de réponse
des requêtes HTTP.

## Uptime check

Un test de disponibilité a été configuré sur l'adresse publique
du portail de production :

`http://34.54.176.240`

Le test utilise l'endpoint `/healthz`.

Il permet de vérifier régulièrement que le portail répond correctement.

## Logs

Une requête de logs a été créée pour retrouver les erreurs
du namespace `foodtrack-prod`.

La requête utilisée est :

```text
resource.type="k8s_container"
resource.labels.namespace_name="foodtrack-prod"
severity>=ERROR
```

Cette requête a été enregistrée dans Google Cloud Logging.

Elle permet de retrouver rapidement les erreurs en cas de problème.

## État actuel

Le monitoring de l'environnement `foodtrack-prod` est configuré.

Le dashboard, l'uptime check et la requête de logs sont opérationnels.
