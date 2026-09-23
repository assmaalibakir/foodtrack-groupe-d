param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("dev", "test", "prod")]
    [string]$Environnement
)

$ErrorActionPreference = "Stop"

$RacineProjet = Split-Path -Parent $PSScriptRoot
$Namespace = "foodtrack-$Environnement"
$Overlay = Join-Path $RacineProjet "k8s\overlays\$Environnement"
$NamespaceYaml = Join-Path $Overlay "namespace.yaml"
$ConfigurationCluster = Join-Path $RacineProjet "k8s\cluster"

function Wait-Workload {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Ressource
    )

    & kubectl rollout status $Ressource -n $Namespace --timeout=5m

    if ($LASTEXITCODE -ne 0) {
        throw "Echec du rollout de $Ressource dans $Namespace."
    }
}

$Contexte = & kubectl config current-context 2>$null

if ($LASTEXITCODE -ne 0) {
    throw "Aucun cluster Kubernetes configure."
}

Write-Host "Contexte      : $Contexte"
Write-Host "Environnement : $Environnement"
Write-Host "Namespace     : $Namespace"

$Confirmation = Read-Host "Tapez DEPLOYER pour continuer"

if ($Confirmation -cne "DEPLOYER") {
    throw "Deploiement annule."
}

Write-Host ""
Write-Host "Creation du namespace..."

& kubectl apply -f $NamespaceYaml

if ($LASTEXITCODE -ne 0) {
    throw "Echec de la creation du namespace."
}

Write-Host ""
Write-Host "Installation de la StorageClass..."

& kubectl apply -k $ConfigurationCluster

if ($LASTEXITCODE -ne 0) {
    throw "Echec de la StorageClass."
}

& kubectl get secret foodtrack-api-config -n $Namespace 2>$null | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "Secret absent. Executez d'abord scripts\creer-secrets-k8s.ps1 -Environnement $Environnement"
}

Write-Host ""
Write-Host "Application des ressources $Environnement..."

& kubectl apply -k $Overlay

if ($LASTEXITCODE -ne 0) {
    throw "Echec du deploiement Kubernetes."
}

Write-Host ""
Write-Host "Attente des workloads..."

Wait-Workload -Ressource "deployment/portail-qualite"
Wait-Workload -Ressource "deployment/api-capteurs"
Wait-Workload -Ressource "statefulset/cache-releves"

Write-Host ""
Write-Host "Etat final..."

& kubectl get pods,services,pvc,hpa,ingress -n $Namespace

if ($LASTEXITCODE -ne 0) {
    throw "Impossible de lire l'etat final de $Namespace."
}

Write-Host ""
Write-Host "DEPLOIEMENT $Environnement TERMINE" -ForegroundColor Green