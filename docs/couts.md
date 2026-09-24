
# Analyse des coûts FoodTrack

## Objectif

L'objectif de cette analyse est d'identifier les principales ressources
qui génèrent des coûts dans l'infrastructure FoodTrack et de proposer
des solutions permettant de limiter les dépenses inutiles.

## Cluster GKE

Le cluster utilisé est :

`foodtrack-d-cluster`

Il s'agit d'un cluster GKE Standard zonal situé dans la zone :

`europe-west4-b`

Le choix d'un cluster zonal permet de limiter les coûts par rapport
à une architecture régionale plus complexe.

En contrepartie, le cluster dépend d'une seule zone et offre donc
une résilience plus faible en cas d'indisponibilité complète de cette zone.

## Node pool

Le node pool utilisé est :

`foodtrack-d-pool`

Sa configuration observée est :

- Type de machine : `e2-medium`.
- Nombre actuel de nœuds : 4.
- Autoscaling : activé.
- Minimum : 1 nœud.
- Maximum : 5 nœuds.
- Type de disque : `pd-standard`.
- Taille du disque : 50 Go par nœud.
- Nœuds privés : activés.
- Provisionnement : standard.

## Justification du dimensionnement

Le type de machine `e2-medium` a été retenu car il fournit des ressources
suffisantes pour faire fonctionner l'application FoodTrack tout en limitant
le coût par rapport à des machines plus puissantes.

Les disques utilisés sont des disques persistants standards `pd-standard`
de 50 Go.

Ce type de disque est moins coûteux qu'un disque SSD et ses performances
sont suffisantes pour les besoins de ce projet.

## Autoscaling

L'autoscaling permet au node pool de varier entre :

- Minimum : 1 nœud.
- Maximum : 5 nœuds.

Ce mécanisme permet d'adapter les ressources à la charge.

Lorsque la charge augmente, des nœuds peuvent être ajoutés.

Lorsque la charge diminue, les ressources inutiles peuvent être supprimées,
ce qui permet de limiter les coûts.

## Extinction du node pool

Le script :

`scripts/cluster-schedule.sh`

permet de désactiver l'autoscaling puis de réduire le node pool à zéro
lorsque l'environnement n'est pas utilisé.

Lors du redémarrage, le script remet un nœud puis réactive l'autoscaling
entre 1 et 5 nœuds.

Ce choix permet de réduire les coûts pendant les périodes où
l'environnement de formation n'est pas utilisé.

## Estimation avec Google Cloud Pricing Calculator

Une estimation a été réalisée avec le Google Cloud Pricing Calculator
en utilisant les caractéristiques réelles du node pool.

Les paramètres utilisés sont :

| Paramètre              | Valeur                     | Justification                                                  |
| ----------------------- | -------------------------- | -------------------------------------------------------------- |
| Nombre d'instances      | 4                          | Le node pool possède actuellement 4 nœuds.                   |
| Famille                 | General Purpose            | Correspond à la famille utilisée par les machines E2.        |
| Série                  | E2                         | Série réellement utilisée par le node pool.                 |
| Type de machine         | `e2-medium`              | Type de machine réellement configuré.                        |
| Région                 | `europe-west4`           | Le cluster est situé dans la zone`europe-west4-b`.          |
| Provisionnement         | Regular                    | Les nœuds ne sont pas des instances Spot.                     |
| Système d'exploitation | Linux sans licence payante | Aucun coût de licence supplémentaire n'est nécessaire.      |
| Type de disque          | `pd-standard`            | Type de disque réellement utilisé.                           |
| Taille du disque        | 50 GiB par instance        | Taille réellement configurée sur le node pool.               |
| Réduction d'engagement | Aucune                     | Aucun engagement sur 1 ou 3 ans n'est utilisé pour ce projet. |

## Scénario 1 : fonctionnement continu

Le premier scénario représente les quatre nœuds fonctionnant en continu.

Temps d'utilisation :

`730 heures par mois et par instance`

Le Google Cloud Pricing Calculator fournit une estimation de :

`116,51 $ par mois`

Ce scénario représente le coût lorsque les nœuds restent disponibles
24 heures sur 24 pendant tout le mois.

## Scénario 2 : extinction nocturne

Le deuxième scénario conserve exactement la même infrastructure,
mais limite l'utilisation des quatre nœuds à :

`365 heures par mois et par instance`

Cela correspond approximativement à une utilisation de 12 heures par jour.

Le Google Cloud Pricing Calculator fournit alors une estimation de :

`58,25 $ par mois`

## Comparaison

| Scénario                    |                  Utilisation | Coût mensuel estimé |
| ---------------------------- | ---------------------------: | --------------------: |
| Fonctionnement continu       |                   730 h/mois |              116,51 $ |
| Extinction environ 12 h/jour |                   365 h/mois |               58,25 $ |
| Économie estimée           | 365 h évitées par instance |               58,26 $ |

L'économie estimée est donc :

`116,51 $ - 58,25 $ = 58,26 $ par mois`

Dans cette simulation, l'extinction du node pool pendant environ
12 heures par jour permet donc de réduire d'environ 50 % le coût
estimé des ressources de calcul configurées dans le simulateur.

## Coûts restant possibles

L'extinction du node pool ne signifie pas que toute l'infrastructure
devient gratuite.

Certaines ressources peuvent continuer à générer des coûts :

- Les volumes persistants.
- Les équilibreurs de charge.
- Certaines adresses IP.
- Cloud Storage.
- Le trafic réseau.
- Les ressources conservées en dehors du node pool.

L'économie calculée ne doit donc pas être interprétée comme une réduction
de 50 % de la facture Google Cloud totale.

## Stockage et sauvegardes

Le projet utilise notamment les buckets :

- `foodtrack-d-backup-dev`
- `foodtrack-d-logs-dev`
- `foodtrack-d-tfstate-foodtrack-equipe-d`

Le stockage est facturé en fonction du volume de données conservé.

Le script :

`scripts/purge-old-logs.sh`

permet de supprimer les exports de logs datant de plus de 30 jours.

Cette politique évite de conserver inutilement des journaux anciens
et permet de limiter progressivement le coût du stockage.

## Sauvegardes

Le script :

`scripts/backup-config.sh`

crée une archive horodatée des fichiers de configuration et l'envoie
dans le bucket Cloud Storage dédié.

Les fichiers de configuration représentent un volume relativement faible,
ce qui limite le coût de ces sauvegardes.

## Principaux postes de coût

Les principaux postes de coût identifiés sont :

- Les machines du node pool GKE.
- Les disques persistants.
- Les équilibreurs de charge.
- Les adresses IP.
- Cloud Storage.
- Le trafic réseau.

## Optimisations retenues

Plusieurs choix permettent de limiter les coûts :

- Utilisation de machines `e2-medium`.
- Utilisation de disques `pd-standard`.
- Limitation des disques à 50 Go.
- Autoscaling du node pool.
- Extinction du node pool lorsqu'il n'est pas utilisé.
- Purge des anciens exports de logs.
- Utilisation d'un seul cluster pour les trois environnements.

## Conclusion

Le principal coût variable de l'infrastructure provient des nœuds GKE.

Le Google Cloud Pricing Calculator estime le fonctionnement continu
des quatre nœuds à environ 116,51 $ par mois.

En limitant leur fonctionnement à environ 12 heures par jour,
l'estimation descend à 58,25 $ par mois.

L'extinction nocturne permet donc une économie estimée à 58,26 $ par mois
sur les ressources simulées.

Cette estimation permet de justifier l'intérêt du script d'extinction
du node pool et montre l'impact concret d'une optimisation des périodes
de fonctionnement de l'infrastructure.
