# foodtrack-groupe-d
FoodTrack sur GCP, Équipe D (Terraform, GKE, CI/CD), entrepôt Eemshaven

## Chaîne de livraison (CI/CD)

Cette section décrit comment le code de l'équipe est automatiquement vérifié, construit et déployé sur Google Cloud, sans intervention manuelle jusqu'à l'environnement de production.

### Principe général

Le pipeline est défini dans `.github/workflows/deploy.yml` et s'exécute automatiquement sur GitHub Actions à chaque envoi de code (push) sur le dépôt. Il enchaîne plusieurs étapes : vérification du code, construction et publication des images, puis déploiement sur trois environnements successifs (développement, test, production).

Le pipeline s'authentifie auprès de Google Cloud sans utiliser de mot de passe ni de clé secrète stockée quelque part. Il utilise un mécanisme appelé Workload Identity Federation (WIF) : GitHub délivre un jeton signé qui prouve l'origine de l'exécution, Google Cloud vérifie ce jeton et accorde en échange un accès temporaire et limité, via un compte de service dédié. Ce compte de service n'a que les droits strictement nécessaires au pipeline, jamais un accès complet au projet.

### Les étapes du pipeline, dans l'ordre

1. **Vérification du code (job « qualite »)**
   Avant toute chose, le pipeline vérifie que le code est correct : le code Terraform est bien formaté et syntaxiquement valide, les fichiers de configuration Kubernetes respectent le format attendu, et une recherche de failles de sécurité connues est effectuée sur le code Terraform. Si une faille grave est détectée, le pipeline s'arrête ici.

2. **Publication des images (job « build »)**
   L'application FoodTrack est composée de trois éléments (un portail web, une API, un cache de données), fournis sous forme d'images déjà prêtes, sans code source à compiler côté équipe. Le pipeline récupère ces images, les analyse à la recherche de failles de sécurité, puis les republie dans le registre d'images de l'équipe sur Google Cloud (Artifact Registry). Chaque image est identifiée par l'identifiant unique du commit qui l'a publiée, pour toujours savoir exactement quelle version tourne où.

3. **Déploiement (jobs « deploy-dev », « deploy-test », « deploy-prod »)**
   Ces trois étapes appliquent la configuration sur le cluster Kubernetes, chacune sur son propre environnement isolé. Le pipeline attend systématiquement la confirmation que le déploiement s'est bien terminé avant de continuer, pour éviter qu'une erreur passe inaperçue.

### La protection avant la mise en production

Le passage en production n'est jamais automatique. Il est protégé par un environnement GitHub dédié nommé `production`, qui impose qu'une personne de l'équipe examine et approuve manuellement le déploiement avant qu'il ne parte réellement. Cette protection ne peut pas être contournée, même par une personne administratrice du dépôt, et elle ne s'applique qu'aux déploiements partant de la branche principale (`main`), jamais d'une branche de travail en cours.

### Configuration nécessaire pour faire fonctionner le pipeline

Le pipeline a besoin de six informations, stockées comme variables du dépôt (et non comme secrets, puisqu'aucune de ces valeurs n'est confidentielle) : l'identifiant du projet Google Cloud, la région et la zone utilisées, le nom du cluster Kubernetes, ainsi que deux identifiants techniques produits par la configuration Terraform (le fournisseur d'identité fédérée et le compte de service du pipeline). Tant que ces valeurs ne sont pas renseignées, les étapes qui en dépendent sont volontairement ignorées plutôt que de faire échouer le pipeline.
