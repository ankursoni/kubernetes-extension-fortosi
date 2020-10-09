FROM jenkins/jenkins:lts

# switch to root user from jenkins user
USER root

# update debian package list and upgrade installed packages via apt
RUN apt-get update && \
    apt-get full-upgrade -y

# jenkins automatic initialisation and setup
COPY jenkins.install.InstallUtil.lastExecVersion ${JENKINS_HOME}/jenkins.install.InstallUtil.lastExecVersion
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY jenkins.yaml /usr/share/jenkins/ref/jenkins.yaml
COPY jenkins-agent.yaml /jenkins-agent.yaml
COPY jenkins-vars-secret /jenkins-vars-secret
COPY kubeconfig-secret /kubeconfig-secret
RUN . /jenkins-vars-secret && \
    sed -i "s|<GITHUB_USER_NAME>|${GITHUB_USER_NAME}|g" /usr/share/jenkins/ref/jenkins.yaml && \
    sed -i "s|<GITHUB_USER_PAT>|${GITHUB_USER_PAT}|g" /usr/share/jenkins/ref/jenkins.yaml && \
    sed -i "s|<CONTAINER_REGISTRY_URL>|${CONTAINER_REGISTRY_URL}|g" /usr/share/jenkins/ref/jenkins.yaml && \
    sed -i "s|<CONTAINER_REPOSITORY_NAME>|${CONTAINER_REPOSITORY_NAME}|g" /usr/share/jenkins/ref/jenkins.yaml && \
    sed -i "s|<JENKINS_IMAGE_NAME>|${JENKINS_IMAGE_NAME}|g" /usr/share/jenkins/ref/jenkins.yaml && \
    sed -i "s|<CONTAINER_REGISTRY_USER_NAME>|${CONTAINER_REGISTRY_USER_NAME}|g" /usr/share/jenkins/ref/jenkins.yaml && \
    sed -i "s|<CONTAINER_REGISTRY_USER_PASSWORD>|${CONTAINER_REGISTRY_USER_PASSWORD}|g" /usr/share/jenkins/ref/jenkins.yaml && \
    sed -i "s|<CICD_NAMESPACE>|${CICD_NAMESPACE}|g" /usr/share/jenkins/ref/jenkins.yaml && \
    sed -i "s|<GITHUB_ORG>|${GITHUB_ORG}|g" /usr/share/jenkins/ref/jenkins.yaml && \
    sed -i "s|<INIT_REPO>|${INIT_REPO}|g" /usr/share/jenkins/ref/jenkins.yaml && \
    sed -i "s|<ENABLE_LOCAL_DOCKER>|${ENABLE_LOCAL_DOCKER}|g" /usr/share/jenkins/ref/jenkins.yaml && \
    sed -i -e '/<JENKINS_AGENT_TEMPLATE_YAML>/r /jenkins-agent.yaml' -e '/<JENKINS_AGENT_TEMPLATE_YAML>/d' /usr/share/jenkins/ref/jenkins.yaml && \
    kubeconfig=$(cat /kubeconfig-secret | base64 | tr -d '\n') && sed -i "s|<KUBECONFIG-SECRET>|${kubeconfig}|g" /usr/share/jenkins/ref/jenkins.yaml && \
    cat /usr/share/jenkins/ref/jenkins.yaml && \
    rm /jenkins-agent.yaml /jenkins-vars-secret /kubeconfig-secret -f

# jenkins automatic plugin installation
ENV CURL_OPTIONS -sSfL0
ENV CURL_CONNECTION_TIMEOUT 60
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# switch back to jenkins user
USER jenkins