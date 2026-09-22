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