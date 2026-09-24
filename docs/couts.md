
# Analyse des coûts FoodTrack

## Objectif

L'objectif est d'identifier les principales ressources qui génèrent des coûts
et les actions permettant de réduire ces coûts.

## Ressources principales

Les principales ressources de l'infrastructure sont :

- Cluster GKE : `foodtrack-d-cluster`
- Node pool : `foodtrack-d-pool`
- Bastion : `foodtrack-d-bastion`
- Cloud NAT : `foodtrack-d-nat`
- Bucket de sauvegarde : `foodtrack-d-backup-dev`
- Bucket d'exports de logs : `foodtrack-d-logs-dev`
- Bucket Terraform : `foodtrack-d-tfstate-foodtrack-equipe-d`

## Configuration du node pool

Le node pool `foodtrack-d-pool` utilise actuellement les caractéristiques suivantes :

- Zone : `europe-west4-b`
- Type de machine : `e2-medium`
- Nombre de nœuds actuellement actifs : `4`
- Autoscaling : activé
- Nombre minimal de nœuds : `1`
- Nombre maximal de nœuds : `5`
- Type de disque : `pd-standard`
- Taille du disque : `50 Go` par nœud
- Nœuds privés : activés
- Mode de provisionnement : standard

Cette configuration permet d'adapter le nombre de nœuds à la charge du cluster
grâce à l'autoscaling.

Le choix de machines `e2-medium` permet d'utiliser des machines de taille modérée,
adaptées à un environnement de projet et de formation.

## Ressources permanentes

Certaines ressources peuvent continuer à générer des coûts même lorsqu'elles sont peu utilisées.

Il faut notamment surveiller :

- Les nœuds GKE lorsqu'ils restent actifs.
- Les disques persistants.
- Les Load Balancers.
- Le stockage dans les buckets.
- Cloud NAT.
- Les logs et les métriques conservés.

## Économies liées au node pool

L'autoscaling permet d'adapter automatiquement le nombre de nœuds entre 1 et 5
en fonction de la charge.

Cela permet d'éviter de conserver en permanence le nombre maximal de nœuds
lorsque l'application utilise peu de ressources.

Un script d'exploitation permet également de réduire le node pool lorsque
l'environnement n'est pas utilisé puis de le redémarrer lorsque cela est nécessaire.

Cette stratégie permet de réduire le temps pendant lequel les machines
du cluster restent actives inutilement.

## Réduction des coûts de stockage

Un script permet de supprimer les exports de logs de plus de 30 jours.

Cette limite permet d'éviter de conserver inutilement des fichiers anciens
dans Cloud Storage.

Les buckets de sauvegarde, de logs et de state Terraform doivent également être
surveillés afin d'éviter une augmentation inutile du volume de données stockées.

## Éléments pris en compte dans l'estimation

Les coûts de l'infrastructure dépendent principalement :

- Du nombre de nœuds GKE actifs.
- Du nombre d'heures d'utilisation des machines `e2-medium`.
- Des disques `pd-standard` de 50 Go associés aux nœuds.
- Du Load Balancer utilisé pour exposer l'application.
- De Cloud NAT.
- Du stockage Cloud Storage.
- Du volume de logs et de métriques générés.

Avec 4 nœuds actuellement actifs, la partie calcul du cluster représente
un poste de coût important.

L'autoscaling et l'arrêt des ressources lorsqu'elles ne sont pas nécessaires
permettent donc de limiter la consommation.

## État actuel

La configuration finale du node pool a été identifiée.

Le cluster utilise actuellement 4 nœuds `e2-medium` avec des disques
`pd-standard` de 50 Go par nœud et un autoscaling configuré entre 1 et 5 nœuds.

Les principales ressources générant des coûts ainsi que les pistes
d'optimisation ont été identifiées.

## Conclusion

Les principaux leviers de réduction des coûts sont :

- L'utilisation de l'autoscaling du node pool.
- La réduction du nombre de nœuds lorsque l'environnement est peu utilisé.
- L'arrêt des ressources lorsqu'elles ne sont pas nécessaires.
- La suppression régulière des anciens exports de logs.
- La surveillance du stockage et des ressources réseau.

Ces choix permettent de conserver une infrastructure fonctionnelle
tout en limitant les ressources consommées inutilement.
