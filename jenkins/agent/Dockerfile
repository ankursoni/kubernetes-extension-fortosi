FROM jenkins/inbound-agent:latest

# switch to root user from jenkins user
USER root

# update debian package list and upgrade installed packages via apt
RUN apt-get update && \
    apt-get full-upgrade -y

# install basic utilities
RUN apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl wget unzip tar sudo \
        lsb-release \
        gnupg-agent gnupg2 \
        software-properties-common

# install docker ce cli tool
RUN curl -fsSL "https://download.docker.com/linux/$(lsb_release -is | tr -td '\n' | tr [:upper:] [:lower:])/gpg" | apt-key add - && \
    echo "deb [arch=amd64] https://download.docker.com/linux/$(lsb_release -is | tr -td '\n' | tr [:upper:] [:lower:]) \
    $(lsb_release -cs | tr -td '\n' | tr [:upper:] [:lower:]) stable" | tee -a /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli

# install kubectl
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && \
    apt-get install -y kubectl

# install helm
RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash -

# switch back to jenkins user
# USER jenkins