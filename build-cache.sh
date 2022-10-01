#!/bin/bash
set -e

##
## This script will do use SteamCMD to download TF2 dedicated server to the local
## cache.
##

docker run --rm -v "$(pwd)/cache/linux/tf2":/output lacledeslan/steamcmd ./steamcmd.sh +force_install_dir /output +login anonymous +app_update 232250 validate +quit
