#!/bin/bash
# kubectl extension script either copied to /usr/local/bin/kubectl-fortosi
# or, locally executed script assumes the current/execution directory in kubernetes-extension-fortosi git directory
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

# kubernetes-extension-fortosi git clone path validation
if [ -z "$FORTOSI_GIT_CLONE_PATH" ] || [ ! -d "$FORTOSI_GIT_CLONE_PATH" ]
then
  echo "kubernetes-extension-fortosi git clone path not set or does not exists!"
  exit
fi

echo -e "\nBuilding docker agent image - $CONTAINER_REGISTRY_URL/$CONTAINER_REPOSITORY_NAME/$JENKINS_IMAGE_NAME:jenkins-agent"
docker build --build-arg CLOUD_PROVIDER=$CLOUD_PROVIDER -t $CONTAINER_REGISTRY_URL/$CONTAINER_REPOSITORY_NAME/$JENKINS_IMAGE_NAME:jenkins-agent $FORTOSI_GIT_CLONE_PATH/jenkins/agent

docker logout

docker login $CONTAINER_REGISTRY_URL -u $CONTAINER_REGISTRY_USER_NAME -p $CONTAINER_REGISTRY_USER_PASSWORD

echo -e "\nPublishing docker agent image - $CONTAINER_REGISTRY_URL/$CONTAINER_REPOSITORY_NAME/$JENKINS_IMAGE_NAME:jenkins-agent"
docker push $CONTAINER_REGISTRY_URL/$CONTAINER_REPOSITORY_NAME/$JENKINS_IMAGE_NAME:jenkins-agent


echo -e "\nSetting kubectl context"
rm -f $FORTOSI_GIT_CLONE_PATH/jenkins/master/kubeconfig-secret
if [ $CLOUD_PROVIDER = 'aws' ]
then
  aws eks --region $AWS_REGION_CODE update-kubeconfig --name $AWS_EKS_NAME \
    --kubeconfig $FORTOSI_GIT_CLONE_PATH/jenkins/master/kubeconfig-secret
elif [ $CLOUD_PROVIDER = 'azure' ]
then
  az aks get-credentials -n $AZURE_AKS_NAME -g $AZURE_AKS_RG \
    --overwrite-existing -f $FORTOSI_GIT_CLONE_PATH/jenkins/master/kubeconfig-secret
fi

cp ~/.kube/config ~/.kube/config.bak | true
export KUBECONFIG=$FORTOSI_GIT_CLONE_PATH/jenkins/master/kubeconfig-secret:~/.kube/config.bak
kubectl config view --flatten > ~/.kube/config
rm -f ~/.kube/config.bak

if [ $CLOUD_PROVIDER = 'aws' ]
then
  kubectl apply -f $FORTOSI_GIT_CLONE_PATH/infra/aws/eks-admin-service-account.yaml
  token=$(kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}') | grep token: | awk '{print $2}')
  sed -i "/user:/a \ \ \ \ token: $token" $FORTOSI_GIT_CLONE_PATH/jenkins/master/kubeconfig-secret
fi

echo -e "\nWriting jenkins agent helm chart secret values file - values-secret.yaml"
cp $FORTOSI_GIT_CLONE_PATH/jenkins/agent/helm/values.yaml $FORTOSI_GIT_CLONE_PATH/jenkins/agent/helm/values-secret.yaml
sed -i "s|<CICD_NAMESPACE>|${CICD_NAMESPACE}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/agent/helm/values-secret.yaml
sed -i "s|<CONTAINER_REGISTRY_URL>|${CONTAINER_REGISTRY_URL}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/agent/helm/values-secret.yaml
sed -i "s|<CONTAINER_REPOSITORY_NAME>|${CONTAINER_REPOSITORY_NAME}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/agent/helm/values-secret.yaml
sed -i "s|<JENKINS_IMAGE_NAME>|${JENKINS_IMAGE_NAME}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/agent/helm/values-secret.yaml

echo -e "\nGenerating jenkins-agent pod definition yaml"
helm install --dry-run -o yaml jenkins-agent -f $FORTOSI_GIT_CLONE_PATH/jenkins/agent/helm/values-secret.yaml $FORTOSI_GIT_CLONE_PATH/jenkins/agent/helm/ | \
  yq r - manifest | yq d - metadata.name | tail -n +2 | sed 's|^|              |' > $FORTOSI_GIT_CLONE_PATH/jenkins/master/jenkins-agent.yaml


echo -e "\nWriting jenkins master docker secret values file - jenkins-vars-secret"
cp $FORTOSI_GIT_CLONE_PATH/jenkins/master/jenkins-vars $FORTOSI_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<GITHUB_USER_NAME>|${GITHUB_USER_NAME}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<GITHUB_USER_PAT>|${GITHUB_USER_PAT}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<CONTAINER_REGISTRY_URL>|${CONTAINER_REGISTRY_URL}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<CONTAINER_REPOSITORY_NAME>|${CONTAINER_REPOSITORY_NAME}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<JENKINS_IMAGE_NAME>|${JENKINS_IMAGE_NAME}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<CONTAINER_REGISTRY_USER_NAME>|${CONTAINER_REGISTRY_USER_NAME}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<CONTAINER_REGISTRY_USER_PASSWORD>|${CONTAINER_REGISTRY_USER_PASSWORD}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<CICD_NAMESPACE>|${CICD_NAMESPACE}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<GITHUB_ORG>|${GITHUB_ORG}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<INIT_REPO>|${INIT_REPO}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret
sed -i "s|<ENABLE_LOCAL_DOCKER>|${ENABLE_LOCAL_DOCKER}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/jenkins-vars-secret

echo -e "\nBuilding docker master image - $CONTAINER_REGISTRY_URL/$CONTAINER_REPOSITORY_NAME/$JENKINS_IMAGE_NAME:jenkins-master"
docker build -t $CONTAINER_REGISTRY_URL/$CONTAINER_REPOSITORY_NAME/$JENKINS_IMAGE_NAME:jenkins-master $FORTOSI_GIT_CLONE_PATH/jenkins/master

echo -e "\nPublishing docker master image - $CONTAINER_REGISTRY_URL/$CONTAINER_REPOSITORY_NAME/$JENKINS_IMAGE_NAME:jenkins-master"
docker push $CONTAINER_REGISTRY_URL/$CONTAINER_REPOSITORY_NAME/$JENKINS_IMAGE_NAME:jenkins-master


echo -e "\nWriting jenkins master helm chart secret values file - values-secret.yaml"
cp $FORTOSI_GIT_CLONE_PATH/jenkins/master/helm/values.yaml $FORTOSI_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<CICD_NAMESPACE>|${CICD_NAMESPACE}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml

docker_config=$(cat "$FORTOSI_GIT_CLONE_PATH/jenkins/master/helm/docker-config.json")
if [ -z "$(echo $CONTAINER_REGISTRY_URL | grep -oP '^docker.io')" ]
then docker_config=$(echo $docker_config | sed "s|<CONTAINER_REGISTRY_URL>|${CONTAINER_REGISTRY_URL}|g")
else docker_config=$(echo $docker_config | sed "s|<CONTAINER_REGISTRY_URL>|https://index.docker.io/v1/|g")
fi
docker_config=$(echo $docker_config | sed "s|<CONTAINER_REGISTRY_AUTH>|$(echo ${CONTAINER_REGISTRY_USER_NAME}:${CONTAINER_REGISTRY_USER_PASSWORD} | tr -d '\n' | base64)|g")

sed -i "s|<CLOUD_PROVIDER>|$CLOUD_PROVIDER|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<STORAGE_ACCOUNT_KEY>|$storage_key|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<AZURE_SUBSCRIPTION_ID>|${AZURE_SUBSCRIPTION_ID}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<DOCKER_CONFIG>|${docker_config}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<CONTAINER_REGISTRY_URL>|${CONTAINER_REGISTRY_URL}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<CONTAINER_REPOSITORY_NAME>|${CONTAINER_REPOSITORY_NAME}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<JENKINS_IMAGE_NAME>|${JENKINS_IMAGE_NAME}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<AWS_EFS_ID>|${AWS_EFS_ID}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<AZURE_MANAGED_DISK_RG>|${AZURE_MANAGED_DISK_RG}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml
sed -i "s|<AZURE_MANAGED_DISK_NAME>|${AZURE_MANAGED_DISK_NAME}|g" $FORTOSI_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml

if [ $CLOUD_PROVIDER = 'aws' ]
then
  echo -e "\nDeploying aws efs csi driver"
  kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/ecr/?ref=release-1.0"
fi

echo -e "\nDeploying jenkins master helm chart"
release=$(helm list -q -f jenkins-master)
if [ -z $release ]
then
  helm install -f $FORTOSI_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml jenkins-master $FORTOSI_GIT_CLONE_PATH/jenkins/master/helm
  echo -e "\nSleeping for 4 minutes..."
  sleep 240
else
  helm upgrade -f $FORTOSI_GIT_CLONE_PATH/jenkins/master/helm/values-secret.yaml jenkins-master $FORTOSI_GIT_CLONE_PATH/jenkins/master/helm
  echo -e "\nSleeping for 1 minute..."
  sleep 60
fi

echo -e "\nBrowsing jenkins portal"
kubectl port-forward -n $CICD_NAMESPACE service/jenkins-master-internal-svc 8090:8080