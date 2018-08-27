FROM registry.access.redhat.com/rhel7:7.5

RUN yum repolist all && \
    yum intall --disablerepo="*" --enablerepo=rhel-7-server-rpms --enablerepo=rhel-server-rhscl-7-rpms -y yum-utils certbot
    
