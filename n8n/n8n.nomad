job "[[.DOMAIN]]" {

  datacenters = [[ .DATACENTERS  | toJson ]]
  type        = "service"

  group "[[.SERVICE_ID]]" {
    count = 1

    restart {
      attempts = 5
      delay    = "30s"
    }

    network {
      port "db" { to = 5432 }
      port "http" { to = 5678 }
    }

    task "[[.SERVICE_ID]]-db" {
      driver = "docker"

      config {
        image = "postgres:16"
        ports = ["db"]
        mount {
          type     = "bind"
          target   = "/var/lib/postgresql/data"
          source   = "/data/[[.SERVICE_ID]]/db"
          readonly = false
        }
      }

      env {
        POSTGRES_DB                = "[[.POSTGRES_DB]]"
        POSTGRES_USER              = "[[.POSTGRES_USER]]"
        POSTGRES_PASSWORD          = "[[.POSTGRES_PASSWORD]]"
        POSTGRES_NON_ROOT_USER     = "[[.POSTGRES_NON_ROOT_USER]]"
        POSTGRES_NON_ROOT_PASSWORD = "[[.POSTGRES_NON_ROOT_PASSWORD]]"
      }

      service {
        provider = "nomad"
        port     = "db"
        name     = "db"
      }
    }

    task "[[.SERVICE_ID]]" {
      driver = "docker"
      config {
        image = "docker.n8n.io/n8nio/n8n"
        ports = ["http"]
        mount {
          type     = "bind"
          target   = "/home/node/.n8n"
          source   = "/data/[[.SERVICE_ID]]/n8n"
          readonly = false
        }
      }
      env {
        DB_TYPE                = "postgresdb"
        DB_POSTGRESDB_HOST     = "${NOMAD_HOST_IP_db}"
        DB_POSTGRESDB_PORT     = "${NOMAD_HOST_PORT_db}"
        DB_POSTGRESDB_DATABAE  = "[[.POSTGRES_DB]]"
        DB_POSTGRESDB_USER     = "[[.POSTGRES_NON_ROOT_USER]]"
        DB_POSTGRESDB_PASSWORD = "[[.POSTGRES_NON_ROOT_PASSWORD]]"
        N8N_PROTOCOL           = "http"
        N8N_RUNNERS_ENABLED    = "true"
        N8N_SECURE_COOKIE      = "false"
        GENERIC_TIMEZONE       = "Europe/Berlin"
        WEBHOOK_URL            = "http://:5678/"
      }
      resources {
        cpu    = 200
        memory = 512
      }
      service {
        provider = "nomad"
        port     = "http"
        name     = "traefik"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.[[.SERVICE_ID]].rule=Host(`[[.DOMAIN]]`)",
          "traefik.http.services.[[.SERVICE_ID]].loadbalancer.server.port=5678"
        ]
      }
    }
  }
}

