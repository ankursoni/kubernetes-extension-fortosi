#!/bin/bash
# $1 - container name
# $2 - container image with tag

docker rm $1 -f
docker run -d -p 8082:80 --name $1 $2