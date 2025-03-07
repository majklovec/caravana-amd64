#!/bin/bash
set -eo pipefail

HOST="$1"
PORT="$2"
USER="$3"
PASSWORD="$4"
RETENTION_DAYS="$5"

export RESTIC_REPO="/restic-repo"
export RESTIC_PASSWORD="${RESTIC_PASSWORD}"

restic list snapshots || restic init

mysqldump \
  --host="$HOST" \
  --port="$PORT" \
  --user="$USER" \
  --password="$PASSWORD" \
  --all-databases \
  --single-transaction \
  --triggers \
  --routines \
  --events \
  | restic backup --stdin --stdin-filename "mysql-all-$(date +%Y%m%d).sql"

restic forget --keep-daily "$RETENTION_DAYS" --prune
