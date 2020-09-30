# Set the values for the variables by writing to the variables file - values-secret.yaml
``` SH
cd jenkins/agent/helm

# copy the template variable file
cp values.yaml values-secret.yaml

# substitute the value for <CICD_NAMESPACE> by replacing PLACEHOLDER in the command
# this should be the same as set in the file - jenkins/master/jenkins-vars-secret
# PLACEHOLDER e.g. jenkins
sed -i 's|<CICD_NAMESPACE>|PLACEHOLDER|g' values-secret.yaml

# substitute the value for <CONTAINER_REGISTRY_URL> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. docker.io
sed -i 's|<CONTAINER_REGISTRY_URL>|PLACEHOLDER|g' values-secret.yaml

# substitute the value for <CONTAINER_REPOSITORY_NAME> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. ankursoni
sed -i 's|<CONTAINER_REPOSITORY_NAME>|PLACEHOLDER|g' values-secret.yaml

# substitute the value for <JENKINS_IMAGE_NAME> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. fortio
# hardcoded image tags like jenkins-master and jenkins-agent will distinguish between the 2 image types
sed -i 's|<JENKINS_IMAGE_NAME>|PLACEHOLDER|g' values-secret.yaml

# verify the values-secret.yaml file by displaying its content
cat values-secret.yaml

# output should be something like this
namespace: jenkins
image:
  registry: docker.io
  repository: ankursoni
  name: fortio
  tag: jenkins-agent
  pullPolicy: Always
```

# Output jenkins agent pod yaml
``` SH
cd jenkins/agent/helm

helm template -f values-secret.yaml jenkins-agent .
```