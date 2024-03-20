#!/bin/bash

# Configuration
BACKUP_DIR=""
GALERA_VIP=""
DB_USER=""
DB_PASS=""
SLACK_WEBHOOK_URL=""

# Timestamp for backup filename
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="${BACKUP_DIR}/galera_backup_${TIMESTAMP}.xbstream.gz"

# Start timer
START_TIME=$(date +%s)

# Perform the backup
echo "Starting backup to ${BACKUP_FILE}"
mariabackup --backup --host=${GALERA_VIP} --port=${GALERA_PORT} --user=${DB_USER} --password=${DB_PASS} --stream=xbstream | gzip > "${BACKUP_FILE}"

if [ $? -eq 0 ]; then
    echo "Backup successfully completed"
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MESSAGE="EDIR Galera backup took $DURATION seconds."
    curl -X POST --data-urlencode "payload={\"text\": \"${MESSAGE}\"}" ${SLACK_WEBHOOK_URL}
    else
    echo "Backup failed"
    exit 1
fi

