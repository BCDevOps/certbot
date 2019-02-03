#!/usr/bin/env bash

: "${CERTBOT_CONFIG_DIR:=/etc/letsencrypt}"
: "${CERTBOT_LOGS_DIR:=/var/log/letsencrypt}"
: "${CERTBOT_WORK_DIR:=/var/lib/letsencrypt}"
: "${CERTBOT_RSA_KEY_SIZE:=2048}"

[ ! -z "$CERTBOT_EMAIL" ] || (echo "Missing 'CERTBOT_EMAIL' environment variable" && exit 1)

mkdir -p "$CERTBOT_CONFIG_DIR" "$CERTBOT_WORK_DIR" "$CERTBOT_LOGS_DIR"

cat > /tmp/certbot.ini <<EOF
rsa-key-size = $CERTBOT_RSA_KEY_SIZE
authenticator = standalone
http-01-port = 8080
tls-sni-01-port = 4443
preferred-challenges = http
agree-tos = true
email = $CERTBOT_EMAIL

config-dir = $CERTBOT_CONFIG_DIR
work-dir = $CERTBOT_WORK_DIR
logs-dir = $CERTBOT_LOGS_DIR
EOF

cat > $CERTBOT_CONFIG_DIR/renewal-hooks/deploy/set-deployed-flag.sh << EOF
#!/bin/sh
touch $CERTBOT_WORK_DIR/deployed
EOF
chmod +x $CERTBOT_CONFIG_DIR/renewal-hooks/deploy/set-deployed-flag.sh

cat > /tmp/certbot-svc.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: certbot
    well-known: acme-challenge
  name: certbot
spec:
  ports:
    - name: http
      port: 8080
      protocol: TCP
      targetPort: 8080
  selector:
    certbot: "true"
  sessionAffinity: None
  type: ClusterIP
EOF

cat > /tmp/certbot-route.yaml <<'EOF'
apiVersion: v1
kind: Template
metadata:
  creationTimestamp: null
  name: certbot-well-known
parameters:
- name: NAME
- name: HOST
objects:
- apiVersion: route.openshift.io/v1
  kind: Route
  metadata:
    annotations:
      haproxy.router.openshift.io/timeout: 5m
    labels:
      app: certbot
      well-known: acme-challenge
    name: ${NAME}
  spec:
    host: ${HOST}
    path: /.well-known/acme-challenge/
    port:
      targetPort: http
    tls:
      insecureEdgeTerminationPolicy: Allow
      termination: edge
    to:
      kind: Service
      name: certbot
      weight: 100
    wildcardPolicy: None
EOF

#Prepare list of domains
oc get route -l certbot-managed=true -o json | jq '.items[].spec.host' -r | sort -f | uniq -iu > /tmp/certbot-hosts.txt
cat /tmp/certbot-hosts.txt | paste -sd "," - > /tmp/certbot-hosts.csv

#List of Routes
oc get route -l certbot-managed=true -o json | jq '.items[].metadata.name' -r > /tmp/certbot-routes.txt

# Delete well-known/acme-challenge routes
oc delete route,svc -l app=certbot,well-known=acme-challenge

# Create certbot service
oc create -f /tmp/certbot-svc.yaml

#Create well-known/acme-challenge routes
cat /tmp/certbot-hosts.txt | xargs -n 1 -I {} oc process -f /tmp/certbot-route.yaml -p 'NAME=acme-challenge-{}' -p 'HOST={}' | oc create -f -

rm -f $CERTBOT_WORK_DIR/deployed
certbot -c /tmp/certbot.ini certonly --no-eff-email --keep --cert-name 'openshift-route-certs' --expand --standalone -d "$(</tmp/certbot-hosts.csv)"
certbot -c /tmp/certbot.ini renew --no-eff-email --cert-name 'openshift-route-certs'

if [ -f $CERTBOT_WORK_DIR/deployed ]; then
  echo 'New certificate(s) have been issued'
else
  echo 'NO certificate(s) have been issued'
fi

#if [ -f $CERTBOT_WORK_DIR/deployed ]; then
echo 'Updating Routes'
CERTIFICATE="$(awk '{printf "%s\\n", $0}' $CERTBOT_CONFIG_DIR/live/openshift-route-certs/cert.pem)"
KEY="$(awk '{printf "%s\\n", $0}' $CERTBOT_CONFIG_DIR/live/openshift-route-certs/privkey.pem)"
CABUNDLE=$(awk '{printf "%s\\n", $0}' $CERTBOT_CONFIG_DIR/live/openshift-route-certs/fullchain.pem)

cat /tmp/certbot-routes.txt | xargs -n 1 -I {} oc patch "route/{}" -p '{"spec":{"tls":{"certificate":"'"${CERTIFICATE}"'","key":"'"${KEY}"'","caCertificate":"'"${CABUNDLE}"'"}}}'
#fi

# Delete well-known/acme-challenge routes
oc delete route,svc -l app=certbot,well-known=acme-challenge
