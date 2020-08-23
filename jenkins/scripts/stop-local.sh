#!/bin/bash
# $1 - disable docker clean

# load variables already set for the jenkins master
source jenkins-vars-secret

# remove container if running already
docker rm jenkins-master -f
docker rm hello-world-aspnetcore -f
docker rm hello-world-nodejs -f

# remove container images
docker rmi jenkins-master -f
docker rmi $(docker images --filter=reference="*$CONTAINER_REPOSITORY_NAME/hello-world-aspnetcore:*" -q) -f
docker rmi $(docker images --filter=reference="*$CONTAINER_REPOSITORY_NAME/hello-world-nodejs:*" -q) -f

# clean docker
if [ -z "$1" ] || ( ! $1 )
then
  docker system prune -f
  docker volume prune -f
fi
