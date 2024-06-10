#!/bin/bash

set -euo pipefail

# Default values
DAYS=2
BACKUPDIR="/home/user/backups-docker"

# Function to display usage information
show_help() {
  echo "Usage: $0 [-h] [-d DAYS] [-b BACKUPDIR]"
  echo "  -h: Display this help message"
  echo "  -d DAYS: Number of days to retain backups (default: $DAYS)"
  echo "  -b BACKUPDIR: Directory to store backups (default: $BACKUPDIR)"
}

# Parse command-line arguments
while getopts ":hd:b:" opt; do
  case $opt in
    h)
      show_help
      exit 0
      ;;
    d)
      DAYS=$OPTARG
      ;;
    b)
      BACKUPDIR=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      show_help
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      show_help
      exit 1
      ;;
  esac
done

TIMESTAMP=$(date +"%Y%m%d%H%M")

# Function to log messages with timestamp and script name
log() {
  echo "$TIMESTAMP - $0 - $*" >> "/var/log/docker-db-backup.log"
}

# Verification and creation of backup directory
if [ ! -d "$BACKUPDIR" ]; then
  mkdir -p "$BACKUPDIR"
  log "Created backup directory: $BACKUPDIR"
fi

# Function to perform backup and clean up old backups
backup_container() {
  local CONTAINER_NAME=$1
  local BACKUP_CMD=$2
  local FILENAME="$BACKUPDIR/$CONTAINER_NAME-$TIMESTAMP.sql.gz"

  log "Starting backup for: $CONTAINER_NAME"
  if ! sudo docker exec "$CONTAINER_NAME" $BACKUP_CMD | gzip > "$FILENAME"; then
    log "ERROR: Backup failed for $CONTAINER_NAME"
    return 1  # Return an error code to indicate failure
  fi
  log "Backup successful for: $CONTAINER_NAME"

  # Clean up old backups (optional)
  find "$BACKUPDIR" -name "$CONTAINER_NAME*.gz" -daystart -mtime +$DAYS -delete
}

# Backup for each MariaDB/MySQL container
sudo docker ps --format '{{.Names}}:{{.Image}}' | grep -E 'mysql|mariadb' | cut -d":" -f1 | while read -r CONTAINER; do
  MYSQL_DATABASE=$(docker exec $CONTAINER env | grep MYSQL_DATABASE | cut -d"=" -f2-)
  MYSQL_PWD=$(docker exec $CONTAINER env | grep MYSQL_ROOT_PASSWORD | cut -d"=" -f2-)

  BACKUP_CMD="/usr/bin/mysqldump -u root -p$MYSQL_PWD $MYSQL_DATABASE"
  backup_container "$CONTAINER" "$BACKUP_CMD"
done

log "All database backups completed."
