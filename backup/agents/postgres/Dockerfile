FROM nomad-backup-base:local
RUN apk add --no-cache postgresql-client
COPY backup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/backup.sh
