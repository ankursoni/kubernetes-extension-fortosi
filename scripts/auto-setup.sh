#!/bin/bash
# kubectl extension script either copied to /usr/local/bin/kubectl-fortio
# or, locally executed script assumes the current/execution directory one level above kubernetes-extension-fortio git directory
# $1 - secret variables values file

# stop on error
set -e

# secret variables values file validation
if [ -z "$1" ] || [ ! -f "$1" ]
then
  echo "Variables values file not provided or does not exists!"
  exit
fi

# load variables
source $1

# kubernetes-extension-fortio git clone path validation
if [ -z "$FORTIO_GIT_CLONE_PATH" ] || [ ! -d "$FORTIO_GIT_CLONE_PATH" ]
then
  echo "kubernetes-extension-fortio git clone path not set or does not exists!"
  exit
fi

echo -e "\nBuilding docker agent image - $CONTAINER_REGISTRY_URL/$CONTAINER_REPOSITORY_NAME/$JENKINS_IMAGE_NAME:jenkins-agent"
docker build -t $CONTAINER_REGISTRY_URL/$CONTAINER_REPOSITORY_NAME/$JENKINS_IMAGE_NAME:jenkins-agent $FORTIO_GIT_CLONE_PATH/jenkins/agent

docker logout

docker login $CONTAINER_REGISTRY_URL -u $CONTAINER_REGISTRY_USER_NAME -p $CONTAINER_REGISTRY_USER_PASSWORD

echo -e "\nPublishing docker agent image - $CONTAINER_REGISTRY_URL/$CONTAINER_REPOSITORY_NAME/$JENKINS_IMAGE_NAME:jenkins-agent"
docker push $CONTAINER_REGISTRY_URL/$CONTAINER_REPOSITORY_NAME/$JENKINS_IMAGE_NAME:jenkins-agent


echo -e "\nSetting kubectl context"
sub=$((az account list -o table || echo '') | grep $SUBSCRIPTION_ID)
if [ -z "$sub" ]
then az login
fi
az account set --subscription $SUBSCRIPTION_ID
storage_key=$(az storage account keys list --account-name ${STORAGE_ACCOUNT_NAME} --query "[0]".{Key:value} -o tsv)

rm -f $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/kubeconfig-secret
az aks get-credentials -n $AKS_NAME -g $AKS_RG \
  --overwrite-existing -f $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/kubeconfig-secret
cp $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/kubeconfig-secret config
az storage file upload --subscription $SUBSCRIPTION_ID \
  --account-name $STORAGE_ACCOUNT_NAME --account-key $storage_key \
  --share-name deployment-kubeconfig --source ./config
rm -f config


cp ~/.kube/config ~/.kube/config.bak
export KUBECONFIG=$FORTIO_GIT_CLONE_PATH/jenkins/master/helm/kubeconfig-secret:~/.kube/config.bak
kubectl config view --flatten > ~/.kube/config
rm -f ~/.kube/config.bak

echo -e "\nWriting jenkins agent helm chart secret values file - values-secret.yaml"
cp $FORTIO_GIT_CLONE_PATH/jenkins/agent/helm/values.yaml $FORTIO_GIT_CLONE_PATH/jenkins/agent/helm/values-secret.yaml
sed -i "s|<CICD_NAMESPACE>|${CICD_NAMESPACE}|g" $FORTIO_GIT_CLONE_PATH/jenkins/agent/helm/values-secret.yaml
sed -i "s|<CONTAINER_REGISTRY_URL>|${CONTAINER_REGISTRY_URL}|g" $FORTIO_GIT_CLONE_PATH/jenkins/agent/helm/values-secret.yaml
sed -i "s|<CONTAINER_REPOSITORY_NAME>|${CONTAINER_REPOSITORY_NAME}|g" $FORTIO_GIT_CLONE_PATH/jenkins/agent/helm/values-secret.yaml
sed -i "s|<JENKINS_IMAGE_NAME>|${JENKINS_IMAGE_NAME}|g" $FORTIO_GIT_CLONE_PATH/jenkins/agent/helm/values-secret.yaml
sed -i "s|<CLOUD_PROVIDER>|$CLOUD_PROVIDER|g" $FORTIO_GIT_CLONE_PATH/jenkins/agent/helm/values-secret.yaml

echo -e "\nGenerating jenkins-agent pod definition yaml"
helm install --dry-run -o yaml jenkins-agent -f $FORTIO_GIT_CLONE_PATH/jenkins/agent/helm/values-secret.yaml $FORTIO_GIT_CLONE_PATH/jenkins/agent/helm/ | \
  yq r - manifest | yq d - metadata.name | tail -n +2 | sed 's|^|              |' > $FORTIO_GIT_CLONE_PATH/jenkins/master/jenkins-agent.yaml


echo -e "\nWriting jenkins master docker secret values file - jenkins-vars-secret"
cp $FORTIO_GIT_CLONE_PATH/jenkins/master/jenkins-vars $FORTIO_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<GITHUB_USER_NAME>|${GITHUB_USER_NAME}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<GITHUB_USER_PAT>|${GITHUB_USER_PAT}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<CONTAINER_REGISTRY_URL>|${CONTAINER_REGISTRY_URL}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<CONTAINER_REPOSITORY_NAME>|${CONTAINER_REPOSITORY_NAME}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<JENKINS_IMAGE_NAME>|${JENKINS_IMAGE_NAME}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<CONTAINER_REGISTRY_USER_NAME>|${CONTAINER_REGISTRY_USER_NAME}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<CONTAINER_REGISTRY_USER_PASSWORD>|${CONTAINER_REGISTRY_USER_PASSWORD}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<CICD_NAMESPACE>|${CICD_NAMESPACE}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<GITHUB_ORG>|${GITHUB_ORG}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<INIT_REPO>|${INIT_REPO}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<ENABLE_LOCAL_DOCKER>|${ENABLE_LOCAL_DOCKER}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret

echo -e "\nBuilding docker master image - $CONTAINER_REGISTRY_URL/$CONTAINER_REPOSITORY_NAME/$JENKINS_IMAGE_NAME:jenkins-master"
docker build -t $CONTAINER_REGISTRY_URL/$CONTAINER_REPOSITORY_NAME/$JENKINS_IMAGE_NAME:jenkins-master $FORTIO_GIT_CLONE_PATH/jenkins/master

echo -e "\nPublishing docker master image - $CONTAINER_REGISTRY_URL/$CONTAINER_REPOSITORY_NAME/$JENKINS_IMAGE_NAME:jenkins-master"
docker push $CONTAINER_REGISTRY_URL/$CONTAINER_REPOSITORY_NAME/$JENKINS_IMAGE_NAME:jenkins-master


echo -e "\nWriting jenkins master helm chart secret values file - values-secret.yaml"
cp $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/values.yaml $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<CICD_NAMESPACE>|${CICD_NAMESPACE}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml

docker_config=$(cat "$FORTIO_GIT_CLONE_PATH/jenkins/master/helm/docker-config.json")
if [ -z "$(echo $CONTAINER_REGISTRY_URL | grep -oP '^docker.io')" ]
then docker_config=$(echo $docker_config | sed "s|<CONTAINER_REGISTRY_URL>|${CONTAINER_REGISTRY_URL}|g")
else docker_config=$(echo $docker_config | sed "s|<CONTAINER_REGISTRY_URL>|https://index.docker.io/v1/|g")
fi
docker_config=$(echo $docker_config | sed "s|<CONTAINER_REGISTRY_AUTH>|$(echo ${CONTAINER_REGISTRY_USER_NAME}:${CONTAINER_REGISTRY_USER_PASSWORD} | tr -d '\n' | base64)|g")

sed -i "s|<CLOUD_PROVIDER>|$CLOUD_PROVIDER|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<STORAGE_ACCOUNT_KEY>|$storage_key|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<SUBSCRIPTION_ID>|${SUBSCRIPTION_ID}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<DOCKER_CONFIG>|${docker_config}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<CONTAINER_REGISTRY_URL>|${CONTAINER_REGISTRY_URL}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<CONTAINER_REPOSITORY_NAME>|${CONTAINER_REPOSITORY_NAME}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<JENKINS_IMAGE_NAME>|${JENKINS_IMAGE_NAME}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<STORAGE_ACCOUNT_NAME>|${STORAGE_ACCOUNT_NAME}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<MANAGED_DISK_RG>|${MANAGED_DISK_RG}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<MANAGED_DISK_NAME>|${MANAGED_DISK_NAME}|g" $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml

echo -e "\nDeploying jenkins master helm chart"
release=$(helm list -q -f jenkins-master)
if [ -z $release ]
then
  helm install -f $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml jenkins-master $FORTIO_GIT_CLONE_PATH/jenkins/master/helm
  echo -e "\nSleeping for 4 minutes..."
  sleep 240
else
  helm upgrade -f $FORTIO_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml jenkins-master $FORTIO_GIT_CLONE_PATH/jenkins/master/helm
  echo -e "\nSleeping for 1 minute..."
  sleep 60
fi

echo -e "\nBrowsing jenkins portal"
kubectl port-forward -n $CICD_NAMESPACE service/jenkins-master-internal-svc 8090:8080