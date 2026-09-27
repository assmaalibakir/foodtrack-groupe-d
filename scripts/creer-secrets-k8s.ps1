# Cree le Secret attendu par l'API et Redis sans ecrire ses valeurs sur disque.
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("dev", "test", "prod")]
    [string]$Environnement
)

# Toute erreur arrete immediatement le script.
$ErrorActionPreference = "Stop"

# Les noms sont derives de l'environnement pour eviter les erreurs de saisie.
$Namespace = "foodtrack-$Environnement"
$SecretName = "foodtrack-api-config"

# Genere une valeur aleatoire avec le generateur cryptographique de .NET.
function New-RandomSecret {
    param([int]$NombreOctets = 32)

    $Octets = New-Object byte[] $NombreOctets
    $Generateur = [System.Security.Cryptography.RandomNumberGenerator]::Create()

    try {
        # Remplit le tableau sans utiliser un generateur pseudo-aleatoire classique.
        $Generateur.GetBytes($Octets)
    }
    finally {
        $Generateur.Dispose()
    }

    # Utilise un Base64 adapte aux variables et aux arguments de commande.
    return [Convert]::ToBase64String($Octets).
        TrimEnd("=").
        Replace("+", "-").
        Replace("/", "_")
}

# Refuse de continuer si kubectl ne pointe vers aucun cluster.
$Contexte = & kubectl config current-context 2>$null

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Contexte)) {
    throw "Aucun cluster Kubernetes n'est configure dans kubectl."
}

Write-Host "Contexte Kubernetes : $Contexte"
Write-Host "Namespace cible      : $Namespace"

# Demande une confirmation explicite avant toute creation.
$Confirmation = Read-Host "Confirmer la creation du Secret ? (O/N)"

if ($Confirmation -notin @("O", "o")) {
    throw "Operation annulee."
}

# Le namespace doit deja avoir ete cree par son manifeste.
& kubectl get namespace $Namespace -o name | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "Le namespace $Namespace n'existe pas dans le cluster."
}

# Ne remplace jamais silencieusement un Secret existant.
& kubectl get secret $SecretName -n $Namespace -o name 2>$null | Out-Null

if ($LASTEXITCODE -eq 0) {
    throw "Le Secret $SecretName existe deja dans $Namespace. Aucune modification effectuee."
}

# Les deux valeurs sont generees separement et conservees uniquement en memoire.
$IngestToken = New-RandomSecret
$CachePassword = New-RandomSecret

# Construit un manifeste JSON en memoire ; aucun fichier sensible n'est cree.
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

# Transmet le manifeste directement a l'entree standard de kubectl.
$Manifeste | & kubectl create -f -

if ($LASTEXITCODE -ne 0) {
    throw "Echec de la creation du Secret."
}

# Retire les valeurs sensibles de la session PowerShell apres utilisation.
Remove-Variable IngestToken, CachePassword, Manifeste

Write-Host "Secret cree dans $Namespace."
Write-Host "Les valeurs n'ont pas ete affichees ni enregistrees dans un fichier."
