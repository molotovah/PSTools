$Date = Read-Host -Prompt "Entrez les jours de la semaine en Anglais (par exemple, monday,tuesday) : "
$Time = Read-Host -Prompt "Entrez l'heure (par exemple, 23:00) : "
$taskName = If ([System.Environment]::OSVersion.Version.Major -eq 10) {"Reboot PC"} else {"Reboot Serveur"}
$action = New-ScheduledTaskAction -Execute 'shutdown.exe' -Argument '/r /t 0'
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $Date.Split(",") -At $Time
$settings = New-ScheduledTaskSettingsSet -Compatibility Win8 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Trigger $trigger -Settings $settings
