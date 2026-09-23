
# Analyse des coûts FoodTrack

## Objectif

L'objectif est d'identifier les principales ressources qui génèrent des coûts et les actions permettant de réduire ces coûts

## Ressources principales

Les principales ressources de l'infrastructure sont :

- Cluster GKE : `foodtrack-d-cluster`
- Node pool : `foodtrack-d-pool`
- Bastion : `foodtrack-d-bastion`
- Cloud NAT : `foodtrack-d-nat`
- Bucket de sauvegarde : `foodtrack-d-backup-dev`
- Bucket d'exports de logs : `foodtrack-d-logs-dev`
- Bucket Terraform : `foodtrack-d-tfstate-foodtrack-equipe-d`

## Ressources permanentes

Certaines ressources peuvent continuer à générer des coûts même lorsqu'elles sont peu utilisées.

Il faut notamment surveiller :

- Les nœuds GKE lorsqu'ils restent actifs
- Les disques persistants
- Les Load Balancers
- Le stockage dans les buckets
- Les logs et les métriques conservé

## Économies liées à l'arrêt du node pool

Un script permet de réduire le node pool à zéro lorsque l'environnement n'est pas utilisé puis de le redémarrer lorsque cela est nécessaire. Cela permettrait d'éviter de laisser les machines du cluster actives inutilement.

## Réduction des coûts de stockage

Un script supprime les exports de logs de plus de 30 jours.

Cette limite permet d'éviter de conserver inutilement des fichiers anciens dans Cloud Storage.

## Estimation des coûts

L'estimation exacte sera réalisée lorsque les caractéristiques finales des ressources seront connues.

Il faudra notamment prendre en compte :

- Le type et le nombre de nœuds GKE
- Le nombre d'heures d'utilisation
- Les disques utilisés
- Les Load Balancers
- Le stockage Cloud Storage
- Cloud NAT
- Les logs et les métriques

## État actuel

Les principales ressources à analyser ont été identifiées.

Le montant précis reste à calculer lorsque la configuration finale de l'infrastructure sera disponible.

## Conclusion

Les principales pistes de réduction des coûts sont l'arrêt du node pool lorsqu'il n'est pas utilisé et la suppression régulière des anciens exports de logs.
