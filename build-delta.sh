#!/bin/bash
set -e

##
## This script will do a quick update to gamesvr-tf2, creating a "delta" layer, that can then be pushed to
## DockerHUB. Image is not as clean as building from scratch - but this process is significantly faster and
## good for tight deadlines.
##

echo -e '\n\033[1m[Preflight Checks]\033[0m'
echo -e "Docker client version: '$(docker version --format '{{.Client.Version}}')'"
echo -e "Docker server version: '$(docker version --format '{{.Server.Version}}')'"


echo -e '\n\033[1m[Grabbing and Extracting SteamCMD]\033[0m'
# to bad `--volumes-from` doesn't support path aliasing ヽ(ಠ_ಠ)ノ
docker pull lacledeslan/steamcmd:latest
docker container rm LLSteamCMD-Extractor &>/dev/null || true
docker create --name LLSteamCMD-Extractor lacledeslan/steamcmd:latest
docker cp LLSteamCMD-Extractor:/app "$(pwd)/.steamcmd/linux"
docker container rm LLSteamCMD-Extractor


echo -e '\n\033[1m[Building Delta Container]\033[0m'
docker pull lacledeslan/gamesvr-tf2:base
docker container rm LL-TF2-DELTA-CAPTURE &>/dev/null || true
docker run -it --name LL-TF2-DELTA-CAPTURE \
    --mount type=bind,source="$(pwd)"/.steamcmd/linux/app/,target=/steamcmd/ \
    lacledeslan/gamesvr-tf2 \
    /steamcmd/steamcmd.sh +force_install_dir /app +login anonymous +app_update 232250 +quit


echo -e '\n\033[1m[Commiting Delta Container to Image]\033[0m'
docker commit --change='CMD ["/bin/bash"]' --message="Content delta update $(date '+%d/%m/%Y %H:%M:%S')" "$(docker ps -aqf "name=LL-TF2-DELTA-CAPTURE")" lacledeslan/gamesvr-tf2:latest
docker container rm LL-TF2-DELTA-CAPTURE

echo -e '\n\033[1m[Running Image Self-Checks]\033[0m'
docker run -it --rm lacledeslan/gamesvr-tf2:latest ./ll-tests/gamesvr-tf2.sh


echo -e '\n\033[1m[Pushing to Docker Hub]\033[0m'
docker push lacledeslan/gamesvr-tf2:latest
