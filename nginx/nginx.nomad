job "[[.DOMAIN]]" {
  type        = "service"
  datacenters = [[ .DATACENTERS  | toJson ]]


  group "[[.SERVICE_ID]]" {
    count = 1

    network {
      port "http" { static = 80 }
    }

    service {
      name     = "[[.SERVICE_ID]]"
      provider = "nomad"
      port     = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.[[.SERVICE_ID]].rule=Host(`[[.DOMAIN]]`)"
      ]

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "[[.SERVICE_ID]]" {
      driver = "docker"

      config {
        image = "nginx:1-alpine"
        ports = ["http"]
        mount {
          type     = "bind"
          target   = "/usr/share/nginx/html"
          source   = "/data/[[.SERVICE_ID]]"
          readonly = false
        }
      }

      resources {
        cpu    = 190
        memory = 256
      }

    }
  }
}
