@echo off
chcp 65001 > nul 2>&1
:: Vérifier si l'exécution en tant qu'administrateur est nécessaire
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Vous êtes déjà administrateur.
) else (
    echo Demande d'élévation en tant qu'administrateur...
    powershell -command "Start-Process '%0' -Verb RunAs"
    exit
)

:: Vérifier l'existence de OcsService.exe
if not exist "C:\Program Files (x86)\OCS Inventory Agent\OcsService.exe" (
    echo OCS Inventory n'est pas installé sur ce système.
    pause
    exit
)

:: Arrêter le service OCS Inventory Service s'il est en cours d'exécution
net stop "OCS Inventory Service" > nul 2>&1

:: Vérifier et modifier le fichier ocsinventory.ini
set "iniFile=C:\ProgramData\OCS Inventory NG\Agent\ocsinventory.ini"

:: Vérifier si le fichier existe
if not exist "%iniFile%" (
    echo Le fichier ocsinventory.ini n'a pas été trouvé.
    pause
    exit
)

:: Créer un fichier temporaire pour stocker les modifications
set "tempFile=%temp%\ocsinventory_tmp.ini"
if exist "%tempFile%" del "%tempFile%"

:: Lire et modifier le fichier ocsinventory.ini
for /f "usebackq tokens=*" %%a in ("%iniFile%") do (
    set "line=%%a"
    setlocal enabledelayedexpansion
    if "!line!"=="SSL=1" (
        set "line=SSL=0"
        echo SSL était activé. Il a été désactivé.
    ) else if "!line!"=="SSL=0" (
        echo SSL est déjà désactivé.
    )
    echo !line! >> "%tempFile%"
    endlocal
)

:: Remplacer l'ancien fichier par le nouveau si des modifications ont été effectuées
if exist "%tempFile%" (
    move /y "%tempFile%" "%iniFile%" > nul 2>&1
    :: Redémarrer le service OCS Inventory Service
    net start "OCS Inventory Service" > nul 2>&1
    echo Les modifications ont été apportées au fichier ocsinventory.ini. Veuillez relancer un inventaire manuel via la systembar
) else (
    echo Aucune modification nécessaire.
)

:: Fin du script
pause
