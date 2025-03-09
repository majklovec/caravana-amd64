#!/bin/bash
set -eo pipefail

SERVICE_NAME="$1"
SERVICE_HOST="$2"
SERVICE_PORT="$3"
SERVICE_USER="$4"
SERVICE_PASSWORD="$5"
SERVICE_DBNAME="$6"

echo "SERVICE: ${SERVICE_NAME}"
echo "HOST: ${SERVICE_HOST}"
echo "PORT: ${SERVICE_PORT}"
echo "USER: ${SERVICE_USER}"
echo "PASSWORD: ${SERVICE_PASSWORD}"
echo "DBNAME: ${SERVICE_DBNAME}"

echo "RESTIC_REPOSITORY: ${RESTIC_REPOSITORY}"


restic list snapshots || restic init

export PGPASSWORD="$SERVICE_PASSWORD" 
restic backup \
  --tag "db" \
  --tag "postgres" \
  --host "$SERVICE_NAME" \
  --stdin-filename "$SERVICE_DBNAME.sql" \
  --stdin-from-command -- pg_dumpall --host="$SERVICE_HOST" --port="$SERVICE_PORT" --username="$SERVICE_USER" 

restic forget --keep-within-hourly 1d --keep-within-daily 7d --keep-within-weekly 1m --keep-within-monthly 1y --keep-within-yearly 75y --prune
