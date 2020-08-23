#!/bin/bash
# $1 - namespace
# $2 - container registry url
# $3 - container repository name
# $4 - container image with tag
# $5 - app name

cd helm

sed -i "s|<NAMESPACE>|$1|g" values.yaml
sed -i "s|<CONTAINER_REGISTRY_URL>|$2|g" values.yaml
sed -i "s|<CONTAINER_REPOSITORY_NAME>|$3|g" values.yaml
sed -i "s|<IMAGE_WITH_TAG>|$4|g" values.yaml

isDeployedAlready=$(helm list -f $5 | grep -oP "^$5")
if [ -z "$isDeployedAlready" ]
then
    helm install -f values.yaml $5 .
else
    helm upgrade -f values.yaml $5 .
fi