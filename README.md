# Goal

Provide a way for automatically update TLS Certificates on OpenShift Routes

# Assumptions
- Using https://letsencrypt.org/ for issuing certificates
- Using https://certbot.eff.org/ for managing (create/renew) certificates
- Run inside OpenShift

# Solution

- Create a OpenShift `CronJob` which will run on a regular schedule for renewing TLS certificate if required.
    - The `CronJob` will manage a set of required `Service` and `Route`s objects.
    - The `CronJob` manages certificates of all routes with a label `certbot-managed=true`
    - One certificate will be issued/renewed for all the managed hosts/domains.
- If a cert is created/renewed, apply the new certificate to the related routes

# Installation
1. Install `openshift/bc.yaml` to create the required build objects.
   ```
    oc apply -f openshift/bc.yaml
    ```
1. Install `openshift/dc.yaml` (Template) to create the CronJob and supporting objects (ServiceAccount, RoleBinding, PVC, etc.).
    ```
    oc process -f openshift/dc.yaml -p 'EMAIL=some@email.com' -p "IMAGE=$(oc get is/certbot '--output=jsonpath={.status.dockerImageRepository}:latest')" | oc apply -f - --record=false --overwrite=true
    ```
    PS: You MUST set/use a valid e-mail
1. (Optional) If you need to run the CronJob for one time, you can do that by running:
  ```
  #Delete any previous Job created
  oc create job certbot-manual-0 --from=cronjob/certbot
  ```

# References
- https://certbot.eff.org/docs/using.html#webroot
- https://certbot.eff.org/docs/using.html#renewing-certificates
- https://letsencrypt.org/
- https://letsencrypt.org/how-it-works/
- https://certbot.eff.org/
- https://github.com/certbot/certbot/issues/2697#issuecomment-242360098
- https://www.entrust.net/knowledge-base/technote.cfm?tn=70882
