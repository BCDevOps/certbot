FROM registry.access.redhat.com/rhel7:7.5

RUN curl -sfL https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -o /tmp/epel-release-latest-7.noarch.rpm && \
    yum install -y /tmp/epel-release-latest-7.noarch.rpm && rm -rf /tmp/epel-release-latest-7.noarch.rpm && \
    yum repolist all && \
    yum install --disablerepo="*" '--enablerepo=rhel-7-server-rpms' '--enablerepo=rhel-server-rhscl-7-rpms' '--enablerepo=rhel-7-server-extras-rpms' '--enablerepo=epel' -y yum-utils certbot
    
