# foodtrack-groupe-d
FoodTrack sur GCP, Équipe D (Terraform, GKE, CI/CD), entrepôt Eemshaven

Ce projet contient la configuration Terraform complète pour le déploiement de l'infrastructure de la plateforme FoodTrack sur Google Cloud Platform (GCP).

L'architecture repose sur une approche modulaire respectant les principes d'isolation réseau, de gestion centralisée des états (remote state), et d'intégration continue sécurisée via la fédération d'identités (WIF).

🏗 Architecture globale
L'infrastructure est découpée en quatre modules principaux :
```text
.
├── main.tf             # Configuration racine (interconnexion des modules)
├── variables.tf        # Variables globales du projet
├── outputs.tf          # Sorties globales de l'infrastructure
├── terraform.tfvars    # Valeurs des variables par environnement
└── modules/
   ├── reseau/          # VPC, Sous-réseau, Cloud Router, Cloud NAT, Pare-feu
   ├── compute/         # Cluster GKE Privé, Node Pool, Bastion Compute Engine
   ├── stockage/        # Artifact Registry Docker, Buckets Storage (Backup & Logs)
   └── wif-github/      # Fédération d'identité Workload Identity (GitHub Actions OIDC)
```

🏷 Convention de nommage
Toutes les ressources respectent la convention de nommage imposée :

| Ressource | Convention de nom |
|---|---|
| VPC | foodtrack-d-vpc |
| Sous-réseau | foodtrack-d-subnet |
| Cluster GKE | foodtrack-d-cluster |
| Node pool GKE | foodtrack-d-pool |
| Bastion VM | foodtrack-d-bastion |
| Bucket State Terraform | foodtrack-d-tfstate-form-gke-eleve04-42a1 |
| Dépôt d'images | foodtrack-d-images |
| Namespaces Kubernetes | foodtrack-dev, foodtrack-test, foodtrack-prod |

🛠 Prérequis
- Google Cloud SDK (gcloud) installé et authentifié.
- Terraform >= 1.5.0 installe.
- Projet GCP configuré : form-gke-eleve04-42a1.
- Le bucket de State Terraform créé au préalable dans GCP.

1. Activer les API GCP requises
Avant la première initialisation, activez les API nécessaires sur le projet :
bash `gcloud services enable compute.googleapis.com \ container.googleapis.com \ artifactregistry.googleapis.com \ iamcredentials.googleapis.com`

2. Configurer la région et la zone CLI
bash
`export EQUIPE="d"
export REGION="europe-west4"
export ZONE="europe-west4-b"
export PROJECT="form-gke-eleve04-42a1"
gcloud config set project "$PROJECT"
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"`

🚀 Guide de déploiement
1. Initialisation de Terraform

Initialisez le backend GCS et téléchargez les fournisseurs :
bash `terraform init`

2. Validation et Planification

Vérifiez la validité de la syntaxe et prévisualisez les modifications :

bash `terraform validate terraform plan`

3. Application de la configuration

Déployez l'ensemble de l'infrastructure :
bash `terraform apply -auto-approve`

🔑 Intégration CI/CD avec GitHub Actions (WIF)
Le module wif-github met en place la fédération d'identités (Workload Identity Federation), évitant le stockage de clés de compte de service dans GitHub.

1. Variables générées par Terraform

Après l'exécution de terraform apply, récupérez les deux valeurs d'output :

bash `terraform output wif_provider_name terraform output ci_service_account_email`

2. Configuration sur GitHub

Allez dans votre dépôt GitHub : Settings > Secrets and variables > Actions > Variables et ajoutez :

WIF_PROVIDER : La valeur issue de `wif_provider_name`.
CI_SERVICE_ACCOUNT : La valeur issue de `ci_service_account_email`.

3. Rôles accordés au pipeline CI

Le compte de service du pipeline dispose de droits strictement minimaux : * `roles/artifactregistry.writer` : Publication des images Docker. * `roles/container.developer` : Déploiement des objets sur le cluster GKE.

🔒 Sécurité & Accès au Cluster GKE

- Plan de contrôle (Master) : Les accès réseau sont restreints via `master_authorized_networks_config`.
- Bastion SSH : Accessible uniquement via Identity-Aware Proxy (IAP) (`35.235.240.0/20`) via le port 22.
- Nodes Kubernetes : Situés dans des sous-réseaux privés sans adresse IP publique, accédant à Internet pour les mises à jour uniquement via le Cloud NAT.

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

## Partie Exploitation

### Monitoring
Le monitoring permet de surveiller l'état et les performances de l'application FoodTrack en production

Le dashboard devra afficher les principales métriques suivantes :

- CPU
- Mémoire
- Pods prêts
- Taux d'erreurs HTTP
- Latence

Un uptime check sera également configuré sur l'adresse publique du portail de production afin de vérifier sa disponibilité
Une requête de logs sera enregistrée dans Cloud logging afin d'isoler rapidement les erreurs de l'application dans le namespace concerné

### Alertes
Les alertes permettent de prévenir rapidement l'équipe en cas de problème détecté sur le portail FoodTrack

Une alerte sera configurée à partir de l'uptime check du portail de production
Une notification par e-mail sera envoyée si le portail ne répond plus pendant une durée définie
Le seuil et la durée de déclenchement seront choisis afin d'éviter les alertes inutiles tout en permettant de réagir rapidement en cas de problèmes

### IAM et securite
L'IAM permet de contrôler qui peut accéder aux ressources du projet et quelles actions chaque utilisateur ou service peut effectuer
Le principe du moindre privilège sera appliqué afin d'attribuer uniquement les permissions nécessaire

La sécurité du projet reposera également sur plusieurs contrôles :

- Vérification des comptes de service et de leurs rôles
- Vérification des règles de pare-feu
- Sécurisation de l'accès au bastion
- Contrôle de l'accès au plan de contrôle GKE
- Vérification de l'absence de secrets dans le dépôt Git
- Contrôle de l'origine, du versionnement et du scan des images Docker

### Script Python de controle de santé
Un script Python permet de vérifier automatiquement l'état du service FoodTrack

Le script interroge une URL, vérifie le code HTTP retourné, mesure le temps de réponse et affiche un résultat
Il retourne un code de sortie '0' si le service fonctionne correctement et un code différent de '0' en cas d'erreur.
L'URL est fournie au lancement du script afin de pouvoir utiliser le même script sur plusieurs environnements sans modifier le code.

### Scripts Bash
Trois scripts Bash permettent d'automatiser des tâches d'exploitation courantes :
- Le premier script sauvegarde les fichiers de configuration dans un bucket Cloud Storage avec un nom horodaté
- Le deuxième script supprime les exports de logs âgés de plus de 30 jours afin d'éviter l'accumulation de fichiers inutiles
- Le troisième script permet de réduire le node pool GKE à zéro pendant les périodes d'inactivité puis de le redémarrer lorsque l'environnement doit être utilisé

Ces scripts sont conçus pour être rejouables et pour arrêter leur exécution automatiquement en cas d'erreur

### Couts
Cette partie permet de voir quelles ressources du projet coûtent de l'argent
Nous allons surtout surveiller le coût du cluster GKE, du stockage, du réseau et des logs
Pour réduire les dépenses, le node pool pourra être arrêté quand l'environnement n'est pas utilisé
Les coûts seront vérifiés avec le calculateur Google Cloud et les données de facturation du projet

### Audit
L'audit permet de vérifier que les règles de sécurité du projet sont bien respectées
Nous allons contrôler les accès IAM, les règles de pare feu, le bastion, les secrets et les images utilisées.
L'objectif est de repérer les éventuels problèmes, de les corriger et de justifier les choix de sécurité qui ont été fait

## Retour d'expérience : premier déploiement réel

Cette section documente les problèmes rencontrés et corrigés lors du premier passage complet du pipeline sur l'infrastructure réelle, à titre de traçabilité et de retour d'expérience.

### Seuils de sécurité des images fournies

Le scan de sécurité de l'image `redis:8.10.1` a d'abord échoué sur 43 failles classées HIGH, toutes situées dans des paquets système Debian embarqués dans l'image (`util-linux`, `ncurses`, `perl-base`), sans rapport avec le fonctionnement de Redis lui-même. Le seuil de blocage a été restreint à CRITICAL pour les images fournies, dont la version est imposée et ne peut pas être changée.

Un second scan a ensuite bloqué sur l'image `nginx:1.30.5`, avec une faille réelle classée CRITICAL (`CVE-2026-6653`, dans la bibliothèque `libxml2`), mais sans correctif disponible à ce jour. L'option `ignore-unfixed` a été ajoutée : le pipeline bloque désormais uniquement sur les failles critiques pour lesquelles un correctif existe et n'a pas été appliqué.

### Dimensionnement du cluster

Le premier déploiement réel a révélé que le node pool, dimensionné pour un seul environnement, ne suffisait pas à héberger les trois environnements (dev, test, prod) simultanément : les pods restaient bloqués en attente faute de CPU disponible. Le plafond de l'autoscaling a été augmenté progressivement (de 3 à 5 nœuds) au fil des tests, en complément d'une réduction des ressources demandées par le cache en environnements dev et test.

### Configuration et données manquantes

Deux erreurs de configuration ont empêché le démarrage de certains pods : une clé manquante dans le Secret utilisé par le cache (`CACHE_PASSWORD`), et un caractère invisible (BOM) en tête du fichier de configuration Nginx, introduit par un enregistrement depuis un éditeur Windows, qui empêchait Nginx de démarrer avec l'erreur `unknown directive "server"`.

### Fiabilisation du pipeline

Une étape de vérification finale, redondante avec les contrôles de fin de déploiement déjà effectués individuellement pour chaque ressource, provoquait des échecs ponctuels en se déclenchant pendant la brève transition entre les deux mises à jour successives d'un déploiement (application des manifestes, puis mise à jour de l'image). Cette étape a été supprimée, les contrôles individuels suffisant à garantir la disponibilité des services.

## Exception documentée : création manuelle du bucket de state Terraform

L'ensemble de l'infrastructure de ce projet est géré par Terraform, à une seule exception près, assumée et documentée ici : le bucket Cloud Storage qui héberge le fichier d'état Terraform (`state`) a été créé manuellement, via une commande `gcloud`, avant le tout premier `terraform init`.

Cette exception est nécessaire pour une raison structurelle : Terraform a besoin que ce bucket existe déjà pour pouvoir s'y connecter et y stocker son état (configuration du bloc `backend "gcs"` dans `terraform/main.tf`). Il ne peut donc pas créer lui-même la ressource qui lui sert de mémoire, ce serait un problème de dépendance circulaire (« l'œuf et la poule »).

Commandes utilisées pour cette unique création manuelle :
```bash
gcloud storage buckets create gs://foodtrack-d-tfstate-foodtrack-equipe-d \
  --location=europe-west4 --uniform-bucket-level-access
gcloud storage buckets update gs://foodtrack-d-tfstate-foodtrack-equipe-d --versioning
```

Le versionnage est activé sur ce bucket pour permettre de revenir à une version antérieure du state en cas de corruption ou de mauvaise manipulation. Aucune autre ressource du projet n'est créée en dehors de Terraform.

<!-- demo soutenance -->
