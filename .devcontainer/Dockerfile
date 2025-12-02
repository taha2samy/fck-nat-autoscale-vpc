FROM registry.access.redhat.com/ubi9/ubi:latest

ENV AUTO_CONFIRM="-y"

RUN dnf update $AUTO_CONFIRM && \
    dnf install $AUTO_CONFIRM \
    openssh-clients \
    git \
    curl \
    unzip \
    yum-utils 

RUN yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo && \
    dnf install $AUTO_CONFIRM terraform

RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

RUN dnf clean all

WORKDIR /workspace

CMD [ "bash" ]