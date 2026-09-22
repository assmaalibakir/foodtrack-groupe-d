# Monitoring FoodTrack

## Objectif

L'objectif du monitoring est de surveiller l'etat de l'application FoodTrack
et de son environnement de production.

La supervision doit permettre de detecter rapidement un probleme de performance,
une indisponibilite ou un dysfonctionnement de l'application.

## Metriques a surveiller

Le dashboard de supervision devra afficher au minimum les metriques suivantes
pour l'environnement de production :

- Utilisation CPU.
- Utilisation memoire.
- Nombre de pods prets.
- Taux d'erreurs HTTP.
- Latence des requetes HTTP.

Ces metriques permettront de verifier a la fois l'etat de l'infrastructure
et le bon fonctionnement de l'application.

## Dashboard

Un dashboard de supervision sera cree dans Google Cloud Monitoring afin de
centraliser les principales metriques de l'environnement de production.

Il devra permettre de visualiser rapidement :

- L'utilisation CPU.
- L'utilisation memoire.
- Le nombre de pods prets.
- Le taux d'erreurs HTTP.
- La latence des requetes HTTP.

Le dashboard sera complete lorsque l'application FoodTrack sera deployee
et que les metriques seront disponibles dans Google Cloud Monitoring.

### Etat actuel

A configurer lorsque l'environnement foodtrack-prod sera disponible.

## Uptime check

Un controle de disponibilite sera configure sur l'adresse publique
du portail de production FoodTrack.

Ce controle permettra de verifier regulierement que le portail
repond correctement et reste accessible.

L'uptime check servira egalement de base pour declencher une alerte
si le portail ne repond plus.

### Etat actuel

A configurer lorsque l'adresse publique de foodtrack-prod sera disponible.

## Logs

Une requete de logs sera preparee afin d'isoler les erreurs
de l'application dans le namespace concerne.

Cette requete permettra de retrouver plus rapidement les messages
d'erreur lorsqu'un probleme apparait dans l'application.

La requete sera enregistree dans Google Cloud Logging
afin de pouvoir etre reutilisee facilement.

### Etat actuel

A configurer lorsque les logs de l'application FoodTrack seront disponibles.

## Etat actuel