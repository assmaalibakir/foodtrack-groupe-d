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