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

helm upgrade -i -f values.yaml $5 .