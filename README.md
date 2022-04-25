# Certbot [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Automatically update TLS Certificates on OpenShift Routes

- [Assumptions](#assumptions)
- [Solution](#solution)
- [Installation](#installation)
- [Manual Run](#manual-run)
- [Cleanup](#cleanup)
- [Entrust Usage](#entrust-usage)
- [Tips](#tips)
- [References](#references)
- [License](#license)

## Assumptions

- Using <https://letsencrypt.org/> for issuing certificates
- Using <https://certbot.eff.org/> for managing (create/renew) certificates
- Run inside OpenShift

## Solution

- Create a OpenShift `CronJob` which will run on a regular schedule for renewing TLS certificate if required.
  - The `CronJob` will manage a set of required `Service` and `Route`s objects.
  - The `CronJob` manages certificates of all routes with a label `certbot-managed=true`
  - One certificate will be issued/renewed for all the managed hosts/domains.
- If a cert is created/renewed, apply the new certificate to the related routes

## Installation

1. Point to the appropriate namespace (usually tools)

    ``` sh
    export NAMESPACE=<YOURNAMESPACE>

    oc project $NAMESPACE
    ```

1. Install `certbot.bc.yaml` to create the required build objects.
    _Note: If the build fails, make sure your namespace contains an NSP allowing '@app:k8s:serviceaccountname=builder' (OCP builders) to access 'ext:network=any' (egress internet)_

    This template accepts the following parameters (add with -p to the `oc process` command):

    | Parameter | Default Value | Description |
    | --- | --- | --- |
    | `GIT_REF` | `master` | Git Pull Request or Branch Reference (i.e. 'pull/CHANGE_ID/head') |
    | `GIT_URL` | `https://github.com/BCDevOps/certbot.git` | Git Repository URL |

    ``` sh
    oc process -n $NAMESPACE -f "https://raw.githubusercontent.com/BCDevOps/certbot/master/openshift/certbot.bc.yaml" | oc apply -n $NAMESPACE -f -
    ```

1. Install `certbot.dc.yaml` to create the CronJob and supporting objects (NSP, ServiceAccount, RoleBinding, PVC, etc).
    This template accepts the following parameters (add with -p to the `oc process` command):

    | Parameter | Default Value | Description |
    | --- | --- | --- |
    | `CERTBOT_CRON_SCHEDULE` | `0 */12 * * *` | Cronjob Schedule |
    | `CERTBOT_STAGING` | `false` (must be `false` for [Entrust](#entrust-usage))  | Self-signed cert renewals |
    | `CERTBOT_SUSPEND_CRON` | `false` | Suspend cronjob |
    | `CERTBOT_SERVER` | `https://acme-v02.api.letsencrypt.org/directory` (for BC Gov SSL, see [Entrust](#entrust-usage)) | ACME Certbot endpoint |
    | `DRYRUN` | `false` | Run without executing |
    | `DEBUG` | `false` | Debug mode |
    | `DELETE_ACME_ROUTES` | `true` | Self cleanup temporary ACME routes when done |
    | `SUBSET` | `true` | Allow domain validation to pass if a subset of them are valid |
    | `EMAIL` | For [Entrust](#entrust-usage), Product Owner's `@gov.bc.ca` is suggested | Email where CSR requests are sent to |
    | `NAMESPACE` | | Openshift Namespace |
    | `IMAGE_REGISTRY` | `image-registry.openshift-image-registry.svc:5000` | Openshift Image Registry |
    | `SOURCE_IMAGE_NAME` | `certbot` | Image Name |
    | `TAG_NAME` | `latest` | Image Tag |

    - For non-prod environments, you may set `CERTBOT_STAGING=true`, so you don't hit any service limits at Let's Encrypt.
    - By default, this template will use Let's Encrypt for certificate generation. If you are just testing, you may use Let's Encrypt testing endpoint `https://acme-staging-v02.api.letsencrypt.org/directory` to avoid being rate limited.
    - For your production applications, we strongly recommend **NOT** using Let's Encrypt certificates. Contact your ministry/department to determine best practices for production SSL/TLS certificate management.
    - If you are using a certificate provider that gives you extra domains on top of what you have requested (like Entrust), you should make sure that the `SUBSET` option is set to true. Otherwise certificate renewals will always fail because their extra domain will never be managed on our end and choke. If you require stringent domain validation, set `SUBSET` to false explicitly.

    ``` sh
    export CERTBOT_SERVER=<YOURCERTBOTSERVER>
    export EMAIL=<some-valid@email.com>

    oc process -n $NAMESPACE -f "https://raw.githubusercontent.com/BCDevOps/certbot/master/openshift/certbot.dc.yaml" -p EMAIL=$EMAIL -p NAMESPACE=$NAMESPACE -p CERTBOT_SERVER=$CERTBOT_SERVER | oc apply -n $NAMESPACE -f -
    ```

    _PS: You MUST supply a valid email address!_

To include this cronjob in your pipeline, it is recommended that you copy `certbot.bc.yaml` and `certbot.dc.yaml` to your appliciton project. The build config will point back to this repo to include the latest changes to the contents of the docker folder. _Note: If you are using BCDK, there is a bug in it that requires you to have a "docker" folder in your repo._

## Manual Run

If you need to run the CronJob manually, you can do that by running:

``` sh
# Delete any previous manual Jobs created
# Note: When there are no jobs to delete, you will get an error for oc delete.
oc get job -n $NAMESPACE -o name | grep -F -e '-manual-' | xargs oc delete -n $NAMESPACE

# Create a Job
oc create job -n $NAMESPACE "certbot-manual-$(date +%s)" --from=cronjob/certbot
```

## Cleanup

To remove certbot from your namespace, run the following commands. All build related manifests will have a `build=certbot` label, and all cronjob application related manifests will have an `app=certbot` label.

``` sh
export NAMESPACE=<YOURNAMESPACE>

# Delete all manifests generated by certbot.dc.yaml
oc delete cronjob,pvc,rolebinding,sa -n $NAMESPACE --selector app=certbot

# Delete all manifests generated by certbot.dc.yaml
oc delete all -n $NAMESPACE --selector build=certbot
```

## Entrust Usage

Entrust is the only approved certificate provider for BC Gov production environments currently.  There are a few extra steps required to request certificates from Entrust instead of Let's Encrypt.

1. Start by creating the deployment config found in the [Installation](#installation) section

1. Modify the `CERTBOT_SERVER` parameter in the deployment config to use Entrust

    | Parameter | Default Value | Description |
    | --- | --- | --- |
    | `CERTBOT_SERVER` | `https://www.entrust.net/acme/api/v1/directory/xx-xxxx-xxxx` | Where `xx-xxxx-xxxx` is the directory ID.  This value may vary between different ministry organizations.  Please contact your organization to determine this value. |

1. Make sure `CERTBOT_STAGING` is set to `false`.  The Entrust server does not have a staging mode

1. If the Certbot job was previously ran on the same route using Let's Encrypt server then you will need to delete the existing PVC.  This will remove old Let's Encrypt files and a new PVC will be created on the next step

1. Apply the deployment config and run the job manually or by cron trigger. The job logs will display it has failed to obtain the certificates and the route will remain unmodified.  This is normal because the request still needs to be approved by your ministry first

1. In the `EMAIL` inbox you should receive an email from `auto-notice@entrust.com` containing a `Tracking ID`.

1. At this point you need the appropriate group in your ministry to create an iStore order to approve the certificate request.  For NRM teams, please have your PO create a [Service Desk](https://apps.nrs.gov.bc.ca/int/jira/servicedesk/customer/portal/1) request containing the following information.
   - Domain for the certificate
   - Entrust Tracking ID
   - iStore Coding
   - Expense Authority
   - [Example Service Desk Ticket](https://apps.nrs.gov.bc.ca/int/jira/servicedesk/customer/portal/1/SD-26581)

1. Once the iStore order has been created you should receive another email from `auto-notice@entrust.com` letting you know the request has been approved

1. Re-run the job and Certbot should obtain the certificates and install them successfully

## Tips

1. If you are going to setup automatic cert renewals for the first time, backup "Certficate", "Private Key" and "CA Certificate" contents from your route.
1. List your cron jobs

    ``` sh
    export NAMESPACE=<YOURNAMESPACE>

    oc get -n $NAMESPACE cronjob
    ```

1. To describe your cron job

    ``` sh
    export NAMESPACE=<YOURNAMESPACE>

    oc describe -n $NAMESPACE cronjob/certbot
    ```

1. To see your cron jobs in Openshift GUI: Resources > Other Resources > Job
1. To access the logs for cron jobs in Openshift GUI: Monitoring > Uncheck "Hide older resources". You will see recently terminated certbot that would have terminated based on your schedule.
1. If you are seeing errors in the logs and need to troubleshoot, you can use optional parameters DEBUG and DELETE_ACME_ROUTES.

    ``` sh
    export CERTBOT_SERVER=<YOURCERTBOTSERVER>
    export EMAIL=<some-valid@email.com>
    export NAMESPACE=<YOURNAMESPACE>

    oc process -n $NAMESPACE -f "https://raw.githubusercontent.com/BCDevOps/certbot/master/openshift/certbot.dc.yaml" -p EMAIL=$EMAIL -p NAMESPACE=$NAMESPACE -p CERTBOT_SERVER=$CERTBOT_SERVER -p CERTBOT_STAGING=false -p DEBUG=true -p DELETE_ACME_ROUTES=false | oc apply -n $NAMESPACE -f -
    ```

    _PS: Ensure that you manually delete the ACME Route and Service after you are done troubleshooting and redeploy without the DEBUG and DELETE_ACME_ROUTES options!_

1. If you end up running the setup process multiple times, ensure that you have deleted all the duplicate copies of those cron jobs and only keep the latest one. Or to delete all the certbot jobs and start fresh you can use the below.

    ``` sh
    export NAMESPACE=<YOURNAMESPACE>

    oc get job -n $NAMESPACE -o name | grep -F -e 'certbot' | xargs oc delete
    oc get cronjob -n $NAMESPACE -o name | grep -F -e 'certbot' | xargs oc delete
    ```

1. To suspend a cronjob in your namespace, you can use the below patch command.

    ``` sh
    export NAMESPACE=<YOURNAMESPACE>

    oc patch cronjob -n $NAMESPACE certbot -p '{"spec" : {"suspend" : false }}'
    ```

1. To resume a cronjob in your namespace, you can use the below patch command.

    ``` sh
    export NAMESPACE=<YOURNAMESPACE>

    oc patch cronjob -n $NAMESPACE certbot -p '{"spec" : {"suspend" : true }}'
    ```

## References

- <https://certbot.eff.org/docs/using.html#webroot>
- <https://certbot.eff.org/docs/using.html#renewing-certificates>
- <https://letsencrypt.org/>
- <https://letsencrypt.org/how-it-works/>
- <https://certbot.eff.org/>
- <https://github.com/certbot/certbot/issues/2697#issuecomment-242360098>
- <https://www.entrust.net/knowledge-base/technote.cfm?tn=70882>

## License

``` text
Copyright 2018 Province of British Columbia

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
