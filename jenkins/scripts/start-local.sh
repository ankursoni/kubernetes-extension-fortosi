#!/bin/bash
# locally executed script assumes the current/execution directory:
# "cd jenkins/master"
# $1 - disable docker clean

# remove container if running already
docker rm jenkins-master -f

# docker build
docker build -t jenkins-master .

# clean docker
if [ -z "$1" ] || ( ! $1 )
then
  docker system prune -f
  docker volume prune -f
fi

# run container mounting /var/run/docker.sock from host path so that docker daemon from host is available
docker run --name jenkins-master -d -p 8080:8080 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  jenkins-master

# collect docker group id from host
docker_gid=$(getent group | grep -oP "^docker:x:\K\d+(?=:.*$)")

# exec bash as root to apply permissions to jenkins user by adding to a new docker group with same gid as host
docker exec --user root jenkins-master bash -c "groupadd docker -g $docker_gid; usermod -aG docker jenkins"

# restart container
docker restart jenkins-master

echo "Browse jenkins portal: http://127.0.0.1:8080"