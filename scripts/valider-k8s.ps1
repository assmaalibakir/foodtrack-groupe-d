$ErrorActionPreference = "Stop"

function Test-Kustomize {
    param(
        [string]$Nom,
        [string]$Chemin,
        [int]$NombreAttendu,
        [string[]]$KindsAttendus
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

Test-Kustomize -Nom "dev" -Chemin ".\k8s\overlays\dev" -NombreAttendu 11 -KindsAttendus $KindsApplication
Test-Kustomize -Nom "test" -Chemin ".\k8s\overlays\test" -NombreAttendu 11 -KindsAttendus $KindsApplication
Test-Kustomize -Nom "prod" -Chemin ".\k8s\overlays\prod" -NombreAttendu 11 -KindsAttendus $KindsApplication
Test-Kustomize -Nom "cluster" -Chemin ".\k8s\cluster" -NombreAttendu 1 -KindsAttendus @("StorageClass")

Write-Host ""
Write-Host "VALIDATION KUBERNETES REUSSIE" -ForegroundColor Green
