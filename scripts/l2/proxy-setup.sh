#!/bin/bash
set -euo pipefail

set -a
source $(pwd)/.env
set +a

# reference: https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-batch-dns-records
create_dns_records() {
    local names=("$@")
    local records=""
    
    for name in "${names[@]}"; do
        if [ -n "$records" ]; then
            records="${records},"
        fi
        records="${records}
        {
            \"type\": \"A\",
            \"name\": \"${name}.${CLOUDFLARE_DNS_SUBDOMAIN}\",
            \"content\": \"$L2_SYSTEM_SERVER_IP\",
            \"proxied\": false
        }"
    done

    curl --request POST \
        --url "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/batch" \
        --header "Content-Type: application/json" \
        --header "X-Auth-Email: $CLOUDFLARE_AUTH_EMAIL" \
        --header "X-Auth-Key: $CLOUDFLARE_API_KEY" \
        --data "{
            \"posts\": [${records}]
        }"
}

# 1. create the DNS records for the subdomains
# (RPC, Bridge, Explorer)
create_dns_records "rpc" "bridge" "explorer"

# 2. obtain the SSL certificate for each subdomain
# the certs will be stored in /etc/letsencrypt/live/${CERTBOT_DOMAIN_SUFFIX}
# 
# note that Certbot creates a single certificate that's valid for all those 
# domains (called a SAN - Subject Alternative Names certificate)
# 
# after running the command, you can verify by:
#   sudo openssl x509 -in /etc/letsencrypt/live/${CERTBOT_DOMAIN_SUFFIX}/fullchain.pem -text | grep DNS:
# 
# reference: https://eff-certbot.readthedocs.io/en/latest/using.html
certbot certonly --nginx --non-interactive --agree-tos -m ${CERTBOT_EMAIL} \
  --cert-name ${CERTBOT_DOMAIN_SUFFIX} \
  -d rpc.${CERTBOT_DOMAIN_SUFFIX} \
  -d bridge.${CERTBOT_DOMAIN_SUFFIX} \
  -d explorer.${CERTBOT_DOMAIN_SUFFIX}

# 3. create the nginx config files for each subdomain
cp configs/nginx/l2-rpc.conf.template /etc/nginx/sites-available/l2-rpc.conf
cp configs/nginx/bridge.conf.template /etc/nginx/sites-available/bridge.conf
cp configs/nginx/l2-explorer.conf.template /etc/nginx/sites-available/l2-explorer.conf

# 4. replace ${CERTBOT_DOMAIN_SUFFIX} in the nginx config files
sed -i 's/\${CERTBOT_DOMAIN_SUFFIX}/'"${CERTBOT_DOMAIN_SUFFIX}"'/g' /etc/nginx/sites-available/*.conf

# 5. enable the nginx config files
mkdir -p /etc/nginx/sites-enabled
ln -sf /etc/nginx/sites-available/l2-rpc.conf /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/bridge.conf /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/l2-explorer.conf /etc/nginx/sites-enabled/

# 6. verify the nginx config files
nginx -t

# 7. restart nginx
#
# after running this, you can check the status of nginx by:
# systemctl status nginx
# 
# see logs
# journalctl -u nginx.service -f
systemctl start nginx
systemctl enable nginx