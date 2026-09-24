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
- Taux d'erreurs HTTP.
- Latence des requêtes HTTP.

## Dashboard

Un dashboard de supervision a été créé dans Google Cloud Monitoring.

Il permet de visualiser :

- L'utilisation CPU.
- L'utilisation mémoire.
- Le nombre de pods prêts.
- Le taux d'erreurs HTTP.
- La latence des requêtes HTTP.

Les métriques CPU et mémoire sont filtrées sur le namespace `foodtrack-prod`.

Le graphique des pods prêts permet de vérifier que les composants de production
sont disponibles.

La valeur observée est de 5 lorsque tous les composants sont disponibles :
2 pods API, 2 pods portail et 1 pod cache.

## Taux d'erreurs HTTP

Le taux d'erreurs HTTP permet de mesurer la proportion de requêtes en erreur
par rapport au nombre total de requêtes reçues par l'application.

Ce suivi permet de détecter rapidement une dégradation du portail,
même lorsque celui-ci reste accessible.

Le taux est calculé à partir de deux requêtes sur la métrique
`Request count` du load balancer :

- Requête A : nombre de réponses HTTP 4xx.
- Requête B : nombre total de requêtes HTTP.

Le ratio utilisé est :

`A / B`

Le résultat est affiché en pourcentage dans le dashboard.

## Latence HTTP

Le graphique de latence permet de surveiller le temps de réponse
des requêtes HTTP.

Cette métrique permet de détecter un ralentissement du portail
même lorsque celui-ci reste disponible.

## Uptime check

Un test de disponibilité a été configuré sur l'adresse publique
du portail de production :

`http://34.54.176.240`

Le test utilise l'endpoint `/healthz`.

Il permet de vérifier régulièrement que le portail répond correctement.

## Alertes

Une alerte de disponibilité est associée à l'uptime check.

Elle se déclenche lorsque le portail reste indisponible pendant 2 minutes.

Cette durée permet d'éviter les alertes provoquées par une interruption
très courte tout en conservant une détection rapide d'un incident réel.

Un canal de notification par email est configuré afin de prévenir
rapidement l'équipe.

## Logs

Une requête de logs a été créée pour retrouver les erreurs
du namespace `foodtrack-prod`.

La requête utilisée est :

```text
resource.type="k8s_container"
resource.labels.namespace_name="foodtrack-prod"
severity>=ERROR
```

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
