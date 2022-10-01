#!/bin/bash
set -e

##
## This script will do a full update to gamesvr-tf2, so it can then be pushed to
## DockerHUB
##

echo -e '\n\033[1m[Preflight Checks]\033[0m'
echo -e "Docker client version: '$(docker version --format '{{.Client.Version}}')'"
echo -e "Docker server version: '$(docker version --format '{{.Server.Version}}')'"


echo -e '\n\033[1m[Build Image]\033[0m'
docker build . -f linux.Dockerfile --rm -t lacledeslan/gamesvr-tf2:latest --no-cache --pull --build-arg BUILDNODE=$(cat /proc/sys/kernel/hostname);


echo -e '\n\033[1m[Running Self-Checks]\033[0m'
docker run -it --rm lacledeslan/gamesvr-tf2:latest ./ll-tests/gamesvr-tf2.sh


echo -e '\n\033[1m[Pushing to Docker Hub]\033[0m'
docker tag lacledeslan/gamesvr-tf2:latest lacledeslan/gamesvr-tf2:base
echo "> push lacledeslan/gamesvr-tf2:base"
docker push lacledeslan/gamesvr-tf2:base
echo "> push lacledeslan/gamesvr-tf2:latest"
docker push lacledeslan/gamesvr-tf2:latest
