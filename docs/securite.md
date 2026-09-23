
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

Deux comptes de service principaux ont été identifiés :

- `foodtrack-ci`, utilisé pour la CI/CD avec des rôles liés à Kubernetes Engine et Artifact Registry.
- Le compte Compute Engine par défaut, qui possède encore le rôle `Editor`.

Le compte `foodtrack-ci` semble également être utilisé par les nœuds GKE. Il serait préférable de séparer l'usage CI/CD de l'usage des nœuds avec un compte de service dédié.

Le rôle `Editor` du compte Compute Engine par défaut doit être vérifié et retiré s'il n'est pas nécessaire.

## Rôles IAM

### Objectif

Vérifier que les rôles IAM attribués aux utilisateurs et aux comptes de service sont adaptés à leur usage et respectent le principe du moindre privilège.

### Points à vérifier

- Identifier les utilisateurs ayant accès au projet.
- Identifier les rôles attribués à chaque utilisateur.
- Identifier les rôles attribués aux comptes de service.
- Vérifier qu'aucun rôle trop permissif n'est attribué sans justification.
- Vérifier que chaque rôle correspond à un besoin réel.
- Justifier pourquoi chaque rôle a été choisi.

### État actuel

Les rôles observés pour `foodtrack-ci` correspondent à des besoins liés à la CI/CD.

Le compte Compute Engine par défaut possède le rôle `Editor`, qui est trop large et doit être corrigé ou justifié.

La vérification des utilisateurs et de leurs rôles reste à finaliser.

## Pare-feu

### Objectif

Vérifier que les règles de pare-feu autorisent uniquement les flux nécessaires au fonctionnement de l'infrastructure.

### Points à vérifier

- Identifier toutes les règles de pare-feu du projet.
- Vérifier les ports ouverts.
- Vérifier les adresses IP ou plages réseau autorisées.
- Vérifier que les règles ciblent uniquement les ressources nécessaires.
- Vérifier qu'aucun accès SSH n'est ouvert à tout Internet.
- Justifier chaque règle de pare-feu présente.

### État actuel

La règle SSH du bastion autorise uniquement le port `22`.

La source autorisée est `35.235.240.0/20` et la règle cible uniquement les ressources portant le tag `bastion-node`.

L'accès SSH n'est pas ouvert à `0.0.0.0/0`.

## Bastion

### Objectif

Vérifier que l'accès au bastion est suffisamment sécurisé et qu'il ne permet pas de connexions trop ouvertes.

### Points à vérifier

- Vérifier que l'authentification par mot de passe est désactivée.
- Vérifier que l'authentification se fait uniquement avec des clés SSH.
- Vérifier que l'accès SSH est limité à des adresses IP autorisées.
- Vérifier que le port SSH n'est pas ouvert à tout Internet.
- Justifier la présence et l'utilisation du bastion.

### État actuel

Le bastion utilisé est `foodtrack-d-bastion`.

L'accès SSH est limité au port `22` et à une plage d'adresses précise.

L'authentification par mot de passe a été désactivée afin de conserver un accès par clé SSH.

## Plan de contrôle GKE

### Objectif

Vérifier comment le plan de contrôle du cluster GKE est exposé et identifier les risques associés à ce choix.

### Points à vérifier

- Identifier si le plan de contrôle est accessible publiquement ou de manière restreinte.
- Identifier les adresses ou réseaux autorisés à communiquer avec le cluster.
- Vérifier que l'exposition choisie correspond aux besoins du projet.
- Identifier les risques liés à ce choix.
- Indiquer quelle alternative aurait pu être utilisée.
- Justifier la solution retenue.

### État actuel

Le plan de contrôle du cluster GKE est actuellement accessible publiquement.

Une restriction aux adresses IP autorisées du bastion est prévue afin de réduire son exposition.

## Secrets

### Objectif

Vérifier qu'aucune information sensible n'est stockée directement dans le dépôt Git ou dans les fichiers de configuration versionnés.

### Points à vérifier

- Vérifier qu'aucun mot de passe n'est présent dans le dépôt.
- Vérifier qu'aucune clé ou information sensible n'est présente dans le code.
- Vérifier qu'aucun fichier sensible comme `.env` ou certains fichiers JSON n'a été ajouté par erreur.
- Vérifier l'historique Git pour détecter d'anciens secrets.
- Vérifier que les valeurs sensibles sont gérées avec une solution adaptée.
- Justifier la méthode choisie pour protéger les secrets.

### État actuel

Les secrets Kubernetes sont générés automatiquement par un script PowerShell.

Les valeurs sensibles sont générées au moment de l'exécution et ne sont ni affichées ni enregistrées dans un fichier.

Aucune valeur sensible n'est stockée directement dans le dépôt par ce script.

## Images Docker

### Objectif

Vérifier que les images Docker utilisées dans le projet proviennent de sources identifiées et qu'elles sont correctement versionnées.

### Points à vérifier

- Identifier l'origine de chaque image Docker utilisée.
- Vérifier que les images utilisent des tags explicites.
- Éviter les tags trop vagues comme `latest`.
- Vérifier que les versions utilisées sont connues.
- Vérifier le dernier résultat d'analyse de sécurité des images.
- Justifier le choix des images utilisées.

### État actuel

À vérifier avec la configuration Kubernetes lorsque les images finales seront connues.
