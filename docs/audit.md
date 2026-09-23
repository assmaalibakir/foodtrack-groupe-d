# Audit FoodTrack

## Objectif

L'objectif de cet audit est de verifier que l'infrastructure FoodTrack
respecte les principales bonnes pratiques de securite demandees dans le projet.

L'audit permettra d'identifier les elements conformes, les points a corriger
et les risques qui restent acceptes.

L'etat final devra etre court, factuel et base sur l'infrastructure
reellement deployee.

## IAM

L'audit IAM permettra de verifier les utilisateurs, les comptes de service
et les roles presents dans le projet.

### Points a verifier

- Identifier les comptes de service du projet.
- Verifier qu'un compte de service correspond a un usage precis.
- Verifier que les comptes de service possedent uniquement les roles necessaires.
- Verifier qu'aucun compte de service n'utilise `roles/editor`.
- Identifier les roles accordes aux membres de l'equipe.
- Justifier les permissions accordees.

### Commande de verification

```bash
gcloud projects get-iam-policy "$PROJECT" \
  --flatten="bindings[].members" \
  --format="table(bindings.role,bindings.members)"
```


### Comptes de service observés

Deux comptes de service actifs ont été identifiés dans le projet.

- `foodtrack-ci@form-gke-eleve04-42a1.iam.gserviceaccount.com`

  - Nom : Compte de service du pipeline FoodTrack
  - Usage : automatisations CI/CD avec Workload Identity Federation et GitHub Actions
  - Rôles observés : Développeur Kubernetes Engine et Rédacteur Artifact Registry
- `944188075327-compute@developer.gserviceaccount.com`

  - Nom : Compute Engine default service account
  - Usage : compte créé automatiquement par GCP et utilisé par défaut par certaines VM ou certains nœuds GKE si aucun compte spécifique n’est défini
  - Rôle observé : Editor

### Constat

Le compte `foodtrack-ci` est dédié à un usage précis lié à la CI/CD.

Le compte Compute Engine par défaut possède encore le rôle `Editor`, qui est trop large par rapport au principe du moindre privilège.

### Résultat

À corriger ou à justifier : le rôle `Editor` du compte Compute Engine par défaut doit être vérifié et remplacé par des rôles plus précis s’il est utilisé par l’infrastructure.

## Pare-feu

### Règle observée

Une règle de pare-feu a été créée pour permettre l’accès SSH au bastion.

- Nom de la règle : `foodtrack-d-bastion`
- Protocole : TCP
- Port autorisé : `22`
- Cible : ressources portant le tag `bastion-node`
- Source autorisée : `35.235.240.0/20`

### Constat

La règle SSH n’est pas ouverte à `0.0.0.0/0`.

L’accès est limité à une plage d’adresses précise et cible uniquement le bastion.

Cette configuration permet de réduire l’exposition du service SSH.

### Résultat

Conforme sous réserve de vérifier que cette règle correspond bien au mode d’accès retenu pour l’administration du bastion.
