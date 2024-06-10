#!/bin/bash

set -euo pipefail

# Default values
DAYS=2
BACKUPDIR="${HOME}/backups-docker"  # Utilisation de ${HOME} pour le répertoire personnel
LOGFILE="/var/log/docker-db-backup.log"

# Utilisation de `printf` pour plus de contrôle sur le formatage des messages
show_help() {
  printf "Usage: %s [-h] [-d DAYS] [-b BACKUPDIR]\n" "$0"
  printf "  -h: Display this help message\n"
  printf "  -d DAYS: Number of days to retain backups (default: %d)\n" "$DAYS"
  printf "  b BACKUPDIR: Directory to store backups (default: %s)\n" "$BACKUPDIR"
}

# Gestion des arguments en ligne de commande
while getopts ":hd:b:" opt; do
  case $opt in
    h) show_help; exit 0 ;;
    d) DAYS="$OPTARG" ;;
    b) BACKUPDIR="$OPTARG" ;;
    \?)
      printf "Invalid option: -%s\n" "$OPTARG" >&2
      show_help; exit 1 
      ;;
    :)
      printf "Option -%s requires an argument.\n" "$OPTARG" >&2
      show_help; exit 1
      ;;
  esac
done

TIMESTAMP=$(date +"%Y%m%d-%H%M")

# Fonction de journalisation (log)
log() {
  printf "%s - %s - %s\n" "$TIMESTAMP" "$0" "$*" >> "$LOGFILE"
}

# Vérification et création du répertoire de sauvegarde
if [ ! -d "$BACKUPDIR" ]; then
  mkdir -p "$BACKUPDIR"
  log "Created backup directory: $BACKUPDIR"
fi

# Fonction pour la sauvegarde d'un conteneur
backup_container() {
  local CONTAINER_NAME="$1"
  local BACKUP_CMD="$2"
  local FILENAME="$BACKUPDIR/$CONTAINER_NAME-$TIMESTAMP.sql.gz"

  log "Starting backup for: $CONTAINER_NAME"
  
  # Exécution de la commande de sauvegarde à l'intérieur du conteneur
  # Redirection de la sortie standard vers gzip pour la compression
  # Gestion des erreurs avec `||` pour capturer les échecs
  if ! docker exec "$CONTAINER_NAME" sh -c "$BACKUP_CMD" | gzip > "$FILENAME"; then
    log "ERROR: Backup failed for $CONTAINER_NAME"
    return 1
  fi
  
  log "Backup successful for: $CONTAINER_NAME"

  # Suppression des anciennes sauvegardes
  find "$BACKUPDIR" -name "$CONTAINER_NAME-*.sql.gz" -mtime +"$DAYS" -delete
}

# Boucle sur les conteneurs MariaDB/MySQL
while IFS=':' read -r CONTAINER IMAGE; do
  if [[ "$IMAGE" =~ (mysql|mariadb) ]]; then  # Filtrage sur le nom de l'image
    # Obtention des variables d'environnement du conteneur 
    MYSQL_DATABASE=$(docker exec "$CONTAINER" sh -c 'echo "$MYSQL_DATABASE"') 
    MYSQL_PWD=$(docker exec "$CONTAINER" sh -c 'echo "$MYSQL_ROOT_PASSWORD"') 
    BACKUP_CMD="mysqldump -u root -p'$MYSQL_PWD' '$MYSQL_DATABASE'"
    backup_container "$CONTAINER" "$BACKUP_CMD"
  fi
done < <(docker ps --format '{{.Names}}:{{.Image}}') # Redirection de la sortie

log "All database backups completed."
