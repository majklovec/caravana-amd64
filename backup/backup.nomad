job "[[.DOMAIN]]" {
  datacenters = [[ .DATACENTERS  | toJson ]]
  type        = "batch"

  periodic {
    cron             = "@hourly"
    prohibit_overlap = true
  }

  group "[[.SERVICE_ID]]" {
    task "backup-script" {
      driver = "exec"

      template {
        data = <<EOH
#!/bin/bash
set -eo pipefail

export NOMAD_TOKEN=[[.NOMAD_TOKEN]]

nomad service list -json | jq -c '.[].Services[] | select(.Tags[]? | contains("backup-enabled"))' | while read -r SVC; do
  SERVICE_NAME=$(echo "$SVC" | jq -r '.ServiceName')
  TAGS=$(echo "$SVC" | jq -r '.Tags | join("\n")')

  # Extract parameters
  BACKUP_TYPE=$(echo "$TAGS" | awk -F= '/^backup-type=/ {print $2}')
  SCHEDULE=$(echo "$TAGS" | awk -F= '/^backup-schedule=/ {print $2}')
  SOURCE_PATH=$(echo "$TAGS" | awk -F= '/^backup-source-path=/ {print $2}')
  DB_USER=$(echo "$TAGS" | awk -F= '/^db-user=/ {print $2}')
  DB_PASSWORD=$(echo "$TAGS" | awk -F= '/^db-password=/ {print $2}')
  DB_NAME=$(echo "$TAGS" | awk -F= '/^db-name=/ {print $2}')
  
  # Get service info and parse IP/Port
  SERVICE_INFO=$(nomad service info -json "$SERVICE_NAME")
  NOMAD_UPSTREAM_IP=$(echo "$SERVICE_INFO" | jq -r '.[0].Address')
  NOMAD_UPSTREAM_PORT=$(echo "$SERVICE_INFO" | jq -r '.[0].Port')  

  # Generate Nomad job HCL with embedded values
  cat > "local/backup-${SERVICE_NAME}.hcl" <<JOB
job "backup-${SERVICE_NAME}" {
  type        = "batch"
  datacenters = ["dc1"]

  group "backup" {
    task "runner" {
      driver = "docker"

      config {
        image = "nomad-backup-${BACKUP_TYPE}:local"
        command = "backup.sh"
        args = ["${SERVICE_NAME}", "${NOMAD_UPSTREAM_IP}", "${NOMAD_UPSTREAM_PORT}", "${DB_USER}", "${DB_PASSWORD}", "${DB_NAME}"]                
        mount {
          type     = "bind"
          target   = "/data"
          source   = "/data"
          readonly = false
        }        
      }

      template {
        data = <<EOT
RESTIC_REPOSITORY="[[.RESTIC_REPOSITORY]]"
RESTIC_PASSWORD="[[.RESTIC_PASSWORD]]"
EOT
        destination = "secrets/env.vars"
        env         = true
      }
    }
  }
}
JOB

  nomad job run "local/backup-${SERVICE_NAME}.hcl"

  # Wait for the backup job to complete
  JOB_NAME="backup-${SERVICE_NAME}"
  echo "Waiting for job $JOB_NAME to complete..."
  while true; do
    STATUS=$(nomad job status -short "$JOB_NAME" | awk '/Status/ {print $3}')
    if [ "$STATUS" == "dead" ]; then
      echo "Job $JOB_NAME completed successfully."
      break
    elif [ "$STATUS" == "failed" ]; then
      echo "Job $JOB_NAME failed. Continuing with next backup."
      break  # Exit wait loop but continue script
    else
      echo "Job $JOB_NAME current status: $STATUS. Checking again in 5 seconds..."
      sleep 5
    fi
  done

  nomad job stop -purge $JOB_NAME

  rm -f  "local/backup-${SERVICE_NAME}.hcl"
done

EOH

        destination = "local/generate-backup-jobs.sh"
        perms       = "755"
      }

      config {
        command = "local/generate-backup-jobs.sh"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}