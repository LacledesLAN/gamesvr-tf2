#!/bin/bash
set -e;
set -u;


####################################################################################################
## Options
####################################################################################################

# Default options
option_delta_updates=false;	# Only build delta layer at the base image level?

# Parse command line options
while [ "$#" -gt 0 ]
do
	case "$1" in
		# options
		-d|--delta)
			option_delta_updates=true;
			;;
		# unknown
		*)
			echo "Error: unknown option '${1}'. Exiting." >&2;
			exit 12;
			;;
	esac
	shift
done;


####################################################################################################
## Helper Functions
####################################################################################################

# Custom sigterm handler, so that interupt signals terminate the script, not just a single command.
sigterm_handler() {
	echo -e "\n";
	exit 1;
}

trap 'trap " " SIGINT SIGTERM SIGHUP; kill 0; wait; sigterm_handler' SIGINT SIGTERM SIGHUP;


if [ "$option_delta_updates" != 'true' ]; then
    #
    # Full Update
    #

    echo -e '\n\033[1m[Build Image]\033[0m';
    docker build . -f linux.Dockerfile --rm -t lacledeslan/gamesvr-tf2:base --no-cache --pull --build-arg BUILDNODE="$(cat /proc/sys/kernel/hostname)";
else
    #
    # Delta Update
    #

    echo -e '\n\033[1m[Grabbing and Extracting SteamCMD]\033[0m'
    # to bad `--volumes-from` doesn't support path aliasing ヽ(ಠ_ಠ)ノ
    docker pull lacledeslan/steamcmd:latest
    docker container rm LLSteamCMD-Extractor &>/dev/null || true
    docker create --name LLSteamCMD-Extractor lacledeslan/steamcmd:latest
    docker cp LLSteamCMD-Extractor:/app "$(pwd)/cache/linux/steamcmd"
    docker container rm LLSteamCMD-Extractor


    echo -e '\n\033[1m[Building Delta Container]\033[0m'
    docker pull lacledeslan/gamesvr-tf2:base
    docker container rm LL-TF2-DELTA-CAPTURE &>/dev/null || true
    docker run -it --name LL-TF2-DELTA-CAPTURE \
        --mount type=bind,source="$(pwd)"/cache/linux/steamcmd/app/,target=/steamcmd/ \
        lacledeslan/gamesvr-tf2 \
        /steamcmd/steamcmd.sh +force_install_dir /app +login anonymous +app_update 232250 +quit


    echo -e '\n\033[1m[Commiting Delta Container to Image]\033[0m'
    docker commit --change='CMD ["/bin/bash"]' --message="Content delta update $(date '+%d/%m/%Y %H:%M:%S')" "$(docker ps -aqf "name=LL-TF2-DELTA-CAPTURE")" lacledeslan/gamesvr-tf2:latest
    docker container rm LL-TF2-DELTA-CAPTURE
fi;


echo -e '\n\033[1m[Running Self-Checks]\033[0m';
docker run -it --rm lacledeslan/gamesvr-tf2:base ./ll-tests/gamesvr-tf2.sh;


if [ "$option_delta_updates" != 'true' ]; then
    #
    # Full Update
    #

    echo -e '\n\033[1m[Pushing to Docker Hub]\033[0m';
    docker tag lacledeslan/gamesvr-tf2:base lacledeslan/gamesvr-tf2:latest;
    echo "> push lacledeslan/gamesvr-tf2:base";
    docker push lacledeslan/gamesvr-tf2:base;
    echo "> push lacledeslan/gamesvr-tf2:latest";
    docker push lacledeslan/gamesvr-tf2:latest;
else
    #
    # Delta Update
    #
    echo -e '\n\033[1m[Pushing to Docker Hub]\033[0m'
    docker push lacledeslan/gamesvr-tf2:latest
fi;
