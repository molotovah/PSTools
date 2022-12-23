# Récupération de la liste des processus en cours d'exécution
$processes = Get-Process

# Pour chaque processus
foreach ($process in $processes)
{
    # Vérification si le nom du processus correspond à un navigateur ou à Microsoft Teams
    if ($process.Name -in @("chrome", "firefox", "edge", "opera", "safari", "Teams"))
    {
        # Arrêt du processus
        Stop-Process -Name $process.Name
    }
}

# Récupération de la liste des dossiers de profils d'utilisateur
$profiles = Get-ChildItem -Path "C:\Users"

# Initialisation du compteur de données supprimées
$dataDeleted = 0

# Pour chaque profil d'utilisateur
foreach ($profile in $profiles)
{
    # Vérification que le dossier de profil est bien un profil d'utilisateur (et pas par exemple "Default" ou "Public")
    if ($profile.PSIsContainer -and $profile.Name -ne "Default" -and $profile.Name -ne "Public")
    {
        # Netoyage des caches de tous les navigateurs web installés
        $browsers = @("chrome", "firefox", "edge", "opera", "safari")
        foreach ($browser in $browsers)
        {
            # Récupération du chemin vers le cache du navigateur
            $cachePath = Join-Path -Path $profile.FullName -ChildPath "AppData\Local\$browser\User Data\Default\Cache"

            # Suppression des fichiers du cache
            Get-ChildItem -Path $cachePath | Remove-Item -Force
        }

        # Netoyage du cache de Microsoft Teams
        $teamsCachePath = Join-Path -Path $profile.FullName -ChildPath "AppData\Roaming\Microsoft\Teams\Cache"
        Get-ChildItem -Path $teamsCachePath | Remove-Item -Force

        # Mise à jour du compteur de données supprimées
        $dataDeleted += (Get-ChildItem -Path $cachePath | Measure-Object -Property Length -Sum).Sum
        $dataDeleted += (Get-ChildItem -Path $teamsCachePath | Measure-Object -Property Length -Sum).Sum
    }
}

# Affichage de la quantité totale de données supprimées
Write-Output "Total data deleted: $dataDeleted bytes"
