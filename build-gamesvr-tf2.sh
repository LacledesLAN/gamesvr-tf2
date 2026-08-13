#!/bin/bash
set -euo pipefail

exec 3>&1
exec 1>&2

printf '## Build gamesvr-tf2\n\n'

created_image_tags=()
command_fence_open=false

record_image_tag() {
    local image_tag="$1"
    local existing_tag

    for existing_tag in "${created_image_tags[@]+"${created_image_tags[@]}"}"; do
        [[ "$existing_tag" == "$image_tag" ]] && return 0
    done
    created_image_tags+=("$image_tag")
}

run_fenced() {
    local command_status=0
    local escape_character=$'\033'

    printf '````````console\n'
    command_fence_open=true
    if "$@" 2>&1 | tr '\r' '\n' | sed -E "s/${escape_character}\\[[0-9;?]*[[:alpha:]]//g"; then
        command_status=${PIPESTATUS[0]}
    else
        command_status=${PIPESTATUS[0]}
    fi
    command_fence_open=false
    printf '````````\n\n'
    return "$command_status"
}

on_exit() {
    local exit_status=$?

    trap - EXIT HUP INT TERM PIPE
    trap '' HUP INT TERM PIPE
    set +e
    if [[ "$command_fence_open" == true ]]; then
        printf '````````\n\n'
        command_fence_open=false
    fi
    if (( ${#created_image_tags[@]} > 0 )); then
        printf '\n### Completed images\n\n' >&2
    fi
    exec 1>&3
    if (( ${#created_image_tags[@]} > 0 )); then
        printf '%s\n' "${created_image_tags[@]}" 2>/dev/null || true
    fi
    exit "$exit_status"
}

trap on_exit EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM


####################################################################################################
## Options
####################################################################################################

build_options=()

# Parse command line options
while [ "$#" -gt 0 ]
do
	case "$1" in
        --delta) build_options+=('--delta') ;;
        --enable-steamcmd-cache) build_options+=('--enable-steamcmd-cache') ;;
        --disable-docker-cache) build_options+=('--disable-docker-cache') ;;
        --progress-plain) build_options+=('--progress-plain') ;;
        --skip-pull) build_options+=('--skip-pull') ;;
        --skip-tests) build_options+=('--skip-tests') ;;
        --skip-push) build_options+=('--skip-push') ;;
		# unknown
		*)
			echo "Error: unknown option '${1}'. Exiting." >&2;
			exit 12;
			;;
	esac
	shift
done;

# DESCRIPTION: Reports whether a common build option was specified.
# PARAMETERS:
#   $1 (option_name) - Canonical command-line option to find in build_options.
# RETURNS:
#   0 - The option is present.
#   1 - The option is absent.
has_build_option() {
    local element
    for element in "${build_options[@]}"; do
        [[ "$element" == "$1" ]] && return 0
    done
    return 1
}

required_commands=(date docker git grep hostname sed tr)
for required_command in "${required_commands[@]}"; do
    if ! command -v "$required_command" > /dev/null 2>&1; then
        printf "ERROR: Required command '%s' is not installed or not in PATH.\n" "$required_command" >&2
        exit 1
    fi
done
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    printf "ERROR: The current directory is not a Git repository.\n" >&2
    exit 1
fi
if ! docker info > /dev/null 2>&1; then
    printf "ERROR: Docker is installed, but the current user cannot access the Docker daemon.\n" >&2
    exit 1
fi

if has_build_option '--enable-steamcmd-cache'; then
    echo "--enable-steamcmd-cache has no effect for this project."
fi
if has_build_option '--skip-tests' && ! has_build_option '--skip-push'; then
    echo "WARNING: --skip-tests was specified without --skip-push. The requested images will be pushed without testing." >&2
fi
if ! has_build_option '--skip-tests' && [[ ! -x ./test-gamesvr-tf2.sh ]]; then
    echo "ERROR: Required test script is missing or not executable: ./test-gamesvr-tf2.sh" >&2
    exit 1
fi

docker_options=()
if ! has_build_option '--skip-pull'; then
    docker_options+=(--pull)
else
    echo "Skipping explicit pulls and Docker build pulls because --skip-pull was specified."
fi
if has_build_option '--disable-docker-cache'; then
    docker_options+=(--no-cache)
fi
if has_build_option '--progress-plain'; then
    docker_options+=(--progress=plain)
fi

####################################################################################################
## Helper Functions
####################################################################################################

####################################################################################################
## Build Stuff
####################################################################################################

# Get the hostname of this build node
build_node="$(hostname)"
readonly build_node

# Get the current Git commit hash and mark as dirty if needed
printf '### Source metadata\n\n'
run_fenced git fetch --quiet
commit_hash="$(
    hash=$(git rev-parse HEAD)
    if ! git diff --quiet || ! git status -uno | grep -q 'Your branch is up to date'; then
        echo "${hash}-dirty"
    else
        echo "${hash}"
    fi
)"
readonly commit_hash

printf '### Base images\n\n'


if ! has_build_option '--delta'; then
    echo "Full Rebuild of base layers";

    printf '#### Build\n\n'
    run_fenced docker build . "${docker_options[@]}" -f linux-base.Dockerfile --rm --tag gamesvr-tf2:base-full --tag gamesvr-tf2:base-latest --tag lacledeslan/gamesvr-tf2:base-full --tag lacledeslan/gamesvr-tf2:base-latest --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" --build-arg BUILD_NODE="$build_node" --build-arg GIT_REVISION="$commit_hash"
    record_image_tag gamesvr-tf2:base-full
    record_image_tag gamesvr-tf2:base-latest
    record_image_tag lacledeslan/gamesvr-tf2:base-full
    record_image_tag lacledeslan/gamesvr-tf2:base-latest

    if ! has_build_option '--skip-tests'; then
        printf '#### Tests\n\n'
        run_fenced ./test-gamesvr-tf2.sh gamesvr-tf2:base-latest
    else
        echo "Skipping base-image test because --skip-tests was specified."
    fi

    if ! has_build_option '--skip-push'; then
        printf '#### Push\n\n'
        echo "> push lacledeslan/gamesvr-tf2:base-full";
        run_fenced docker push lacledeslan/gamesvr-tf2:base-full
        echo "> push lacledeslan/gamesvr-tf2:base-latest";
        run_fenced docker push lacledeslan/gamesvr-tf2:base-latest
    else
        echo "Skipping base-image pushes because --skip-push was specified."
    fi
else
    echo "Delta update of base-latest";

    printf '#### Prepare SteamCMD\n\n'
    # to bad `--volumes-from` doesn't support path aliasing ヽ(ಠ_ಠ)ノ
    if ! has_build_option '--skip-pull'; then
        run_fenced docker pull lacledeslan/steamcmd:latest
    fi
    docker container rm LLSteamCMD-Extractor &>/dev/null || true
    run_fenced docker create --name LLSteamCMD-Extractor lacledeslan/steamcmd:latest
    run_fenced docker cp LLSteamCMD-Extractor:/app/tf2 "$(pwd)/cache/linux/steamcmd"
    docker container rm --force LLSteamCMD-Extractor &>/dev/null || true


    printf '#### Build delta container\n\n'
    if ! has_build_option '--skip-pull'; then
        run_fenced docker pull lacledeslan/gamesvr-tf2:base-full
    fi
    docker container rm LL-TF2-DELTA-CAPTURE &>/dev/null || true
    run_fenced docker run -it --name LL-TF2-DELTA-CAPTURE \
        --mount type=bind,source="$(pwd)"/cache/linux/steamcmd/app/tf2/,target=/steamcmd/ \
        lacledeslan/gamesvr-tf2:base-full \
        /steamcmd/steamcmd.sh +force_install_dir /app/tf2 +login anonymous +app_update 232250 +quit


    printf '#### Commit delta image\n\n'
    run_fenced docker commit --change='CMD ["/bin/bash"]' --message="Content base latest update $(date '+%d/%m/%Y %H:%M:%S')" "$(docker ps -aqf "name=LL-TF2-DELTA-CAPTURE")" gamesvr-tf2:base-latest
    record_image_tag gamesvr-tf2:base-latest
    run_fenced docker tag gamesvr-tf2:base-latest lacledeslan/gamesvr-tf2:base-latest
    record_image_tag lacledeslan/gamesvr-tf2:base-latest
    docker container rm --force LL-TF2-DELTA-CAPTURE &>/dev/null || true

    if ! has_build_option '--skip-tests'; then
        printf '#### Tests\n\n'
        run_fenced ./test-gamesvr-tf2.sh gamesvr-tf2:base-latest
    else
        echo "Skipping base-image test because --skip-tests was specified."
    fi

    if ! has_build_option '--skip-push'; then
        printf '#### Push\n\n'
        echo "> push lacledeslan/gamesvr-tf2:base-latest";
        run_fenced docker push lacledeslan/gamesvr-tf2:base-latest;
    else
        echo "Skipping base-image push because --skip-push was specified."
    fi
fi;


printf '### x64 image\n\n'
printf '#### Build\n\n'
run_fenced docker build . "${docker_options[@]}" -f linux-x64.Dockerfile --rm --tag gamesvr-tf2:latest --tag gamesvr-tf2:64-bit --tag lacledeslan/gamesvr-tf2:latest --tag lacledeslan/gamesvr-tf2:64-bit --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" --build-arg BUILD_NODE="$build_node" --build-arg GIT_REVISION="$commit_hash"
record_image_tag gamesvr-tf2:latest
record_image_tag gamesvr-tf2:64-bit
record_image_tag lacledeslan/gamesvr-tf2:latest
record_image_tag lacledeslan/gamesvr-tf2:64-bit

if ! has_build_option '--skip-tests'; then
    printf '#### Tests\n\n'
    run_fenced ./test-gamesvr-tf2.sh gamesvr-tf2:latest;
else
    echo "Skipping x64 tests because --skip-tests was specified."
fi

if ! has_build_option '--skip-push'; then
    printf '#### Push\n\n'
    echo "> push lacledeslan/gamesvr-tf2:latest";
    run_fenced docker push lacledeslan/gamesvr-tf2:latest
    echo "> push lacledeslan/gamesvr-tf2:64-bit";
    run_fenced docker push lacledeslan/gamesvr-tf2:64-bit
else
    echo "Skipping x64 pushes because --skip-push was specified."
fi


printf '### x86 image\n\n'
printf '#### Build\n\n'
run_fenced docker build . "${docker_options[@]}" -f linux-x86.Dockerfile --rm --tag gamesvr-tf2:32-bit --tag lacledeslan/gamesvr-tf2:32-bit --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" --build-arg BUILD_NODE="$build_node" --build-arg GIT_REVISION="$commit_hash"
record_image_tag gamesvr-tf2:32-bit
record_image_tag lacledeslan/gamesvr-tf2:32-bit

if ! has_build_option '--skip-tests'; then
    printf '#### Tests\n\n'
    run_fenced ./test-gamesvr-tf2.sh gamesvr-tf2:32-bit;
else
    echo "Skipping x86 tests because --skip-tests was specified."
fi

if ! has_build_option '--skip-push'; then
    printf '#### Push\n\n'
    echo "> push lacledeslan/gamesvr-tf2:32-bit";
    run_fenced docker push lacledeslan/gamesvr-tf2:32-bit
else
    echo "Skipping x86 push because --skip-push was specified."
fi
