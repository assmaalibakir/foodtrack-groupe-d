param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("dev", "test", "prod")]
    [string]$Environnement
)

$ErrorActionPreference = "Stop"

$Namespace = "foodtrack-$Environnement"
$SecretName = "foodtrack-api-config"

function New-RandomSecret {
    param([int]$NombreOctets = 32)

    $Octets = New-Object byte[] $NombreOctets
    $Generateur = [System.Security.Cryptography.RandomNumberGenerator]::Create()

    try {
        $Generateur.GetBytes($Octets)
    }
    finally {
        $Generateur.Dispose()
    }

    return [Convert]::ToBase64String($Octets).
        TrimEnd("=").
        Replace("+", "-").
        Replace("/", "_")
}

$Contexte = & kubectl config current-context 2>$null

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Contexte)) {
    throw "Aucun cluster Kubernetes n'est configure dans kubectl."
}

Write-Host "Contexte Kubernetes : $Contexte"
Write-Host "Namespace cible      : $Namespace"

$Confirmation = Read-Host "Confirmer la creation du Secret ? (O/N)"

if ($Confirmation -notin @("O", "o")) {
    throw "Operation annulee."
}

& kubectl get namespace $Namespace -o name | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "Le namespace $Namespace n'existe pas dans le cluster."
}

& kubectl get secret $SecretName -n $Namespace -o name 2>$null | Out-Null

if ($LASTEXITCODE -eq 0) {
    throw "Le Secret $SecretName existe deja dans $Namespace. Aucune modification effectuee."
}

$IngestToken = New-RandomSecret
$CachePassword = New-RandomSecret

$Manifeste = [ordered]@{
    apiVersion = "v1"
    kind       = "Secret"
    metadata   = [ordered]@{
        name      = $SecretName
        namespace = $Namespace
    }
    type       = "Opaque"
    stringData = [ordered]@{
        INGEST_TOKEN   = $IngestToken
        CACHE_PASSWORD = $CachePassword
    }
} | ConvertTo-Json -Depth 6 -Compress

$Manifeste | & kubectl create -f -

if ($LASTEXITCODE -ne 0) {
    throw "Echec de la creation du Secret."
}

Remove-Variable IngestToken, CachePassword, Manifeste

Write-Host "Secret cree dans $Namespace."
Write-Host "Les valeurs n'ont pas ete affichees ni enregistrees dans un fichier."
