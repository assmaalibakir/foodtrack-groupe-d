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

& kubectl rollout status deployment/portail-qualite -n $Namespace --timeout=5m
& kubectl rollout status deployment/api-capteurs -n $Namespace --timeout=5m
& kubectl rollout status statefulset/cache-releves -n $Namespace --timeout=5m

Write-Host ""
Write-Host "Etat final..."

& kubectl get pods,services,pvc,hpa,ingress -n $Namespace

Write-Host ""
Write-Host "DEPLOIEMENT $Environnement TERMINE" -ForegroundColor Green
