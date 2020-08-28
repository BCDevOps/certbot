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
1. Point to appropriate namespace (usually tools)
1. Install `openshift/certbot.bc.yaml` to create the required build objects.
   ```
    oc process -f Openshift/certbot.bc.yaml | oc apply -f -
    ```
1. Install `openshift/certbot.dc.yaml` (Template) to create the CronJob and supporting objects (ServiceAccount, RoleBinding, PVC, etc.).
   For non-prod environments you can set `CERTBOT_STAGING=true`, so you don't hit any service limits at Let's Encrypt.
   Review the other parameters in the yaml file and overwrite anything required, e.g. CERTBOT_CRON_SCHEDULE or CERTBOT_SUSPEND_CRON.
    ```
    oc process -f openshift/certbot.dc.yaml -p 'EMAIL=some@email.com' -p 'IMAGE_NAMESPACE=<your-tools-namespace>' -p 'CERTBOT_STAGING=false'| oc apply -f - --record=false --overwrite=true
    ```
    PS: You MUST set/use a valid e-mail    
1. (Optional) If you need to run the CronJob for one time, you can do that by running:
    ```
    # Delete any previous manual Job created
    oc get job -o name | grep -F -e '-manual-' | xargs oc delete
    Note: When there are no jobs to delete, you will get an error for oc delete.

    # Create a Job
    oc create job "certbot-manual-$(date +%s)" --from=cronjob/certbot
    ```
1. To include this cronjob in your pipeline, it is recommended that you copy certbot.bc.yaml and certbot.dc.yaml to your appliciton project. Build Config will point back to this repo to include the latest changes to the contents of the docker folder. Note: If you are using BCDK, there is a bug in it that requires you to have a "docker" folder in your repo.

# Tips
1. If you are going to setup automatic cert renewals for the first time, backup "Certficate", "Private Key" and "CA Certificate" contents from your route.
1. List your cron jobs
    ```
    oc get cronjob
    ```
1. To describe your cron job
    ```
    oc describe cronjob/certbot
    ```
1. To see your cron jobs in Openshift GUI: Resources > Other Resources> Job
1. To access the logs for cron jobs in Openshift GUI: Monitoring > Uncheck "Hide older resources". You will see recently terminated certbot that would have terminated based on your schedule.
1. If you are seeing errors in the logs and need to troubleshoot, you can use optional parameters DEBUG and DELETE_ACME_ROUTES.
    ```
    oc process -f openshift/certbot.dc.yaml -p 'EMAIL=some@email.com' -p 'IMAGE_NAMESPACE=<your-tools-namespace>' -p 'CERTBOT_STAGING=false' -p 'DEBUG=true' -p 'DELETE_ACME_ROUTES=false' | oc apply -f - --record=false --overwrite=true
    ```
    PS: Ensure that you manually delete the ACME Route and Service after you are done troubleshooting and redeploy without the DEBUG and DELETE_ACME_ROUTES options.
1. If you end up running the setup process multiple times, ensure that you have deleted all the duplicate copies of those cron jobs and only keep the latest one. Or to delete all the certbot jobs and start fresh you can use the below. 
    ```
    oc get job -o name | grep -F -e 'certbot' | xargs oc delete
    oc get cronjob -o name | grep -F -e 'certbot' | xargs oc delete
    ```
1. To unsuspend a cronjob in your non-prod environment, you can use the below patch command.
    ```
    oc patch cronjob certbot -p '{"spec" : {"suspend" : false }}'
    ```
# References
- https://certbot.eff.org/docs/using.html#webroot
- https://certbot.eff.org/docs/using.html#renewing-certificates
- https://letsencrypt.org/
- https://letsencrypt.org/how-it-works/
- https://certbot.eff.org/
- https://github.com/certbot/certbot/issues/2697#issuecomment-242360098
- https://www.entrust.net/knowledge-base/technote.cfm?tn=70882
