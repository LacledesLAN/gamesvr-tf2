#!/bin/bash
set -euo pipefail

if (( $# != 1 )); then
    printf 'ERROR: Expected exactly one unqualified local image tag.\n' >&2
    exit 2
fi

image_tag="$1"
if [[ "$image_tag" != gamesvr-tf2 && "$image_tag" != gamesvr-tf2:* ]]; then
    printf "ERROR: Invalid unqualified image tag for gamesvr-tf2: '%s'.\n" "$image_tag" >&2
    exit 2
fi

case "$image_tag" in
    gamesvr-tf2:base-full|gamesvr-tf2:base-latest)
        docker run --rm "$image_tag" test -x /app/tf2/srcds_run_64
        ;;
    *)
        docker run --rm "$image_tag" ./ll-tests/gamesvr-tf2.sh
        ;;
esac