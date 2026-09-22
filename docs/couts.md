# Analyse des couts FoodTrack

## Objectif

L'objectif de cette partie est d'analyser les couts generes par l'infrastructure FoodTrack et d'identifier les ressources qui consomment le plus de budget. Cette analyse permettra egalement de mettre en place des actions pour reduire les couts lorsque les environnements ne sont pas utilises

## Ressources principales

Les principales ressources pouvant generer des couts dans le projet sont :

- Le cluster GKE et ses noeuds.
- Les disques persistants utilises par les applications.
- Les Load Balancers utilises pour exposer les services.
- Les buckets Cloud Storage.
- Artifact Registry pour le stockage des images Docker.
- Cloud NAT pour permettre aux noeuds prives d'acceder a Internet.
- Les logs et les metriques de supervision.

## Ressources permanentes

Les ressources permanentes sont celles qui peuvent continuer a generer des couts meme lorsqu'elles sont peu utilisees.

Dans le projet FoodTrack, il faudra notamment surveiller :

- Les noeuds du cluster GKE lorsqu'ils restent actifs.
- Les disques persistants encore presents.
- Les Load Balancers encore provisionnes.
- Les adresses IP reservees.
- Certaines ressources de stockage conservees dans le temps.

## Ressources liees a l'utilisation

Les ressources liees a l'utilisation sont facturees en fonction de leur consommation ou de leur activite.

Dans le projet FoodTrack, cela peut concerner :

- Le trafic reseau.
- L'utilisation de Cloud NAT.
- Le volume de logs et de metriques genere.
- Le stockage des images Docker dans Artifact Registry.
- Le stockage des sauvegardes et des exports de logs.

## Economies liees a l'arret nocturne

L'arret nocturne du node pool permet de reduire les couts lorsque l'environnement n'est pas utilise.

Le principe consiste a reduire le nombre de noeuds a zero pendant la nuit, puis a les redemarrer le matin.

Cette methode permet d'eviter de payer inutilement des machines virtuelles pendant les periodes d'inactivite.

Le gain financier exact sera calcule plus tard a partir du cout reel du node pool et du nombre d'heures d'arret par jour.

## Estimation des couts

L'estimation des couts sera realisee lorsque l'infrastructure FoodTrack sera completement deployee.

Les couts seront verifies a l'aide :

- Du calculateur officiel Google Cloud.
- Des rapports de facturation du projet.
- Du nombre et du type de noeuds GKE utilises.
- Du nombre d'heures pendant lesquelles les noeuds restent actifs.
- Des ressources de stockage utilisees.
- Des Load Balancers presents.
- De l'utilisation du reseau, des logs et des metriques.

Le cout avec et sans arret nocturne du node pool sera compare afin de quantifier les economies realisees.

### Etat actuel

A completer lorsque l'infrastructure et les donnees de facturation seront disponibles.

## Conclusion

A completer apres l'analyse des couts reels du projet.