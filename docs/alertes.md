
# Alertes FoodTrack

## Objectif

L'objectif des alertes est de détecter rapidement une indisponibilité
du portail FoodTrack et de prévenir l'équipe lorsqu'un problème apparaît.

## Condition de déclenchement

Une alerte a été configurée à partir de l'uptime check du portail
de production.

L'alerte se déclenche lorsque le contrôle de disponibilité échoue
pendant une durée de 2 minutes.

Cette durée permet d'éviter de déclencher immédiatement une alerte
pour une interruption très courte, tout en permettant de réagir rapidement
en cas d'indisponibilité réelle.

## Notification

Un canal de notification par email a été configuré dans Google Cloud Monitoring.

Lorsqu'une indisponibilité est détectée pendant la durée définie,
une notification est envoyée afin d'informer rapidement l'équipe.

## Justification du seuil

Une durée de 2 minutes a été choisie comme compromis entre réactivité
et limitation des fausses alertes.

Une interruption très courte peut être temporaire et ne nécessite pas
forcément une intervention immédiate.

En revanche, une indisponibilité qui se prolonge pendant plusieurs contrôles
peut indiquer un véritable incident et doit être signalée.

## État actuel

L'alerte de disponibilité du portail de production est configurée.

Elle repose sur l'uptime check du portail FoodTrack, utilise une durée
de déclenchement de 2 minutes et possède un canal de notification par email.
