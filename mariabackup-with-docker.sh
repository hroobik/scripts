#!/bin/bash

# Configuration
BACKUP_DIR=""
DATA_DIR=""
FULL_BACKUP_DIR="$BACKUP_DIR/full"
INCREMENTAL_BACKUP_DIR="$BACKUP_DIR/incremental"
LAST_FULL_BACKUP_DATE_FILE="$BACKUP_DIR/last_full_backup_date.txt"

# Docker image name for MariaDB with mariabackup
MARIADB_IMAGE="mariadb:10.3.39"

# Ensure backup directories exist
mkdir -p "$FULL_BACKUP_DIR"
mkdir -p "$INCREMENTAL_BACKUP_DIR"

# Determine the type of backup to perform
DAY_OF_WEEK=$(date +%u) # 1=Monday, 7=Sunday
if [[ $DAY_OF_WEEK == 1 || ! -f "$LAST_FULL_BACKUP_DATE_FILE" ]]; then
    BACKUP_TYPE="full"
else
    BACKUP_TYPE="incremental"
fi

# Perform the backup operation
if [[ $BACKUP_TYPE == "full" ]]; then
    echo "Performing full backup..."
    docker run --rm \
        --volume "$DATA_DIR:/var/lib/mysql:ro" \
        --volume "$FULL_BACKUP_DIR:/backup" \
        --user "$(id -u):$(id -g)" \
        $MARIADB_IMAGE \
        mariabackup --backup --host=  --user= --password= --target-dir=/backup/$(date +%F) --datadir=/var/lib/mysql

    # Record the date of the full backup
    date +%F > "$LAST_FULL_BACKUP_DATE_FILE"
else
    echo "Performing incremental backup..."
    LAST_FULL_BACKUP_DATE=$(cat "$LAST_FULL_BACKUP_DATE_FILE")
    docker run --rm \
        --volume "$DATA_DIR:/var/lib/mysql:ro" \
        --volume "$INCREMENTAL_BACKUP_DIR:/backup" \
        --user "$(id -u):$(id -g)" \
        $MARIADB_IMAGE \
        mariabackup --backup --host=  --user= --password= --target-dir=/backup/$(date +%F) --incremental-basedir=/backup/$LAST_FULL_BACKUP_DATE --datadir=/var/lib/mysql

