job "[[.DOMAIN]]" {

  datacenters = [[ .DATACENTERS  | toJson ]]
  type        = "service"

  group "[[.SERVICE_ID]]" {
    count = 1

    restart {
      attempts = 0
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    network {
      port "firebird" {
        static = 3050
        to     = 3050
      }
    }

    task "firebird" {
      driver = "docker"

      config {
        image = "[[.FIREBIRD_IMAGE]]"
        ports = ["firebird"]

        mount {
          type     = "bind"
          target   = "/var/lib/firebird/data"
          source   = "/data/[[.SERVICE_ID]]"
          readonly = false
        }
      }

      env {
        FIREBIRD_ROOT_PASSWORD            = "[[.FIREBIRD_ROOT_PASSWORD]]"
        FIREBIRD_USER                     = "[[.FIREBIRD_USER]]"
        FIREBIRD_PASSWORD                 = "[[.FIREBIRD_PASSWORD]]"
        FIREBIRD_DATABASE                 = "[[.FIREBIRD_DATABASE]]"
        FIREBIRD_DATABASE_DEFAULT_CHARSET = "[[.FIREBIRD_DATABASE_DEFAULT_CHARSET]]"
      }

      resources {
        cpu    = 200
        memory = 512
      }

      service {
        name     = "firebird-db"
        provider = "nomad"
        port     = "firebird"

        tags = [
          "backup-enabled",
          "backup-type=file",
          "backup-schedule=@hourly",
          "backup-retention=7",
          "db-user=[[.FIREBIRD_USER]]",
          "db-password=[[.FIREBIRD_PASSWORD]]",
          "db-name=/data/[[.SERVICE_ID]]/[[.FIREBIRD_DATABASE]]"
        ]
      }
    }
  }
}
