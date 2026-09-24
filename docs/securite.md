
# Sécurité FoodTrack

## Comptes de service

### Objectif

Vérifier que chaque usage dispose d'un compte de service adapté et que les permissions accordées respectent le principe du moindre privilège.

### Points à vérifier

- Identifier les comptes de service utilisés par le projet.
- Identifier le rôle de chaque compte de service.
- Vérifier que chaque compte possède uniquement les permissions nécessaires.
- Vérifier qu'aucun compte de service ne possède un rôle trop permissif comme `roles/editor`.
- Justifier les permissions accordées à chaque compte.

### État actuel

Le pipeline CI/CD utilise le compte de service :

`foodtrack-ci@form-gke-eleve04-42a1.iam.gserviceaccount.com`

Les rôles attribués sont :

- `roles/artifactregistry.writer`
- `roles/container.developer`

L'authentification entre GitHub Actions et Google Cloud utilise Workload Identity Federation.

Aucune clé JSON de compte de service n'est stockée dans le dépôt ou dans GitHub Actions.

Le compte Compute Engine par défaut possède encore le rôle `Editor`, qui donne des permissions très larges. Ce point doit être vérifié et justifié s'il est réellement utilisé.

## Rôles IAM

### Objectif

Vérifier que les rôles IAM attribués aux utilisateurs et aux comptes de service sont adaptés à leur usage et respectent le principe du moindre privilège.

### Points à vérifier

- Identifier les utilisateurs ayant accès au projet.
- Identifier les rôles attribués à chaque utilisateur.
- Identifier les rôles attribués aux comptes de service.
- Vérifier qu'aucun rôle trop permissif n'est attribué sans justification.
- Vérifier que chaque rôle correspond à un besoin réel.

### État actuel

Les droits IAM des quatre membres de l'équipe ont été vérifiés.

Plusieurs rôles permettent d'administrer le projet, notamment `Éditeur`, `Administrateur de projet IAM` et `Administrateur de compte de service`.

Ces droits ont été attribués dans le cadre de l'environnement de formation et permettent aux membres de l'équipe d'administrer le projet.

Le compte `foodtrack-ci` possède uniquement les rôles nécessaires au pipeline CI/CD.

## Workload Identity Federation

### Objectif

Éviter l'utilisation de clés JSON permanentes pour authentifier GitHub Actions auprès de Google Cloud.

### État actuel

Le pipeline utilise Workload Identity Federation.

Le pool utilisé est :

`github-pool-dev`

Il est restreint au dépôt :

`assmaalibakir/foodtrack-groupe-d`

L'authentification utilise des jetons temporaires.

Aucune clé JSON permanente n'est stockée dans GitHub Actions ou dans le dépôt.

## Pare-feu

### Objectif

Vérifier que les règles de pare-feu autorisent uniquement les flux nécessaires au fonctionnement de l'infrastructure.

### Points à vérifier

- Vérifier les ports ouverts.
- Vérifier les plages réseau autorisées.
- Vérifier que les règles ciblent uniquement les ressources nécessaires.
- Vérifier qu'aucun accès SSH n'est ouvert à tout Internet.

### État actuel

La règle SSH du bastion autorise uniquement le port `22`.

La source autorisée est :

`35.235.240.0/20`

La règle cible uniquement les ressources portant le tag :

`bastion-node`

L'accès SSH n'est donc pas ouvert à `0.0.0.0/0`.

## Bastion

### Objectif

Vérifier que l'accès au bastion est suffisamment sécurisé.

### Points à vérifier

- Vérifier que l'authentification par mot de passe est désactivée.
- Vérifier que l'authentification se fait par clé SSH.
- Vérifier que l'accès SSH est limité à une plage réseau autorisée.

### État actuel

Le bastion utilisé est :

`foodtrack-d-bastion`

L'accès SSH est limité au port `22` et à une plage réseau précise.

L'authentification par mot de passe est désactivée afin de conserver un accès sécurisé par clé SSH.

## Plan de contrôle GKE

### Objectif

Vérifier comment le plan de contrôle du cluster GKE est exposé et identifier les risques associés à ce choix.

### État actuel

Le plan de contrôle GKE reste accessible depuis :

`0.0.0.0/0`

Cette configuration permet au pipeline GitHub Actions d'accéder au cluster malgré l'utilisation d'adresses IP dynamiques par les runners GitHub.

La sécurité repose donc principalement sur IAM et Workload Identity Federation.

Cette exception est documentée dans le code Terraform avec :

`# trivy:ignore:GCP-0053`

Cette configuration augmente l'exposition réseau mais correspond à un compromis lié au fonctionnement du pipeline CI/CD.

## Secrets

### Objectif

Vérifier qu'aucune information sensible n'est stockée directement dans le dépôt Git ou dans GitHub Actions.

### État actuel

Aucune clé de service ni secret sensible n'est stocké directement dans le dépôt ou dans GitHub Actions.

Les secrets applicatifs, comme le mot de passe du cache et le jeton de l'API, sont gérés avec des objets `Secret` Kubernetes.

Les valeurs sensibles ne sont pas écrites en clair dans le dépôt.

## Images Docker

### Objectif

Vérifier que les images Docker utilisées sont identifiées, versionnées et contrôlées.

### État actuel

Les images déployées en production sont :

### API

`europe-west4-docker.pkg.dev/form-gke-eleve04-42a1/foodtrack-d-images/api-capteurs:485a7c1a21c7bf61d57855bbf09317ec565e45b4`

### Portail

`europe-west4-docker.pkg.dev/form-gke-eleve04-42a1/foodtrack-d-images/portail-qualite:485a7c1a21c7bf61d57855bbf09317ec565e45b4`

### Cache

`redis:8.10.1`

Les images de l'API et du portail sont stockées dans Artifact Registry.

Elles utilisent le SHA du commit comme tag, ce qui permet d'identifier précisément la version déployée.

Le tag `latest` n'est pas utilisé.

## Scan de sécurité Terraform

### État actuel

Un scan Trivy est exécuté sur le code Terraform dans le job `qualite` du pipeline.

Trois problèmes de niveau HIGH ont été identifiés :

- `GCP-0048` : anciens endpoints de métadonnées activés.
- `GCP-0057` : métadonnées des nœuds insuffisamment sécurisées.
- `GCP-0053` : plan de contrôle accessible depuis `0.0.0.0/0`.

Les problèmes `GCP-0048` et `GCP-0057` ont été corrigés.

Le problème `GCP-0053` fait l'objet d'une exception documentée.

## Scan des configurations Kubernetes

### État actuel

Trivy a identifié deux problèmes de niveau HIGH sur les composants API, portail et cache dans les environnements DEV, TEST et PROD :

- `KSV-0014` : le système de fichiers racine n'est pas configuré en lecture seule.
- `KSV-0118` : le contexte de sécurité par défaut est utilisé.

Ces résultats montrent que les contextes de sécurité des conteneurs peuvent encore être renforcés.

## Protection de la production

### État actuel

L'environnement GitHub `production` est protégé.

- Un relecteur est obligatoire avant le déploiement.
- Le contournement administrateur est désactivé.
- Les déploiements sont limités à la branche `main`.

Le déploiement en production nécessite donc une validation manuelle avant exécution.

## Conclusion

La sécurité du projet repose sur plusieurs mécanismes complémentaires :

- Workload Identity Federation pour le pipeline CI/CD.
- Des règles de pare-feu restreintes pour le bastion.
- Une authentification SSH sans mot de passe.
- Des secrets non stockés en clair dans le dépôt.
- Des images versionnées avec des tags précis.
- Des scans Trivy intégrés au pipeline.

Certains points restent des compromis ou des axes d'amélioration, notamment l'exposition du plan de contrôle GKE et le renforcement du contexte de sécurité des conteneurs.
