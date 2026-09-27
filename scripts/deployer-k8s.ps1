# Deploie un overlay Kustomize apres confirmation et controles prealables.
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("dev", "test", "prod")]
    [string]$Environnement
)

# Toute erreur arrete immediatement le script.
$ErrorActionPreference = "Stop"

# Construit les chemins a partir de la position du script dans le depot.
$RacineProjet = Split-Path -Parent $PSScriptRoot
$Namespace = "foodtrack-$Environnement"
$Overlay = Join-Path $RacineProjet "k8s\overlays\$Environnement"
$NamespaceYaml = Join-Path $Overlay "namespace.yaml"
$ConfigurationCluster = Join-Path $RacineProjet "k8s\cluster"

# Attend qu'un Deployment ou StatefulSet termine son rollout.
function Wait-Workload {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Ressource
    )

    # Un delai de cinq minutes evite une attente sans fin.
    & kubectl rollout status $Ressource -n $Namespace --timeout=5m

    if ($LASTEXITCODE -ne 0) {
        throw "Echec du rollout de $Ressource dans $Namespace."
    }
}

# Refuse de deployer si kubectl ne pointe vers aucun cluster.
$Contexte = & kubectl config current-context 2>$null

if ($LASTEXITCODE -ne 0) {
    throw "Aucun cluster Kubernetes configure."
}

Write-Host "Contexte      : $Contexte"
Write-Host "Environnement : $Environnement"
Write-Host "Namespace     : $Namespace"

# Exige une confirmation explicite pour limiter les erreurs d'environnement.
$Confirmation = Read-Host "Tapez DEPLOYER pour continuer"

if ($Confirmation -cne "DEPLOYER") {
    throw "Deploiement annule."
}

Write-Host ""
Write-Host "Creation du namespace..."

# Le namespace est applique separement pour qu'il existe avant les autres ressources.
& kubectl apply -f $NamespaceYaml

if ($LASTEXITCODE -ne 0) {
    throw "Echec de la creation du namespace."
}

Write-Host ""
Write-Host "Installation de la StorageClass..."

# Cette ressource de cluster est commune aux trois environnements.
& kubectl apply -k $ConfigurationCluster

if ($LASTEXITCODE -ne 0) {
    throw "Echec de la StorageClass."
}

# Les workloads ne sont pas appliques tant que leur Secret n'existe pas.
& kubectl get secret foodtrack-api-config -n $Namespace 2>$null | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "Secret absent. Executez d'abord scripts\creer-secrets-k8s.ps1 -Environnement $Environnement"
}

Write-Host ""
Write-Host "Application des ressources $Environnement..."

# Assemble et applique la base avec l'overlay de l'environnement choisi.
& kubectl apply -k $Overlay

if ($LASTEXITCODE -ne 0) {
    throw "Echec du deploiement Kubernetes."
}

Write-Host ""
Write-Host "Attente des workloads..."

# Attend successivement le portail, l'API et Redis.
Wait-Workload -Ressource "deployment/portail-qualite"
Wait-Workload -Ressource "deployment/api-capteurs"
Wait-Workload -Ressource "statefulset/cache-releves"

Write-Host ""
Write-Host "Etat final..."

# Affiche les ressources utiles au controle immediat du deploiement.
& kubectl get pods,services,pvc,hpa,ingress -n $Namespace

if ($LASTEXITCODE -ne 0) {
    throw "Impossible de lire l'etat final de $Namespace."
}

# Ce message n'est atteint que si toutes les etapes ont reussi.
Write-Host ""
Write-Host "DEPLOIEMENT $Environnement TERMINE" -ForegroundColor Green
