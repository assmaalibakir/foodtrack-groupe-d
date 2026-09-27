# Valide les rendus Kustomize sans modifier le cluster.
$ErrorActionPreference = "Stop"

# Controle un dossier Kustomize, ses ressources et ses valeurs attendues.
function Test-Kustomize {
    param(
        [string]$Nom,
        [string]$Chemin,
        [int]$NombreAttendu,
        [string[]]$KindsAttendus,
        [hashtable]$ValeursAttendues = @{}
    )

    # kubectl kustomize assemble les manifestes localement sans les appliquer.
    $Sortie = & kubectl kustomize $Chemin 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "$Nom - erreur de rendu : $Sortie"
    }

    # Une occurrence de kind: correspond a une ressource YAML rendue.
    $Texte = $Sortie -join "`n"
    $NombreRessources = ([regex]::Matches($Texte, "(?m)^kind:\s*")).Count

    if ($NombreRessources -ne $NombreAttendu) {
        throw "$Nom - $NombreRessources ressources au lieu de $NombreAttendu"
    }

    # Un Secret reel ne doit jamais apparaitre dans les fichiers versionnes.
    if ($Texte -match "(?m)^kind:\s*Secret\s*$") {
        throw "$Nom - un Secret apparait dans le rendu"
    }

    # Verifie que chaque famille de ressources obligatoire est presente.
    foreach ($Kind in $KindsAttendus) {
        if ($Texte -notmatch "(?m)^kind:\s*$Kind\s*$") {
            throw "$Nom - ressource $Kind absente"
        }
    }

    # Controle les parametres propres a l'environnement dans la ConfigMap rendue.
    foreach ($Cle in $ValeursAttendues.Keys) {
        $Valeur = [regex]::Escape([string]$ValeursAttendues[$Cle])
        $CleRegex = [regex]::Escape($Cle)
        $Motif = "(?m)^\s*${CleRegex}:\s*['\x22]?$Valeur['\x22]?\s*$"

        if ($Texte -notmatch $Motif) {
            throw "$Nom - valeur attendue absente : $Cle=$($ValeursAttendues[$Cle])"
        }
    }

    # Le nom stable est necessaire aux montages subPath des fichiers du portail.
    if ($Nom -ne "cluster" -and $Texte -notmatch "(?m)^\s*name:\s*foodtrack-config\s*$") {
        throw "$Nom - le ConfigMap doit porter exactement le nom foodtrack-config"
    }

    Write-Host "$Nom - OK - $NombreRessources ressources" -ForegroundColor Green
}

# Types de ressources attendus pour chaque environnement applicatif.
$KindsApplication = @(
    "Namespace",
    "ConfigMap",
    "Service",
    "Deployment",
    "StatefulSet",
    "HorizontalPodAutoscaler",
    "BackendConfig",
    "Ingress"
)

# Developpement : seuil 8 C et journalisation detaillee.
Test-Kustomize `
    -Nom "dev" `
    -Chemin ".\k8s\overlays\dev" `
    -NombreAttendu 11 `
    -KindsAttendus $KindsApplication `
    -ValeursAttendues @{
        ENVIRONMENT = "dev"
        SEUIL_TEMPERATURE_C = "8"
        NIVEAU_JOURNAL = "debug"
    }

# Test : seuil 2 C et journalisation informative.
Test-Kustomize `
    -Nom "test" `
    -Chemin ".\k8s\overlays\test" `
    -NombreAttendu 11 `
    -KindsAttendus $KindsApplication `
    -ValeursAttendues @{
        ENVIRONMENT = "test"
        SEUIL_TEMPERATURE_C = "2"
        NIVEAU_JOURNAL = "info"
    }

# Production : seuil 4 C et journaux limites aux avertissements.
Test-Kustomize `
    -Nom "prod" `
    -Chemin ".\k8s\overlays\prod" `
    -NombreAttendu 11 `
    -KindsAttendus $KindsApplication `
    -ValeursAttendues @{
        ENVIRONMENT = "prod"
        SEUIL_TEMPERATURE_C = "4"
        NIVEAU_JOURNAL = "warn"
    }

# Cluster : une seule StorageClass commune aux trois environnements.
Test-Kustomize `
    -Nom "cluster" `
    -Chemin ".\k8s\cluster" `
    -NombreAttendu 1 `
    -KindsAttendus @("StorageClass") `
    -ValeursAttendues @{
        provisioner = "pd.csi.storage.gke.io"
        type = "pd-standard"
        volumeBindingMode = "WaitForFirstConsumer"
    }

# Ce message n'est atteint que si toutes les validations ont reussi.
Write-Host ""
Write-Host "VALIDATION KUBERNETES REUSSIE" -ForegroundColor Green
