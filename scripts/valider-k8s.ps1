$ErrorActionPreference = "Stop"

function Test-Kustomize {
    param(
        [string]$Nom,
        [string]$Chemin,
        [int]$NombreAttendu,
        [string[]]$KindsAttendus,
        [hashtable]$ValeursAttendues = @{}
    )

    $Sortie = & kubectl kustomize $Chemin 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "$Nom - erreur de rendu : $Sortie"
    }

    $Texte = $Sortie -join "`n"
    $NombreRessources = ([regex]::Matches($Texte, "(?m)^kind:\s*")).Count

    if ($NombreRessources -ne $NombreAttendu) {
        throw "$Nom - $NombreRessources ressources au lieu de $NombreAttendu"
    }

    if ($Texte -match "(?m)^kind:\s*Secret\s*$") {
        throw "$Nom - un Secret apparait dans le rendu"
    }

    foreach ($Kind in $KindsAttendus) {
        if ($Texte -notmatch "(?m)^kind:\s*$Kind\s*$") {
            throw "$Nom - ressource $Kind absente"
        }
    }

    foreach ($Cle in $ValeursAttendues.Keys) {
        $Valeur = [regex]::Escape([string]$ValeursAttendues[$Cle])
        $CleRegex = [regex]::Escape($Cle)
        $Motif = "(?m)^\s*${CleRegex}:\s*['\x22]?$Valeur['\x22]?\s*$"

        if ($Texte -notmatch $Motif) {
            throw "$Nom - valeur attendue absente : $Cle=$($ValeursAttendues[$Cle])"
        }
    }

    if ($Nom -ne "cluster" -and $Texte -notmatch "(?m)^\s*name:\s*foodtrack-config\s*$") {
        throw "$Nom - le ConfigMap doit porter exactement le nom foodtrack-config"
    }

    Write-Host "$Nom - OK - $NombreRessources ressources" -ForegroundColor Green
}

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

Write-Host ""
Write-Host "VALIDATION KUBERNETES REUSSIE" -ForegroundColor Green