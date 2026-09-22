# Securite FoodTrack

## Comptes de service

### Objectif

Verifier que chaque usage dispose d'un compte de service adapte et que les permissions accordees respectent le principe du moindre privilege

### Points a verifier

- Identifier les comptes de service utilises par le projet.
- Identifier le role de chaque compte de service.
- Verifier que chaque compte possede uniquement les permissions necessaires
- Verifier qu'aucun compte de service ne possede un role trop permissif comme `roles/editor`.
- Justifier les permissions accordees a chaque compte

### Etat actuel

A verifier lorsque l'infrastructure Terraform de l'equipe D sera deployee

## Roles IAM

### Objectif

Verifier que les roles IAM attribues aux utilisateurs et aux comptes de service
sont adaptes a leur usage et respectent le principe du moindre privilege.

### Points a verifier

- Identifier les utilisateurs ayant acces au projet.
- Identifier les roles attribues a chaque utilisateur.
- Identifier les roles attribues aux comptes de service.
- Verifier qu'aucun role trop permissif n'est attribue sans justification.
- Verifier que chaque role correspond a un besoin reel.
- Justifier pourquoi chaque role a ete choisi.

### Etat actuel

A verifier lorsque le projet Google Cloud de l'equipe D sera accessible
et que les ressources auront ete creees.

## Pare-feu
### Objectif

Verifier que les regles de pare-feu autorisent uniquement les flux necessaires
au fonctionnement de l'infrastructure.

### Points a verifier

- Identifier toutes les regles de pare-feu du projet.
- Verifier les ports ouverts.
- Verifier les adresses IP ou plages reseau autorisees.
- Verifier que les regles ciblent uniquement les ressources necessaires.
- Verifier qu'aucun acces SSH n'est ouvert a tout Internet.
- Justifier chaque regle de pare-feu presente.

### Etat actuel

A verifier lorsque le VPC et les regles de pare-feu de l'equipe D
auront ete crees par Terraform.

## Bastion

### Objectif

Verifier que l'acces au bastion est suffisamment securise
et qu'il ne permet pas de connexions trop ouvertes.

### Points a verifier

- Verifier que l'authentification par mot de passe est desactivee.
- Verifier que l'authentification se fait uniquement avec des cles SSH.
- Verifier que l'acces SSH est limite a des adresses IP autorisees.
- Verifier que le port SSH n'est pas ouvert a tout Internet.
- Justifier la presence et l'utilisation du bastion.

### Etat actuel

A verifier lorsque le bastion de l'equipe D aura ete deploye.

## Plan de controle GKE

### Objectif

Verifier comment le plan de controle du cluster GKE est expose
et identifier les risques associes a ce choix.

### Points a verifier

- Identifier si le plan de controle est accessible publiquement ou de maniere restreinte.
- Identifier les adresses ou reseaux autorises a communiquer avec le cluster.
- Verifier que l'exposition choisie correspond aux besoins du projet.
- Identifier les risques lies a ce choix.
- Indiquer quelle alternative aurait pu etre utilisee.
- Justifier la solution retenue.

### Etat actuel

A verifier lorsque le cluster GKE de l'equipe D aura ete deploye.

## Secrets

### Objectif

Verifier qu'aucune information sensible n'est stockee directement
dans le depot Git ou dans les fichiers de configuration versionnes.

### Points a verifier

- Verifier qu'aucun mot de passe n'est present dans le depot.
- Verifier qu'aucune cle ou information sensible n'est presente dans le code.
- Verifier qu'aucun fichier sensible comme `.env` ou certains fichiers JSON
  n'a ete ajoute par erreur.
- Verifier l'historique Git pour detecter d'anciens secrets.
- Verifier que les valeurs sensibles sont gerees avec une solution adaptee.
- Justifier la methode choisie pour proteger les secrets.

### Etat actuel

A verifier lorsque le depot final de l'equipe D sera complet

## Images Docker

### Objectif

Verifier que les images Docker utilisees dans le projet
proviennent de sources identifiees et qu'elles sont correctement versionnees.

### Points a verifier

- Identifier l'origine de chaque image Docker utilisee.
- Verifier que les images utilisent des tags explicites.
- Eviter les tags trop vagues comme `latest`.
- Verifier que les versions utilisees sont connues.
- Verifier le dernier resultat d'analyse de securite des images.
- Justifier le choix des images utilisees.

### Etat actuel

A verifier lorsque les images finales du projet seront definies
et que l'Artifact Registry sera disponible.