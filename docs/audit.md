
# Audit de sécurité

## Objectif

L'objectif de cet audit est de vérifier les principaux éléments de sécurité
de l'infrastructure FoodTrack.

Les contrôles portent notamment sur les comptes de service, les rôles IAM,
le pare-feu, le bastion, le plan de contrôle GKE, les secrets et les images.

## IAM et authentification

### Constat

Le compte de service suivant est utilisé par le projet :

`foodtrack-ci@form-gke-eleve04-42a1.iam.gserviceaccount.com`

Les rôles observés sont :

- `roles/artifactregistry.writer`
- `roles/container.developer`

Ce compte est utilisé par le pipeline CI/CD avec Workload Identity Federation.

La configuration du node pool GKE a également permis de vérifier que
`foodtrack-ci` est utilisé par les nœuds du cluster.

Le même compte de service est donc utilisé pour deux usages différents :

- Le pipeline CI/CD.
- Les nœuds GKE.

Cette configuration fonctionne, mais elle ne sépare pas complètement
les permissions selon les usages.

Une amélioration serait de créer un compte de service dédié aux nœuds GKE
avec uniquement les permissions nécessaires à leur fonctionnement.

Le compte Compute Engine par défaut existe également dans le projet et possède
le rôle `Editor`.

Il n'est cependant pas le compte de service attaché au node pool observé.

### Résultat

À améliorer : séparer le compte utilisé par la CI/CD de celui utilisé par
les nœuds GKE afin de mieux respecter le principe du moindre privilège.

Le rôle `Editor` du compte Compute Engine par défaut reste également un point
à surveiller car il donne des permissions très larges.

## Workload Identity Federation

### Constat

L'authentification entre GitHub Actions et Google Cloud utilise
Workload Identity Federation.

Le pool utilisé est :

`github-pool-dev`

Il est restreint au dépôt :

`assmaalibakir/foodtrack-groupe-d`

Aucune clé JSON permanente de compte de service n'est stockée dans le dépôt
ou dans GitHub Actions.

### Résultat

Conforme : l'authentification du pipeline utilise des jetons temporaires
et ne repose pas sur une clé JSON permanente.

## Pare-feu

### Constat

Une règle de pare-feu permet l'accès SSH au bastion.

- Port : `22`
- Protocole : TCP
- Source autorisée : `35.235.240.0/20`
- Cible : `bastion-node`

L'accès SSH n'est pas ouvert à `0.0.0.0/0`.

### Résultat

Conforme : l'accès SSH au bastion est limité à une plage réseau précise.

## Bastion

### Constat

Le bastion utilisé dans le projet est :

`foodtrack-d-bastion`

L'accès SSH est limité par la règle de pare-feu.

L'authentification par mot de passe a été désactivée afin de conserver
un accès sécurisé par clé SSH.

### Résultat

Conforme : l'accès SSH au bastion est restreint et l'authentification
par mot de passe est désactivée.

## Plan de contrôle GKE

### Constat

Le plan de contrôle GKE reste accessible depuis :

`0.0.0.0/0`

Cette configuration a été détectée par Trivy avec la règle :

`GCP-0053`

La restriction par adresse IP n'a pas été conservée car les runners
GitHub Actions utilisent des adresses IP dynamiques qui peuvent changer
à chaque exécution du pipeline.

La sécurité de l'accès repose donc principalement sur IAM et
Workload Identity Federation.

Cette exception est documentée directement dans le code Terraform avec :

`# trivy:ignore:GCP-0053`

### Résultat

Exception documentée : le plan de contrôle reste exposé publiquement,
mais son utilisation nécessite une authentification IAM/WIF.

Ce choix augmente l'exposition réseau et constitue un compromis lié
au fonctionnement du pipeline CI/CD.

## Scan de sécurité Terraform

### Constat

Un scan Trivy est exécuté sur le code Terraform dans le job `qualite`
du pipeline CI/CD.

Trois problèmes de niveau HIGH ont été détectés dans
`modules/compute/main.tf`.

### GCP-0048

Les anciens endpoints de métadonnées étaient activés.

Correction appliquée :

`disable-legacy-endpoints = "true"`

### GCP-0057

La configuration des métadonnées des nœuds n'était pas suffisamment sécurisée.

Correction appliquée :

```text
workload_metadata_config {
  mode = "GKE_METADATA"
}
```

### GCP-0053

Le plan de contrôle GKE est accessible depuis `0.0.0.0/0`.

Cette alerte n'a pas été corrigée et fait l'objet d'une exception documentée
car le pipeline GitHub Actions utilise des adresses IP dynamiques.

### Résultat

Deux problèmes ont été corrigés.

Le troisième fait l'objet d'une exception documentée et justifiée.

## Secrets

### Constat

Aucune clé de service ni secret sensible n'est stocké dans le dépôt
ou dans GitHub Actions.

L'authentification du pipeline utilise Workload Identity Federation.

Les secrets applicatifs, comme le mot de passe du cache et le jeton de l'API,
sont stockés dans des objets `Secret` Kubernetes.

Ils ne sont pas écrits en clair dans le dépôt Git.

### Résultat

Conforme : les informations sensibles ne sont pas stockées directement
dans le dépôt.

## Images Docker

### Constat

Les images déployées en production utilisent des versions précises.

### API

`europe-west4-docker.pkg.dev/form-gke-eleve04-42a1/foodtrack-d-images/api-capteurs:485a7c1a21c7bf61d57855bbf09317ec565e45b4`

### Portail

`europe-west4-docker.pkg.dev/form-gke-eleve04-42a1/foodtrack-d-images/portail-qualite:485a7c1a21c7bf61d57855bbf09317ec565e45b4`

### Cache

`redis:8.10.1`

Les images de l'API et du portail sont stockées dans Artifact Registry
et utilisent le SHA du commit comme tag.

Cela permet de connaître précisément la version déployée.

Le tag `latest` n'est pas utilisé.

Les scans des images fournies utilisent un seuil `CRITICAL`
avec l'option `ignore-unfixed`.

Le pipeline échoue lorsqu'une vulnérabilité critique disposant
d'un correctif est détectée.

## Scan des configurations Kubernetes

### Constat

Trivy a identifié deux problèmes de niveau HIGH sur les composants
API, portail et cache dans les environnements DEV, TEST et PROD.

- `KSV-0014` : le système de fichiers racine n'est pas configuré en lecture seule.
- `KSV-0118` : le contexte de sécurité par défaut est utilisé.

### Résultat

À améliorer : les contextes de sécurité des conteneurs peuvent être renforcés
afin de réduire les risques signalés par Trivy.

## Protection de la production

### Constat

L'environnement GitHub `production` est protégé.

- Un relecteur est obligatoire avant le déploiement.
- Le contournement administrateur est désactivé.
- Les déploiements sont limités à la branche `main`.

Le premier déploiement en production a été validé manuellement
et s'est terminé avec succès.

### Résultat

Conforme : le déploiement en production nécessite une validation avant exécution.

## Exception Terraform

### Constat

Le bucket utilisé pour stocker le state Terraform a été créé manuellement
avant le premier `terraform init`.

Cette création manuelle était nécessaire afin de disposer du backend Terraform
avant le déploiement de l'infrastructure.

Cette exception est documentée dans le README avec les commandes utilisées.

### Résultat

Exception documentée et justifiée.

## Conclusion

L'audit a permis de vérifier les principaux éléments de sécurité du projet.

L'authentification du pipeline utilise Workload Identity Federation sans clé JSON,
les accès SSH sont restreints, les secrets ne sont pas stockés en clair
et les images utilisent des versions identifiables.

Les scans Trivy sont intégrés au pipeline et ont permis de détecter plusieurs
mauvaises configurations.

Des améliorations restent possibles, notamment la séparation du compte
de service utilisé par la CI/CD et les nœuds GKE, ainsi que le renforcement
du contexte de sécurité des conteneurs.

Le principal compromis réseau concerne l'exposition publique du plan de contrôle
GKE, conservée pour permettre le fonctionnement du pipeline GitHub Actions
et documentée comme exception.
