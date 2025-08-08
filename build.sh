#!/bin/bash
set -euo pipefail


####################################################################################################
## Options
####################################################################################################

# Default options
option_delta_updates=false;	# Only build delta layer at the base image level?
option_skip_base=false;		# Skip base builds?

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

# Custom sigterm handler, so that interrupt signals terminate the script, not just a single command.
sigterm_handler() {
	echo -e "\n";
	exit 1;
}

trap 'trap " " SIGINT SIGTERM SIGHUP; kill 0; wait; sigterm_handler' SIGINT SIGTERM SIGHUP;


####################################################################################################
## Build Stuff
####################################################################################################

# Get the hostname of this build node
readonly build_node="$(cat /proc/sys/kernel/hostname)"

# Get the current Git commit hash and mark as dirty if needed
readonly commit_hash="$(
    hash=$(git rev-parse --short HEAD)
    git fetch --quiet
    if ! git diff --quiet || ! git status -uno | grep -q 'Your branch is up to date'; then
        echo "${hash}-dirty"
    else
        echo "${hash}"
    fi
)"


echo -e '\n\n';
echo -e '\033[1m/===========================\\\033[0m'
echo -e '\033[1m[ tf2-base / tf2-base-delta ]\033[0m'
echo -e '\033[1m\\===========================/\033[0m'


if [ "$option_delta_updates" != 'true' ]; then
    #
    # Full Update
    #

    echo -e '\n\033[1m[Build Image]\033[0m';
    docker build . -f linux-base.Dockerfile --rm --tag lacledeslan/gamesvr-tf2:base-full --tag lacledeslan/gamesvr-tf2:base-latest --no-cache --pull --build-arg BUILDNODE="$build_node" --build-arg SOURCECOMMIT="$commit_hash"

    echo -e '\n\033[1m[Pushing to Docker Hub]\033[0m';
    echo "> push lacledeslan/gamesvr-tf2:base-full";
    docker push lacledeslan/gamesvr-tf2:base-full
    echo "> push lacledeslan/gamesvr-tf2:base-latest";
    docker push lacledeslan/gamesvr-tf2:base-latest
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
    docker container rm --force LLSteamCMD-Extractor &>/dev/null || true


    echo -e '\n\033[1m[Building base-latest Container]\033[0m'
    docker pull lacledeslan/gamesvr-tf2:base-full
    docker container rm LL-TF2-DELTA-CAPTURE &>/dev/null || true
    docker run -it --name LL-TF2-DELTA-CAPTURE \
        --mount type=bind,source="$(pwd)"/cache/linux/steamcmd/app/,target=/steamcmd/ \
        lacledeslan/gamesvr-tf2:base-full \
        /steamcmd/steamcmd.sh +force_install_dir /app +login anonymous +app_update 232250 +quit


    echo -e '\n\033[1m[Committing base-latest Container to Image]\033[0m'
    docker commit --change='CMD ["/bin/bash"]' --message="Content base latest update $(date '+%d/%m/%Y %H:%M:%S')" "$(docker ps -aqf "name=LL-TF2-DELTA-CAPTURE")" lacledeslan/gamesvr-tf2:base-latest
    docker container rm --force LL-TF2-DELTA-CAPTURE &>/dev/null || true

    echo -e '\n\033[1m[Pushing to Docker Hub]\033[0m';
    echo "> push lacledeslan/gamesvr-tf2:base-latest";
    docker push lacledeslan/gamesvr-tf2:base-latest;
fi;


echo -e '\n\n';
echo -e '\033[1m/===========================\\\033[0m'
echo -e '\033[1m[        x64 (64-bit)        ]\033[0m'
echo -e '\033[1m\\===========================/\033[0m'

echo -e '\n\033[1m[Build Image]\033[0m';
docker build . -f linux-x64.Dockerfile --rm --tag lacledeslan/gamesvr-tf2:latest --tag lacledeslan/gamesvr-tf2:64-bit --no-cache --pull --build-arg BUILDNODE="$build_node" --build-arg SOURCECOMMIT="$commit_hash"

echo -e '\n\033[1m[Self-Checks]\033[0m';
docker run -it --rm lacledeslan/gamesvr-tf2:latest ./ll-tests/gamesvr-tf2.sh;

echo -e '\n\033[1m[Push to Docker Hub]\033[0m';
echo "> push lacledeslan/gamesvr-tf2:latest";
docker push lacledeslan/gamesvr-tf2:latest
echo "> push lacledeslan/gamesvr-tf2:64-bit";
docker push lacledeslan/gamesvr-tf2:64-bit


echo -e '\n\n';
echo -e '\033[1m/===========================\\\033[0m'
echo -e '\033[1m[        x86 (32-bit)        ]\033[0m'
echo -e '\033[1m\\===========================/\033[0m'

echo -e '\n\033[1m[Build Image]\033[0m';
docker build . -f linux-x86.Dockerfile --rm --tag lacledeslan/gamesvr-tf2:32-bit --no-cache --pull --build-arg BUILDNODE="$build_node" --build-arg SOURCECOMMIT="$commit_hash"

echo -e '\n\033[1m[Self-Checks]\033[0m';
docker run -it --rm lacledeslan/gamesvr-tf2:32-bit ./ll-tests/gamesvr-tf2.sh;

echo -e '\n\033[1m[Push to Docker Hub]\033[0m';
echo "> push lacledeslan/gamesvr-tf2:32-bit";
docker push lacledeslan/gamesvr-tf2:32-bit
