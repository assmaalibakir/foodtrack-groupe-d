# foodtrack-groupe-d
FoodTrack sur GCP, Équipe D (Terraform, GKE, CI/CD), entrepôt Eemshaven

## Chaîne de livraison (CI/CD)

Cette section décrit comment le code de l'équipe est automatiquement vérifié, construit et déployé sur Google Cloud, sans intervention manuelle jusqu'à l'environnement de production.

### Principe général

Le pipeline est défini dans `.github/workflows/deploy.yml` et s'exécute automatiquement sur GitHub Actions à chaque envoi de code (push) sur le dépôt. Il enchaîne plusieurs étapes : vérification du code, construction et publication des images, puis déploiement sur trois environnements successifs (développement, test, production).

Le pipeline s'authentifie auprès de Google Cloud sans utiliser de mot de passe ni de clé secrète stockée quelque part. Il utilise un mécanisme appelé Workload Identity Federation (WIF) : GitHub délivre un jeton signé qui prouve l'origine de l'exécution, Google Cloud vérifie ce jeton et accorde en échange un accès temporaire et limité, via un compte de service dédié. Ce compte de service n'a que les droits strictement nécessaires au pipeline, jamais un accès complet au projet.

### Les étapes du pipeline, dans l'ordre

1. **Vérification du code (job « qualite »)**
   Avant toute chose, le pipeline vérifie que le code est correct : le code Terraform est bien formaté et syntaxiquement valide, les fichiers de configuration Kubernetes (assemblés via Kustomize à partir du dossier `k8s/`) respectent le format attendu, et une recherche de failles de sécurité connues est effectuée sur le code Terraform. Si une faille grave est détectée, le pipeline s'arrête ici.

2. **Publication des images (job « build »)**
   L'application FoodTrack est composée de trois éléments (un portail web, une API, un cache de données), fournis sous forme d'images déjà prêtes, sans code source à compiler côté équipe. Le pipeline récupère ces images, les analyse à la recherche de failles de sécurité, puis les republie dans le registre d'images de l'équipe sur Google Cloud (Artifact Registry, dépôt `foodtrack-d-images`). Chaque image est identifiée par l'identifiant unique du commit qui l'a publiée, pour toujours savoir exactement quelle version tourne où.

3. **Déploiement (jobs « deploy-dev », « deploy-test », « deploy-prod »)**
   Ces trois étapes assemblent et appliquent la configuration Kubernetes du bon environnement grâce à Kustomize (`k8s/overlays/dev`, `test` ou `prod`, chacun basé sur le socle commun `k8s/base`), mettent à jour les déploiements pour pointer vers les images republiées dans Artifact Registry, puis attendent la confirmation que le déploiement s'est bien terminé et que tous les pods sont prêts, pour éviter qu'une erreur passe inaperçue.

### La protection avant la mise en production

Le passage en production n'est jamais automatique. Il est protégé par un environnement GitHub dédié nommé `production`, qui impose qu'une personne de l'équipe examine et approuve manuellement le déploiement avant qu'il ne parte réellement. Cette protection ne peut pas être contournée, même par une personne administratrice du dépôt, et elle ne s'applique qu'aux déploiements partant de la branche principale (`main`), jamais d'une branche de travail en cours.

### Configuration nécessaire pour faire fonctionner le pipeline

Le pipeline a besoin de six informations, stockées comme variables du dépôt (et non comme secrets, puisqu'aucune de ces valeurs n'est confidentielle) : l'identifiant du projet Google Cloud, la région et la zone utilisées, le nom du cluster Kubernetes, ainsi que deux identifiants techniques produits par la configuration Terraform (le fournisseur d'identité fédérée et le compte de service du pipeline). Tant que ces valeurs ne sont pas renseignées, les étapes qui en dépendent sont volontairement ignorées plutôt que de faire échouer le pipeline.

## Stratégie de versions et de releases

Trois événements différents déclenchent chacun un environnement, de façon indépendante :

| Événement | Environnement déclenché |
|---|---|
| Envoi de code sur la branche `develop` | Développement (`foodtrack-dev`) |
| Fusion de code sur la branche `main` | Test (`foodtrack-test`) |
| Création d'un tag de version (`v1.0.0`, `v1.1.0`, etc.) | Production (`foodtrack-prod`), après validation manuelle |

Le code circule librement sur `develop` pendant le développement. Une fois prêt à être testé plus sérieusement, il est fusionné sur `main`, ce qui déclenche automatiquement le déploiement sur l'environnement de test. La mise en production n'est jamais automatique : elle nécessite la création explicite d'un tag suivant le versionnage sémantique (`vMAJEUR.MINEUR.CORRECTIF`), puis l'approbation manuelle d'un membre de l'équipe sur l'environnement GitHub protégé.

### Correctif urgent

Un correctif urgent suit le même chemin que toute autre modification : développement sur une branche dédiée, fusion sur `main` pour validation en test, puis création d'un nouveau tag de version (incrément du numéro de correctif, par exemple `v1.0.1`) pour le déployer en production. Aucun raccourci n'est prévu pour contourner la validation manuelle, y compris en urgence.

### Retour en arrière (rollback)

`kubectl rollout undo` permet de revenir à la version précédente d'un déploiement rapidement. Cette commande suffit lorsque seule l'image du conteneur a changé entre les deux versions. Elle ne suffit plus si la nouvelle version a aussi modifié la configuration (ConfigMap, Secret) ou la structure des données stockées : dans ce cas, revenir uniquement sur l'image applicative sans revenir également sur la configuration associée peut laisser le système dans un état incohérent. Un retour en arrière complet nécessite alors de redéployer explicitement l'ensemble version applicative et configuration correspondant au tag précédent.
