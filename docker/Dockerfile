FROM registry.access.redhat.com/rhel7:7.5

RUN set -x && \
    curl -sfL https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -o /tmp/epel-release-latest-7.noarch.rpm && \
    yum install -y /tmp/epel-release-latest-7.noarch.rpm && rm -rf /tmp/epel-release-latest-7.noarch.rpm && \
    yum repolist all && \
    yum install --disablerepo="*" '--enablerepo=rhel-7-server-rpms' '--enablerepo=rhel-server-rhscl-7-rpms' '--enablerepo=rhel-7-server-extras-rpms' '--enablerepo=epel' '--enablerepo=rhel-7-server-optional-rpms' -y yum-utils certbot && \
    mkdir -p /var/log/letsencrypt && \
    chmod -R ugo+rwX /var/log/letsencrypt && \
    mkdir -p /var/lib/letsencrypt && \
    chmod -R ugo+rwX /var/lib/letsencrypt && \
    mkdir -p /etc/letsencrypt && \
    chmod -R ugo+rwX /etc/letsencrypt
