#!/bin/bash
set -e

# Validate critical environment variables
: "${DOMAIN_FQDN:?DOMAIN_FQDN must be set}"
: "${DC_IP:?DC_IP must be set}"
: "${DC_NAME:?DC_NAME must be set}"
: "${MAIN_DNS_IP:?MAIN_DNS_IP must be set}"

# Calculate derived values
DOMAIN_FQDN_UCASE=$(echo "$DOMAIN_FQDN" | tr '[:lower:]' '[:upper:]')
DOMAIN_NETBIOS=${DOMAIN_NETBIOS:-$(echo "$DOMAIN_FQDN" | cut -d. -f1 | tr '[:lower:]' '[:upper:]')}

# Check for existing domain provision
if [ ! -f /var/lib/samba/private/sam.ldb ]; then
    echo "Provisioning domain: $DOMAIN_FQDN_UCASE ($DOMAIN_NETBIOS)"
    
    samba-tool domain provision \
        --use-rfc2307 \
        --server-role=dc \
        --dns-backend=SAMBA_INTERNAL \
        --realm="$DOMAIN_FQDN_UCASE" \
        --domain="$DOMAIN_NETBIOS" \
        --host-ip="$DC_IP" \
        --configfile=/etc/samba/smb.conf

    samba-tool domain passwordsettings set --history-length=0
    samba-tool domain passwordsettings set --min-pwd-age=0
    samba-tool domain passwordsettings set --max-pwd-age=0



    echo "Provisioning completed successfully"
else
    echo "Existing domain found - skipping provisioning"
fi

# Start Samba through tini for proper signal handling
samba -i --configfile=/etc/samba/smb.conf
