# Build jenkins agent docker image
``` SH
cd jenkins/agent

docker build -t <CONTAINER_REGISTRY_URL>/<CONTAINER_REPOSITORY_NAME>/<JENKINS_IMAGE_NAME>:jenkins-agent .
# for e.g., for 'docker.io' as <CONTAINER_REGISTRY_URL>, 'ankursoni' as <CONTAINER_REPOSITORY_NAME> and 'fortosi' as <JENKINS_IMAGE_NAME>:
# docker build -t docker.io/ankursoni/fortosi:jenkins-agent .
```

# Publish jenkins agent docker image (not required if you are running locally)
``` SH
docker login -u <USERNAME> <CONTAINER_REGISTRY_URL>
# for e.g., for 'ankursoni' as <USERNAME> and 'docker.io' as <CONTAINER_REGISTRY_URL>:
docker login -u ankursoni docker.io

docker push <CONTAINER_REGISTRY_URL>/<CONTAINER_REPOSITORY_NAME>/<JENKINS_IMAGE_NAME>:jenkins-agent
# for e.g., for 'docker.io' as <CONTAINER_REGISTRY_URL>, 'ankursoni' as <CONTAINER_REPOSITORY_NAME> and 'fortosi' as <JENKINS_IMAGE_NAME>:
# docker push docker.io/ankursoni/fortosi:jenkins-agent
```

# Output jenkins jenkins-agent pod yaml (optional as it is checked-in already)
``` SH
helm template -f helm/values.yaml jenkins-agent helm

# use the output from above as kubernetes pod template 'yaml' value for 'jenkins-agent' label agent in master/jenkins.yaml file
```