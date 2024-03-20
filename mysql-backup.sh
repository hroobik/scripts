#!/bin/bash

# Configuration
BACKUP_DIR="/backup-galera"
GALERA_VIP="<ip_address_of_mysql>"
GALERA_PORT="3306"
DB_USER="<db_username>"
DB_PASS="<db_password>"
SLACK_WEBHOOK_URL="<yourslack_url>"



# Timestamp for backup filename
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="${BACKUP_DIR}/galera_backup_${TIMESTAMP}.sql"


#timer_start
START_TIME=$(date +%s)


# Perform the backup
echo "Starting backup to ${BACKUP_FILE}"
 mysqldump --host=${GALERA_VIP}  --user=${DB_USER} --password=${DB_PASS}  --databases db1 db2  --skip-lock-tables |  pigz -9  > "${BACKUP_FILE}"
if [ $? -eq 0 ]; then
    echo "Backup successfully completed"
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    DURATION_MINUTES=$(echo "scale=2; $DURATION / 60" | bc)
    MESSAGE="EDIR database dump took $DURATION_MINUTES Minutes."
    curl -X POST --data-urlencode "payload={\"text\": \"${MESSAGE}\"}" ${SLACK_WEBHOOK_URL}
else
    echo "Backup failed"
    exit 1
fi

