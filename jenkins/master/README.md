# Set the values for the variables by writing to the variables file - jenkins-vars-secret
``` SH
cd jenkins/master

# copy the template variable file
cp jenkins-vars jenkins-vars-secret

# substitute the value for <GITHUB_USER_NAME> by replacing PLACEHOLDER in the following command:
sed -i 's|<GITHUB_USER_NAME>|PLACEHOLDER|g' jenkins-vars-secret
# for e.g., the command to substitute the value for <GITHUB_USER_NAME> with ankursoni as PLACEHOLDER looks like this:
# sed -i 's|<GITHUB_USER_NAME>|ankursoni|g' jenkins-vars-secret

# substitute the value for <GITHUB_USER_PAT> by replacing PLACEHOLDER in the command
# to generate a github personal access token (pat), visit https://github.com/settings/tokens
# and 'generate new token' with full 'repo' access and 'read:packages' permissions
sed -i 's|<GITHUB_USER_PAT>|PLACEHOLDER|g' jenkins-vars-secret

# substitute the value for <CONTAINER_REGISTRY_URL> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. docker.io
sed -i 's|<CONTAINER_REGISTRY_URL>|PLACEHOLDER|g' jenkins-vars-secret

# substitute the value for <CONTAINER_REPOSITORY_NAME> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. ankursoni
sed -i 's|<CONTAINER_REPOSITORY_NAME>|PLACEHOLDER|g' jenkins-vars-secret

# substitute the value for <JENKINS_IMAGE_NAME> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. fortosi
# hardcoded image tags like jenkins-master and jenkins-agent will distinguish between the 2 image types
sed -i 's|<JENKINS_IMAGE_NAME>|PLACEHOLDER|g' jenkins-vars-secret

# substitute the value for <CONTAINER_REGISTRY_USER_NAME> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. ankursoni
sed -i 's|<CONTAINER_REGISTRY_USER_NAME>|PLACEHOLDER|g' jenkins-vars-secret

# substitute the value for <CONTAINER_REGISTRY_USER_PASSWORD> by replacing PLACEHOLDER in the command
# for e.g., to generate a docker hub personal access token (pat), visit https://hub.docker.com/settings/security
# and generate 'new access token'
sed -i 's|<CONTAINER_REGISTRY_USER_PASSWORD>|PLACEHOLDER|g' jenkins-vars-secret

# substitute the value for <CICD_NAMESPACE> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. jenkins
# this namespace is a dedicated place for running jenkins pods in a kubernetes cluster
sed -i 's|<CICD_NAMESPACE>|PLACEHOLDER|g' jenkins-vars-secret

# substitute the value for <GITHUB_ORG> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. BulldozerLabs
sed -i 's|<GITHUB_ORG>|PLACEHOLDER|g' jenkins-vars-secret

# substitute the value for <INIT_REPO> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. fortosi
sed -i 's|<INIT_REPO>|PLACEHOLDER|g' jenkins-vars-secret

# substitute the value for <ENABLE_LOCAL_DOCKER> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. true
# enable this flag to true if you want to run jenkins in a local docker environment else keep it false if you are deploying to cloud
sed -i 's|<ENABLE_LOCAL_DOCKER>|PLACEHOLDER|g' jenkins-vars-secret
```
> NOTE:
>- Make sure the value for the variable - ENABLE_LOCAL_DOCKER is set to 'false' in the file - jenkins/master/jenkins-vars-secret
``` SH
# verify the jenkins-vars-secret file by displaying its content
cat jenkins-vars-secret

# output should be something like this
GITHUB_USER_NAME="ankursoni"
GITHUB_USER_PAT="<removed as secret>"
CONTAINER_REGISTRY_URL="docker.io"
CONTAINER_REPOSITORY_NAME="ankursoni"
JENKINS_IMAGE_NAME="fortosi"
CONTAINER_REGISTRY_USER_NAME="ankursoni"
CONTAINER_REGISTRY_USER_PASSWORD="<removed as secret>"
CICD_NAMESPACE="jenkins"
ENABLE_LOCAL_DOCKER=true

# if there is a correction needed then use text editor 'nano' to update the file and then press ctrl+x after you are done editing
nano jenkins-vars-secret
```

# Build jenkins master docker image
``` SH
cd jenkins/master

docker build -t <CONTAINER_REGISTRY_URL>/<CONTAINER_REPOSITORY_NAME>/<JENKINS_IMAGE_NAME>:jenkins-master .
# for e.g., for 'docker.io' as <CONTAINER_REGISTRY_URL>, 'ankursoni' as <CONTAINER_REPOSITORY_NAME> and 'fortosi' as <JENKINS_IMAGE_NAME>:
# docker build -t docker.io/ankursoni/fortosi:jenkins-master .
```

# Start jenkins master docker locally (it rebuilds image also)
``` SH
cd jenkins/master

chmod +x ../scripts/*.sh

../scripts/start-local.sh

# to disable docker clean, then:
../scripts/start-local.sh true

# browse jenkins portal: http://127.0.0.1:8080
```

# Stop jenkins master docker locally (it deletes hello-world demo apps also)
``` SH
cd jenkins/master

chmod +x ../scripts/*.sh

../scripts/stop-local.sh

# to disable docker clean, then:
../scripts/stop-local.sh true
```

# Publish jenkins master docker image (not required if you are running locally)
``` SH
docker login <CONTAINER_REGISTRY_URL> -u <USERNAME>
# for e.g., for 'docker.io' as <CONTAINER_REGISTRY_URL> and 'ankursoni' as <USERNAME>:
docker login docker.io -u ankursoni

docker push <CONTAINER_REGISTRY_URL>/<CONTAINER_REPOSITORY_NAME>/<JENKINS_IMAGE_NAME>:jenkins-master
# for e.g., for 'docker.io' as <CONTAINER_REGISTRY_URL>, 'ankursoni' as <CONTAINER_REPOSITORY_NAME> and 'fortosi' as <JENKINS_IMAGE_NAME>:
# docker push docker.io/ankursoni/fortosi:jenkins-master
```