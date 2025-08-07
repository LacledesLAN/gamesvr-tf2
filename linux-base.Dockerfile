# escape=`
FROM lacledeslan/steamcmd:linux AS tf2-builder

ARG SKIP_STEAMCMD=false

# Copy in local cache files (if any)
COPY --chown=SteamCMD:root ./cache/linux/tf2/ /output

# Download TF2 via SteamCMD
RUN if [ "$SKIP_STEAMCMD" = true ] ; then `
        echo "\n\nSkipping SteamCMD install -- using only contents from steamcmd-cache\n\n"; `
    else `
        echo "\n\nDownloading TF2 via SteamCMD"; `
        mkdir --parents /output; `
        /app/steamcmd.sh +force_install_dir /output +login anonymous +app_update 232250 validate +quit;`
    fi;

# Grab x64 version of steamclient.so
RUN mkdir --parents /output/.steam/sdk64/ /app/ll-tests &&`
    cp /app/linux64/steamclient.so /output/.steam/sdk64/steamclient.so;

FROM debian:bookworm-slim

RUN apt-get update &&`
    apt-get install --no-install-recommends --no-install-suggests -y `
        ca-certificates locales locales-all tmux &&`
    apt-get clean &&`
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* &&`
    echo "LC_ALL=en_US.UTF-8" >> /etc/environment &&`
    useradd --home /app --gid root --system TF2 &&`
    mkdir --parents /app &&`
    chown TF2:root -R /app;

COPY --chown=TF2:root --from=tf2-builder /output /app

USER TF2

WORKDIR /app

CMD ["/bin/bash"]

ONBUILD USER root
