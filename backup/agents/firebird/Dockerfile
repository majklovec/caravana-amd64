FROM firebirdsql/firebird

RUN apt update && apt install -y restic
COPY backup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/backup.sh
CMD ["/usr/local/bin/backup.sh"]
