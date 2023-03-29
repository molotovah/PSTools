# Demander à l'utilisateur quand il veut que la tâche redémarre l'ordinateur
$Date = Read-Host -Prompt "Entrez les jours de la semaine (par exemple, lundi,mardi) : "
$Time = Read-Host -Prompt "Entrez l'heure (par exemple, 23:00) : "

# Créer une action pour redémarrer l'ordinateur
$Action = New-ScheduledTaskAction -Execute 'shutdown.exe' -Argument '/r /t 0'

# Créer un déclencheur pour la tâche planifiée
$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $Date.Split(",") -At $Time

# Créer une tâche planifiée pour redémarrer l'ordinateur
Register-ScheduledTask -TaskName "Redémarrage de l'ordinateur" -Trigger $Trigger -Action $Action -User "SYSTEM"
