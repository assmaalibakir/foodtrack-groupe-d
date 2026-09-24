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

| Ressource              | Convention de nom                             |
| ---------------------- | --------------------------------------------- |
| VPC                    | foodtrack-d-vpc                               |
| Sous-réseau           | foodtrack-d-subnet                            |
| Cluster GKE            | foodtrack-d-cluster                           |
| Node pool GKE          | foodtrack-d-pool                              |
| Bastion VM             | foodtrack-d-bastion                           |
| Bucket State Terraform | foodtrack-d-tfstate-form-gke-eleve04-42a1     |
| Dépôt d'images       | foodtrack-d-images                            |
| Namespaces Kubernetes  | foodtrack-dev, foodtrack-test, foodtrack-prod |

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
   `export EQUIPE="d" export REGION="europe-west4" export ZONE="europe-west4-b" export PROJECT="form-gke-eleve04-42a1" gcloud config set project "$PROJECT" gcloud config set compute/region "$REGION" gcloud config set compute/zone "$ZONE"`

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

## Partie Kubernetes

### Organisation des manifestes

Nous avons organisé les manifestes avec Kustomize pour éviter de recopier toute la configuration pour chaque environnement.

Le dossier `k8s/base` contient les ressources communes : les Deployments, le StatefulSet Redis, les Services, l'Ingress, le stockage, les ConfigMaps et le HorizontalPodAutoscaler. Les dossiers `k8s/overlays/dev`, `k8s/overlays/test` et `k8s/overlays/prod` adaptent ensuite cette base.

Chaque environnement possède son propre namespace :

- `foodtrack-dev`
- `foodtrack-test`
- `foodtrack-prod`

Cette séparation nous permet de tester une modification en développement puis en test avant de l'envoyer en production.

### Composants déployés

FoodTrack est composé de trois éléments :

- `api-capteurs`, déployée avec un Deployment et exposée sur le port 8080
- `portail-qualite`, déployé avec Nginx et exposé sur le port 8080
- `cache-releves`, basé sur Redis 8.10.1 et déployé avec un StatefulSet sur le port 6379

Le nombre de pods prévu n'est pas le même partout :

| Environnement  | API | Portail | Redis | Total |
| -------------- | --: | ------: | ----: | ----: |
| Développement |   1 |       1 |     1 |     3 |
| Test           |   1 |       1 |     1 |     3 |
| Production     |   2 |       2 |     1 |     5 |
| Total          |   4 |       4 |     3 |    11 |

La production possède deux pods pour l'API et deux pour le portail. Si un pod redémarre, l'autre peut continuer à répondre. Lors de notre dernière vérification, les 11 pods applicatifs étaient dans l'état `Running`.

### Capacité réelle du cluster

Le cluster `foodtrack-d-cluster` est déployé dans la zone `europe-west4-b`. Son node pool `foodtrack-d-pool` utilise des machines `e2-medium` et peut évoluer automatiquement entre 1 et 5 nœuds.

Au moment de notre vérification, quatre nœuds étaient actifs. Les valeurs affichées par Kubernetes étaient les suivantes :

| Capacité                          |        Par nœud | Total pour 4 nœuds |
| ---------------------------------- | ---------------: | ------------------: |
| CPU matériel                      |           2 vCPU |              8 vCPU |
| CPU utilisable par Kubernetes      |             940m |               3760m |
| Mémoire matérielle               | environ 3,83 Gio |   environ 15,31 Gio |
| Mémoire utilisable par Kubernetes | environ 2,73 Gio |   environ 10,94 Gio |

Une partie de la puissance de chaque machine est réservée par GKE pour le système et les composants Kubernetes. C'est pour cela que la capacité utilisable est plus faible que la capacité matérielle.

Le nombre de nœuds n'est pas fixe. GKE peut en ajouter lorsqu'il manque de la place pour démarrer les pods, puis en retirer lorsque la charge redescend. La réduction n'est pas immédiate, ce qui explique que le cluster puisse encore afficher quatre nœuds après un déploiement.

### Ressources des conteneurs

Les trois environnements utilisent les mêmes ressources pour chaque composant :

| Composant | CPU réservé | Mémoire réservée | Limite CPU | Limite mémoire |
| --------- | ------------: | ------------------: | ---------: | --------------: |
| API       |          100m |               128Mi |       300m |           128Mi |
| Portail   |          100m |               128Mi |       300m |           128Mi |
| Redis     |           50m |               128Mi |       500m |           512Mi |

Les valeurs réservées servent à Kubernetes pour placer les pods sur les nœuds. Les limites empêchent un conteneur de consommer trop de ressources.

Avec le nombre de réplicas prévu dans chaque environnement, les pods FoodTrack réservent :

| Environnement  | CPU réservé | Mémoire réservée |
| -------------- | ------------: | ------------------: |
| Développement |          250m |               384Mi |
| Test           |          250m |               384Mi |
| Production     |          450m |               640Mi |
| Total          |          950m |              1408Mi |

Ces chiffres correspondent au fonctionnement normal de l'application, avant une éventuelle montée en charge de l'API par le HPA. Ils ne comprennent pas les composants internes de GKE. Si les trois HPA atteignent leur nombre maximal de pods, les réservations de l'application peuvent monter jusqu'à 1250m de CPU et 1792Mi de mémoire.

### Autoscaling de l'API

Un HorizontalPodAutoscaler surveille le Deployment `api-capteurs`. Les réglages sont adaptés à chaque environnement :

| Environnement  | Minimum | Maximum | Seuil CPU |
| -------------- | ------: | ------: | --------: |
| Développement |   1 pod |  2 pods |      80 % |
| Test           |   1 pod |  2 pods |      70 % |
| Production     |  2 pods |  3 pods |      60 % |

La production conserve donc toujours deux pods API et peut monter jusqu'à trois pods lorsque l'utilisation du CPU augmente. Si les nœuds existants n'ont plus assez de place, l'autoscaler du node pool peut à son tour créer une machine supplémentaire.

### Réseau et exposition

Les communications internes passent par des Services Kubernetes de type `ClusterIP`.

| Service             | Port | Accès                       |
| ------------------- | ---: | ---------------------------- |
| `api-capteurs`    | 8080 | Interne au cluster           |
| `portail-qualite` | 8080 | Interne, derrière l'Ingress |
| `cache-releves`   | 6379 | Interne, Service headless    |

L'API et Redis ne sont pas directement exposés sur Internet. Seul le portail passe par un Ingress GKE.

Au moment de la validation, l'adresse publique de la production était `http://34.54.176.240`.

Les tests ont donné les résultats suivants :

| Test                           | Résultat |
| ------------------------------ | --------- |
| Page principale`/`           | HTTP 200  |
| Sonde`/healthz`              | HTTP 200  |
| API appelée depuis le cluster | HTTP 200  |
| Route publique`/api`         | HTTP 301  |

Le code 301 sur `/api` correspond à la redirection Nginx vers la route terminée par `/`. L'API répond bien avec un code 200 lorsqu'elle est appelée depuis le cluster.

### Stockage de Redis

Redis utilise un StatefulSet afin de conserver une identité stable et un volume persistant.

Chaque environnement possède un PersistentVolumeClaim de `10Gi`, utilisant la StorageClass `foodtrack-hdd` et le mode d'accès `ReadWriteOnce`.

| Environnement  | Volume |
| -------------- | -----: |
| Développement |   10Gi |
| Test           |   10Gi |
| Production     |   10Gi |
| Total          |   30Gi |

Le volume reste présent lorsqu'un pod Redis est supprimé puis recréé. Le Service `cache-releves` utilise aussi `clusterIP: None` afin de fournir une identité réseau stable au StatefulSet.

### Configuration et secrets

Les paramètres non sensibles sont placés dans la ConfigMap `foodtrack-config`. Kustomize ajoute un suffixe à son nom lorsque son contenu change, ce qui permet de mettre à jour les pods avec la bonne version de la configuration.

Les informations sensibles sont placées dans le Secret `foodtrack-api-config`, qui contient deux clés :

- `INGEST_TOKEN`
- `CACHE_PASSWORD`

Les vraies valeurs ne sont jamais enregistrées dans Git. Le fichier `k8s/examples/secret.example.yaml` ne contient que des valeurs fictives et sert de modèle. Le script `scripts/creer-secrets-k8s.sh` permet de créer le Secret à partir de variables d'environnement.

L'encodage Base64 de Kubernetes n'est pas du chiffrement. Les valeurs encodées ne doivent donc pas non plus apparaître dans Git, le README ou les captures d'écran.

### Disponibilité et retour en arrière

Les conteneurs utilisent des readiness probes pour vérifier qu'ils sont prêts à recevoir du trafic et des liveness probes pour détecter un conteneur qui ne répond plus.

Les Deployments utilisent une stratégie RollingUpdate. Kubernetes remplace progressivement les anciens pods par les nouveaux. En cas de problème, nous pouvons revenir à la version précédente avec une commande comme celle-ci :

```bash
kubectl rollout undo deployment/portail-qualite -n foodtrack-prod
```

Cette procédure a été utilisée pendant le premier déploiement après une erreur dans la configuration Nginx.

### Images validées en production

Lors de la validation finale, les images suivantes étaient déployées :

| Composant | Image                                                                                                                             |
| --------- | --------------------------------------------------------------------------------------------------------------------------------- |
| API       | `europe-west4-docker.pkg.dev/form-gke-eleve04-42a1/foodtrack-d-images/api-capteurs:485a7c1a21c7bf61d57855bbf09317ec565e45b4`    |
| Portail   | `europe-west4-docker.pkg.dev/form-gke-eleve04-42a1/foodtrack-d-images/portail-qualite:485a7c1a21c7bf61d57855bbf09317ec565e45b4` |
| Cache     | `redis:8.10.1`                                                                                                                  |

Le tag de l'API et du portail correspond au hash du commit Git utilisé pour le déploiement. Nous pouvons ainsi retrouver précisément la version qui tourne dans le cluster.

### Scan Trivy des manifestes Kubernetes

Un scan Trivy a été lancé sur les 13 fichiers de configuration détectés dans le dossier `k8s`.

| Sévérité | Nombre |
| ----------- | -----: |
| Critique    |      0 |
| Élevée    |      8 |
| Moyenne     |     10 |
| Faible      |     21 |
| Inconnue    |      0 |

Les huit résultats élevés correspondent à deux contrôles présents dans plusieurs ressources générées :

- `KSV-0014` : le système de fichiers racine n'est pas configuré en lecture seule
- `KSV-0118` : le contexte de sécurité Kubernetes n'est pas défini explicitement

Aucune erreur critique n'a été trouvée. Ces résultats restent documentés pour pouvoir renforcer la sécurité sans empêcher le fonctionnement des images Nginx et Redis fournies pour le projet.

### Validation finale

À la fin du déploiement, nous avons vérifié les points suivants :

- les quatre nœuds GKE étaient dans l'état `Ready`
- le node pool pouvait évoluer entre un et cinq nœuds
- les Deployments de dev et test avaient chacun un réplica disponible
- les Deployments de production avaient chacun deux réplicas disponibles
- les trois StatefulSets Redis étaient dans l'état `1/1`
- les trois volumes de `10Gi` étaient liés
- les 11 pods applicatifs étaient dans l'état `Running`
- le portail et sa sonde `/healthz` répondaient avec un code HTTP 200
- l'API répondait avec un code HTTP 200 depuis le cluster
- chaque namespace possédait un Secret contenant les deux clés attendues
- aucune valeur secrète réelle n'était enregistrée dans Git

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

| Événement                                                  | Environnement déclenché                                   |
| ------------------------------------------------------------ | ----------------------------------------------------------- |
| Envoi de code sur la branche`develop`                      | Développement (`foodtrack-dev`)                          |
| Fusion de code sur la branche`main`                        | Test (`foodtrack-test`)                                   |
| Création d'un tag de version (`v1.0.0`, `v1.1.0`, etc.) | Production (`foodtrack-prod`), après validation manuelle |

Le code circule librement sur `develop` pendant le développement. Une fois prêt à être testé plus sérieusement, il est fusionné sur `main`, ce qui déclenche automatiquement le déploiement sur l'environnement de test. La mise en production n'est jamais automatique : elle nécessite la création explicite d'un tag suivant le versionnage sémantique (`vMAJEUR.MINEUR.CORRECTIF`), puis l'approbation manuelle d'un membre de l'équipe sur l'environnement GitHub protégé.

### Correctif urgent

Un correctif urgent suit le même chemin que toute autre modification : développement sur une branche dédiée, fusion sur `main` pour validation en test, puis création d'un nouveau tag de version (incrément du numéro de correctif, par exemple `v1.0.1`) pour le déployer en production. Aucun raccourci n'est prévu pour contourner la validation manuelle, y compris en urgence.

### Retour en arrière (rollback)

`kubectl rollout undo` permet de revenir à la version précédente d'un déploiement rapidement. Cette commande suffit lorsque seule l'image du conteneur a changé entre les deux versions. Elle ne suffit plus si la nouvelle version a aussi modifié la configuration (ConfigMap, Secret) ou la structure des données stockées : dans ce cas, revenir uniquement sur l'image applicative sans revenir également sur la configuration associée peut laisser le système dans un état incohérent. Un retour en arrière complet nécessite alors de redéployer explicitement l'ensemble version applicative et configuration correspondant au tag précédent.

## Partie Exploitation

### Monitoring

Le monitoring permet de surveiller l'état et les performances de l'application
FoodTrack en production.

Un dashboard a été configuré dans Google Cloud Monitoring pour suivre les
principales métriques de l'environnement `foodtrack-prod` :

- CPU
- Mémoire
- Pods prêts
- Taux d'erreurs HTTP
- Latence

Le taux d'erreurs HTTP est calculé en comparant le nombre de réponses HTTP 4xx
au nombre total de requêtes reçues par le load balancer.

Ce suivi permet de détecter une dégradation du portail même lorsque celui-ci
reste accessible.

Un uptime check a également été configuré sur l'adresse publique du portail
de production :

`http://34.54.176.240`

Le chemin contrôlé est :

`/healthz`

Une requête de logs a été enregistrée dans Cloud Logging afin d'isoler
rapidement les erreurs de l'application dans le namespace `foodtrack-prod`.

### Alertes

Une alerte a été configurée à partir de l'uptime check du portail de production.

Une notification par e-mail est envoyée si le portail ne répond plus pendant
une durée de 2 minutes.

Cette durée a été choisie comme compromis entre réactivité et limitation
des fausses alertes provoquées par une interruption très courte.

### IAM et sécurité

L'IAM permet de contrôler qui peut accéder aux ressources du projet et quelles
actions chaque utilisateur ou service peut effectuer.

L'authentification du pipeline GitHub Actions utilise Workload Identity
Federation, ce qui évite de stocker une clé JSON permanente dans le dépôt
ou dans GitHub.

Le compte de service :

`foodtrack-ci@form-gke-eleve04-42a1.iam.gserviceaccount.com`

possède notamment les rôles :

- `roles/artifactregistry.writer`
- `roles/container.developer`

La configuration du node pool a également montré que ce même compte de service
est utilisé par les nœuds GKE.

Cette mutualisation fonctionne, mais une amélioration serait de séparer
le compte utilisé par la CI/CD de celui utilisé par les nœuds afin de mieux
respecter le principe du moindre privilège.

Les autres contrôles réalisés portent sur :

- les comptes de service et leurs rôles
- les règles de pare-feu
- l'accès SSH au bastion
- l'accès au plan de contrôle GKE
- l'absence de secrets dans le dépôt Git
- l'origine, le versionnement et le scan des images Docker

### Script Python de contrôle de santé

Un script Python permet de vérifier automatiquement l'état du service FoodTrack.

Le script interroge l'API, vérifie le code HTTP retourné, mesure le temps
de réponse et affiche un résultat lisible.

Il retourne un code de sortie `0` si le service fonctionne correctement
et un code différent de `0` en cas d'erreur.

L'URL est fournie au lancement du script afin de pouvoir utiliser le même script
sur plusieurs environnements sans modifier le code.

Un test réalisé sur l'API de production a retourné un code HTTP 200
avec une latence d'environ 0,066 seconde.

### Scripts Bash

Trois scripts Bash permettent d'automatiser des tâches d'exploitation courantes :

- `backup-config.sh` crée une archive horodatée des fichiers de configuration
  et l'envoie dans le bucket Cloud Storage `foodtrack-d-backup-dev`
- `purge-old-logs.sh` supprime les exports de logs âgés de plus de 30 jours
  afin d'éviter l'accumulation de fichiers inutiles
- `cluster-schedule.sh` permet de réduire le node pool GKE à zéro pendant
  les périodes d'inactivité puis de le redémarrer lorsque l'environnement
  doit être utilisé

Le script d'arrêt désactive l'autoscaling avant de réduire le node pool à zéro.

Lors du redémarrage, il remet un nœud puis réactive l'autoscaling entre
1 et 5 nœuds.

Ces scripts utilisent `set -euo pipefail` afin d'arrêter leur exécution
lorsqu'une erreur est détectée.

### Coûts

Une analyse des coûts a été réalisée à partir de la configuration réelle
du node pool et du Google Cloud Pricing Calculator.

Les principaux paramètres utilisés sont :

- 4 nœuds
- type de machine `e2-medium`
- région `europe-west4`
- disques `pd-standard`
- 50 GiB par nœud
- provisionnement standard

Deux scénarios ont été comparés.

Pour un fonctionnement continu d'environ 730 heures par mois,
le coût estimé est de :

`116,51 $ par mois`

Pour une utilisation limitée à environ 365 heures par mois,
soit environ 12 heures par jour, le coût estimé est de :

`58,25 $ par mois`

L'économie estimée est donc de :

`58,26 $ par mois`

soit environ 50 % sur les ressources de calcul simulées.

Cette estimation ne représente pas l'ensemble de la facture Google Cloud,
car certaines ressources comme les volumes persistants, les équilibreurs
de charge, Cloud Storage ou le trafic réseau peuvent continuer à générer
des coûts lorsque le node pool est arrêté.

### Audit

Un audit de sécurité a été réalisé afin de vérifier la conformité
de l'infrastructure avec les exigences du projet.

Les contrôles ont porté sur :

- les accès IAM
- les comptes de service
- les règles de pare-feu
- le bastion
- le plan de contrôle GKE
- les secrets
- les images Docker
- les résultats des scans Trivy

Les scans Terraform ont permis de corriger plusieurs problèmes de sécurité,
notamment les anciens endpoints de métadonnées et la configuration
des métadonnées des nœuds.

Le plan de contrôle GKE reste accessible depuis `0.0.0.0/0`.

Cette exception est documentée car les runners GitHub Actions utilisent
des adresses IP dynamiques. La sécurité de l'accès repose donc principalement
sur IAM et Workload Identity Federation.

Les scans Kubernetes ont également identifié des améliorations possibles
sur les contextes de sécurité des conteneurs.

L'audit complet est documenté dans :

`docs/audit.md`

La configuration de sécurité détaillée est disponible dans :

`docs/securite.md`

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
gcloud storage buckets create gs://foodtrack-d-tfstate-form-gke-eleve04-42a1 \
  --location=europe-west4 --uniform-bucket-level-access
gcloud storage buckets update gs://foodtrack-d-tfstate-form-gke-eleve04-42a1 --versioning
```

Le versionnage est activé sur ce bucket pour permettre de revenir à une version antérieure du state en cas de corruption ou de mauvaise manipulation. Aucune autre ressource du projet n'est créée en dehors de Terraform.

<!-- demo soutenance -->
