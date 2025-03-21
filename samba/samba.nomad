job "[[.DOMAIN]]" {
  type        = "service"
  datacenters = [[ .DATACENTERS  | toJson ]]


  group "[[.SERVICE_ID]]" {
    count = 1

    network {
      mode = "bridge"
      # port "dns" { static = 53 }
      port "kerberos" { static = 88 }
      port "ldap" { static = 389 }
      port "ldaps" { static = 636 }
      port "smb" { static = 445 }
    }

    service {
      name     = "[[.SERVICE_ID]]"
      provider = "nomad"
      port     = "smb"


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

      env {
        DC_NAME     = "dc1"
        DOMAIN_FQDN = "ad.internal"
        DC_IP       = "192.168.0.5"
        MAIN_DNS_IP = "192.168.0.4"
      }

      config {
        image = "samba:local"
        ports = ["dns", "kerberos", "ldap", "ldaps", "smb"]

        mount {
          type     = "bind"
          target   = "/var/lib/samba"
          source   = "/data/[[.SERVICE_ID]]"
          readonly = false
        }
        mount {
          type     = "bind"
          target   = "/etc/samba/smb.conf"
          source   = "local/smb.conf"
          readonly = false
        }
        mount {
          type     = "bind"
          target   = "/etc/krb5.conf"
          source   = "local/krb5.conf"
          readonly = false
        }
      }



      template {
        data        = <<EOH
# Global parameters
[global]
    disable netbios = yes
    dns forwarder = {{ env "MAIN_DNS_IP" }}
    netbios name = {{ env "DC_NAME" }}
    realm = {{ env "DOMAIN_FQDN" | toUpper }}
    server role = active directory domain controller    
    workgroup = {{ slice (split "." (env "DOMAIN_FQDN")) 0 1 | join "" | toUpper }}
    idmap_ldb:use rfc2307 = yes

[sysvol]
    path = /var/lib/samba/sysvol
    read only = No

[netlogon]
    path = /var/lib/samba/sysvol/{{ env "DOMAIN_FQDN" }}/scripts
    read only = No
EOH
        destination = "local/smb.conf"
      }

      template {
        data        = <<EOH
[libdefaults]
    default_realm =  {{ env "DOMAIN_FQDN" | toUpper }}
    dns_lookup_realm = false
    dns_lookup_kdc = true                
EOH
        destination = "local/krb5.conf"
      }


      resources {
        cpu    = 190
        memory = 256
      }

    }

  }
}
