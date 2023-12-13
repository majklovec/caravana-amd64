job "[[.DOMAIN]]" {
  datacenters = [[ .DATACENTERS  | toJson ]]
  type        = "service"

  // must have linux for network mode
  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "[[.SERVICE_ID]]" {
    count = 1

    service {
      name     = "grafana"
      provider = "nomad"
      port     = "http"
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:[[ .VERSION ]]"
        ports = ["http"]
      }

      env {
        [[- range $key, $value := .ENV_VARS ]]
        [[ $key ]] = [[ $value | quote]]
        [[- end ]]
      }

      [[- if .ARTIFACTS ]]
      [[- range $artifact := .ARTIFACTS ]]
      artifact {
        source      = [[ $artifact.source | quote ]]
        destination = [[ $artifact.destination | quote ]]
        mode        = [[ $artifact.mode | quote ]]
        [[- if $artifact.options ]]
        options {
          [[- range $option, $val := $artifact.options ]]
          [[ $option ]] = [[ $val | quote ]]
          [[- end ]]
        }
        [[- end ]]

      }
      [[- end ]]
      [[- end ]]

      template {
        data        = <<EOF
[[ .GRAFANAINI ]]
EOF
        destination = "/local/grafana/grafana.ini"
      }

      [[- if .DASHBOARDS ]]
      template {
        data        = <<EOF
[[ .DASHBOARDS ]]
EOF
        destination = "/local/grafana/provisioning/dashboards/dashboards.yaml"
      }
      [[- end ]]

      [[- if .DATASOURCES ]]
      template {
        data        = <<EOF
[[ .DATASOURCES ]]
EOF
        destination = "/local/grafana/provisioning/datasources/datasources.yaml"
      }
      [[- end ]]

      [[- if .PLUGINS ]]

      template {
        data        = <<EOF
[[ .PLUGINS ]]
EOF
        destination = "/local/grafana/provisioning/plugins/plugins.yml"
      }
      [[- end ]]
    }
  }
}
