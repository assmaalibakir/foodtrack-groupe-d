## Objectif

L'objectif des alertes est de detecter rapidement une indisponibilite
du portail FoodTrack et de prevenir l'equipe lorsqu'un probleme apparait.

## Condition de declenchement

Une alerte sera configuree a partir de l'uptime check du portail
de production.

Elle devra se declencher lorsque le portail ne repond plus correctement
pendant une duree definie.

## Notification

Une notification par email sera configuree afin d'informer l'equipe
lorsqu'une indisponibilite est detectee.

## Justification du seuil

Le seuil et la duree seront choisis afin d'eviter de declencher une alerte
pour une coupure tres courte tout en permettant de reagir rapidement
en cas de panne reelle.

La valeur exacte sera definie et justifiee lorsque l'environnement
de production sera disponible.

## Etat actuel

A configurer lorsque l'uptime check et l'adresse publique
de foodtrack-prod seront disponibles.