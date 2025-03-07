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
      port "http" {
        static = 8080
        to     = 8080
      }
    }

    task "[[.SERVICE_ID]]" {
      driver = "docker"

      artifact {
        source = "https://raw.githubusercontent.com/dvorakmilda/mitmproxy_bps/refs/heads/main/proxy.py"
      }

      config {
        image   = "mitmproxy/mitmproxy:latest"
        ports   = ["http"]
        command = "mitmdump"
        args = [
          "-s", "local/proxy.py",
          "--mode", "reverse:[[.BASEHOST]]"
        ]
        volumes = [
          "local/config.json:/etc/mitmproxy/config.json",
        ]
      }

      template {
        data        = <<EOF
[[ .PROXYCONFIG ]]
EOF
        destination = "/local/config.json"
      }


      env {
        PYTHONUNBUFFERED = "1"
      }

      resources {
        cpu    = 200
        memory = 512
      }

      service {
        provider = "nomad"
        port     = "http"
        name     = "mitmdump"
      }
    }
  }
}
