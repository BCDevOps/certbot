# Certbot [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE) [![Lifecycle:Dormant](https://img.shields.io/badge/Lifecycle-Dormant-ff7f2a)](https://github.com/bcgov/repomountie/blob/master/doc/lifecycle-badges.md)

[![version](https://img.shields.io/docker/v/bcgovimages/certbot.svg?sort=semver)](https://hub.docker.com/r/bcgovimages/certbot)
[![pulls](https://img.shields.io/docker/pulls/bcgovimages/certbot.svg)](https://hub.docker.com/r/bcgovimages/certbot)
[![size](https://img.shields.io/docker/image-size/bcgovimages/certbot.svg)](https://hub.docker.com/r/bcgovimages/certbot)

Automatically update TLS Certificates on OpenShift Routes

**Update: As of August 2023, Entrust (the only approved certificate provider for BC Gov production environments) has discontinued support for Certbot. Currently, Certbot cannot be used to manage your Entrust certificates.**

To learn more about the **Common Services** available visit the [Common Services Showcase](https://bcgov.github.io/common-service-showcase/) page.

## Directory Structure

```txt
.github/                   - PR and Issue templates
docker/                    - Certbot application Root
openshift/                 - OpenShift-deployment files
CODE-OF-CONDUCT.md         - Code of Conduct
COMPLIANCE.yaml            - BCGov PIA/STRA compliance status
CONTRIBUTING.md            - Contributing Guidelines
LICENSE                    - License
SECURITY.md                - Security Policy and Reporting
```

## Documentation

* [Docker Readme](docker/README.md)
* [Security Reporting](SECURITY.md)

## Getting Help or Reporting an Issue

To report bugs/issues/features requests, please file an [issue](https://github.com/BCDevOps/certbot/issues).

## How to Contribute

If you would like to contribute, please see our [contributing](CONTRIBUTING.md) guidelines.

Please note that this project is released with a [Contributor Code of Conduct](CODE-OF-CONDUCT.md). By participating in this project you agree to abide by its terms.

## License

```txt
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
