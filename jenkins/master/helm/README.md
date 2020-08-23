# Set the kubectl context
``` SH
az aks get-credentials -n <AKS_NAME> -g <AKS_RG>
```

# Set the values for the variables by writing to the variables file - values-secret.yaml
``` SH
cd jenkins/master/helm

# copy the template variable file
cp values.yaml values-secret.yaml

# substitute the value for <CICD_NAMESPACE> by replacing PLACEHOLDER in the command
# this should be the same as set in the file - jenkins/master/jenkins-vars-secret
# PLACEHOLDER e.g. jenkins
sed -i 's|<CICD_NAMESPACE>|PLACEHOLDER|g' values-secret.yaml


# login to docker hub or other container registry
docker login

# copy the flat content from the file ~/.docker/config.json
docker_config=$(cat ~/.docker/config.json | tr -d '\n' | tr -d '\t')

# substitute the value for <DOCKER_CONFIG> by running the following command:
sed -i "s|<DOCKER_CONFIG>|$docker_config|g" values-secret.yaml


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


# login to az
az login
az account list -o table
# note the id as <SUBSCRIPTION_ID> from the output of previous command

# substitute the value for <SUBSCRIPTION_ID> by replacing PLACEHOLDER in the following command:
sed -i 's|<SUBSCRIPTION_ID>|PLACEHOLDER|g' values-secret.yaml

# substitute the value for <STORAGE_ACCOUNT_NAME> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. fortiodemosa01
sed -i 's|<STORAGE_ACCOUNT_NAME>|PLACEHOLDER|g' values-secret.yaml

# determine the storage account key by substituting <STORAGE_ACCOUNT_NAME> in the following command:
storage_key=$(az storage account keys list --account-name <STORAGE_ACCOUNT_NAME> --query "[0]".{Key:value} -o tsv)

# substitute the value for <STORAGE_ACCOUNT_KEY> by running the following command:
sed -i "s|<STORAGE_ACCOUNT_KEY>|$storage_key|g" values-secret.yaml


# substitute the value for <MANAGED_DISK_NAME> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. fortio-demo-md01
sed -i 's|<MANAGED_DISK_NAME>|PLACEHOLDER|g' values-secret.yaml

# substitute the value for <MANAGED_DISK_RG> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. fortio-demo-rg01
sed -i 's|<MANAGED_DISK_RG>|PLACEHOLDER|g' values-secret.yaml

# verify the values-secret.yaml file by displaying its content
cat values-secret.yaml

# output should be something like this
namespace: jenkins
dockerConfig: '<removed as secret>'
image:
  registry: docker.io
  repository: ankursoni
  name: fortio
  tag: jenkins-master
  pullPolicy: Always
storageAccount:
  name: fortiodemosa01
  key: <removed as secret>
managedDisk:
  name: fortio-demo-md01
  uri: /subscriptions/794a7d2a-565a-4ebd-8dd9-0439763e6b55/resourceGroups/fortio-demo-rg01/providers/Microsoft.Compute/disks/fortio-demo-md01
```

# Upload the kubeconfig file to azure file share for in place deployment of applications
``` SH
# get the aks credentials by substituting <AKS_NAME> and <AKS_RG> in the following command:
az aks get-credentials -n <AKS_NAME> -g <AKS_RG> \
  --overwrite-existing -f kubeconfig-secret

# copy the kubeconfig-secret as config
cp kubeconfig-secret config

# upload the kube config file by substituting <SUBSCRIPTION_ID>, <STORAGE_ACCOUNT_NAME> and <STORAGE_ACCOUNT_KEY> in the following command:
az storage file upload --subscription <SUBSCRIPTION_ID> \
  --account-name <STORAGE_ACCOUNT_NAME> --account-key '<STORAGE_ACCOUNT_KEY>' \
  --share-name deployment-kubeconfig --source ./config

# remove the config file
rm config -f
```

# Deploy jenkins master helm chart
``` SH
cd jenkins/master/helm

helm install -f values-secret.yaml jenkins-master .
```

# Browse jenkins portal
``` SH
# forward port 8080 from inside jenkins master pod to port 8090 on host
kubectl port-forward -n <CICD_NAMESPACE> service/jenkins-master-internal-svc 8090:8080
```