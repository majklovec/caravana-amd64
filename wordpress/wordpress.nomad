job "[[.DOMAIN]]" {
  type        = "service"
  datacenters = [[ .DATACENTERS  | toJson ]]


  group "[[.SERVICE_ID]]" {
    count = 1

    network {
      port "http" { to = 80 }
      port "mysql" { to = 3306 }
    }

    service {
      name     = "[[.SERVICE_ID]]-wordpress"
      provider = "nomad"
      port = "http"
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

    service {
      name = "[[.SERVICE_ID]]-db"
      port = "mysql"
      provider = "nomad"

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

    task "[[.SERVICE_ID]]-wordpress" {
      driver = "docker"

      env = {
        WORDPRESS_DB_HOST     = "${NOMAD_ADDR_mysql}"
        WORDPRESS_DB_USER     = "[[.DB_USER]]"
        WORDPRESS_DB_PASSWORD = "[[.DB_PASSWORD]]"
        WORDPRESS_DB_NAME     = "[[.DB_DATABASE]]"
        WORDPRESS_DEBUG       = 1
      }

      config {
        image = "wordpress"
        ports = ["http"]
        mount {
          type     = "bind"
          target   = "/var/www/html"
          source   = "/data/[[.SERVICE_ID]]/wordpress"
          readonly = false
        }
      }

      resources {
        cpu    = 190
        memory = 256
      }

    }

    task "[[.SERVICE_ID]]-mysql" {
      driver = "docker"

      env = {
        "MYSQL_ROOT_PASSWORD" = "[[.DB_PASSWORD]]"
        "MYSQL_USER"          = "[[.DB_USER]]"
        "MYSQL_PASSWORD"      = "[[.DB_PASSWORD]]"
        "MYSQL_DATABASE"      = "[[.DB_DATABASE]]"
      }

      config {
        image = "mysql/mysql-server:8.0"
        ports = ["mysql"]
        mount {
          type     = "bind"
          target   = "/var/lib/mysql"
          source   = "/data/[[.SERVICE_ID]]/db"
          readonly = false
        }
      }

      resources {
        cpu    = 500
        memory = 1024
      }
    }
  }
}
