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
      port "rest" {
        static = 8000
        to     = 8000
      }
    }

    task "[[.SERVICE_ID]]" {
      driver = "docker"

      env {
        OPTIONS = "--prometheus --prometheus-no-auth"
      }

      config {
        image = "[[.REST_IMAGE]]"
        ports = ["rest"]

        mount {
          type     = "bind"
          target   = "/data"
          source   = "/data/[[.SERVICE_ID]]"
          readonly = false
        }
      }

      resources {
        cpu    = [[.CPU | default "100"]]
        memory = [[.MEMORY | default "256"]]
      }

      service {
        provider = "nomad"
        port     = "rest"
        name     = "restic"
      }
    }
  }
}
