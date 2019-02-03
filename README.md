# Goal

Provide a way for automatically update TLS Certs for Routes

# Assumptions
- Using https://letsencrypt.org/ for issuing certificates
- Using https://certbot.eff.org/ for managing (create/renew) certificates
- Run inside OpenShift

# Prerequisites
- small PVC for sharing the '/.well-known/acme-challenge' with the CronJob
- route/service/pod for allowing domain validation using well-knonw URI

# Solution
Create a OpenShift CronJob which will run 2 times a day and renew TLS cert when required.
When a cert is created/renewed, apply the new certificate to the related routes


# References
- https://certbot.eff.org/docs/using.html#webroot
- https://certbot.eff.org/docs/using.html#renewing-certificates
- https://letsencrypt.org/
- https://letsencrypt.org/how-it-works/
- https://certbot.eff.org/
- https://github.com/certbot/certbot/issues/2697#issuecomment-242360098
- https://www.entrust.net/knowledge-base/technote.cfm?tn=70882
