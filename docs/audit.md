
# Audit de sécurité

## Objectif

L’objectif de cet audit est de vérifier les principaux éléments de sécurité de l’infrastructure FoodTrack.

Nous vérifions les comptes de service, les rôles IAM, le pare-feu, le bastion, le plan de contrôle GKE, les secrets et les images Docker.

---

## IAM

### Comptes de service observés

Deux comptes de service actifs ont été identifiés dans le projet.

- `foodtrack-ci@form-gke-eleve04-42a1.iam.gserviceaccount.com`

  - Usage : CI/CD avec GitHub Actions et Workload Identity Federation
  - Rôles observés : Kubernetes Engine Developer et Artifact Registry Writer
- `944188075327-compute@developer.gserviceaccount.com`

  - Nom : Compute Engine default service account
  - Usage : compte créé automatiquement par GCP
  - Rôle observé : Editor

### Constat

Le compte `foodtrack-ci` est utilisé pour la CI/CD et semble également être utilisé par les nœuds GKE.

Il serait préférable de séparer ces deux usages avec un compte de service dédié aux nœuds.

Le compte Compute Engine par défaut possède encore le rôle `Editor`, qui donne des droits trop larges.

### Résultat

À corriger ou à justifier : vérifier les comptes réellement utilisés par les nœuds GKE et limiter leurs permissions au strict nécessaire.

---

## Pare-feu

### Constat

Une règle de pare-feu permet l’accès SSH au bastion.

- Nom : `foodtrack-d-bastion`
- Protocole : TCP
- Port : `22`
- Source autorisée : `35.235.240.0/20`
- Cible : `bastion-node`

La règle SSH n’est pas ouverte à `0.0.0.0/0`.

L’accès est donc limité à une plage d’adresses précise et cible uniquement le bastion.

### Résultat

Conforme : l’accès SSH n’est pas ouvert à tout Internet.

---

## Bastion

### Constat

Le bastion utilisé dans le projet est `foodtrack-d-bastion`.

L’accès SSH est limité au port `22` et à une plage d’adresses précise.

L’authentification par mot de passe a été désactivée afin de conserver uniquement un accès par clé SSH.

### Résultat

Conforme : l’accès SSH au bastion est restreint et l’authentification par mot de passe est désactivée.

---

## Plan de contrôle GKE

### Constat

Le plan de contrôle du cluster GKE est actuellement accessible publiquement.

Une restriction aux adresses IP autorisées du bastion est prévue afin de réduire son exposition.

### Résultat

À corriger : appliquer la restriction puis vérifier son fonctionnement.

---

## Secrets

### Constat

Les secrets Kubernetes sont créés par un script PowerShell.

Les valeurs sensibles sont générées aléatoirement au moment de l’exécution. Elles ne sont pas enregistrées dans un fichier et ne sont pas affichées dans le terminal

### Résultat

Conforme : aucune valeur sensible n’est stockée directement dans le dépôt Git par ce script

## Images Docker

### Constat

À vérifier.

Il faut vérifier l’origine des images utilisées, leurs versions et s’assurer qu’elles n’utilisent pas inutilement le tag `latest`.

Il faut également vérifier le résultat du dernier scan de sécurité des images.

### Résultat

À compléter après vérification.

---

## Conclusion

L’audit a permis de vérifier plusieurs points de sécurité de l’infrastructure.

Le pare-feu et le bastion sont correctement restreints. Les secrets ne sont pas stockés directement dans le dépôt Git. Des points restent encore à finaliser concernant les comptes de service, le plan de contrôle GKE et les images Docker
