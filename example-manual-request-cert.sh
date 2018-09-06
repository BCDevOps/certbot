#!/usr/bin/env sh

SCRIPT_PATH=$(cd "$(dirname "$0")"; pwd)

echo "$SCRIPT_PATH"
mkdir -p $SCRIPT_PATH/certbot/config
mkdir -p $SCRIPT_PATH/certbot/logs
mkdir -p $SCRIPT_PATH/certbot/work

certbot certonly --manual --config-dir certbot/config  --work-dir certbot/work --logs-dir certbot/logs --preferred-challenges http --agree-tos -m clecio.varjao@gov.bc.ca -d nmp.apps.nrs.gov.bc.ca -vvvv


# oc secret new nmp-route-cert-prod caCertificate=certbot/config/live/nmp.apps.nrs.gov.bc.ca/chain.pem certificate=certbot/config/live/nmp.apps.nrs.gov.bc.ca/cert.pem key=certbot/config/live/nmp.apps.nrs.gov.bc.ca/privkey.pem
