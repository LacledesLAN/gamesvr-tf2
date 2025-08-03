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

#=======================================================================
FROM debian:bookworm-slim

ARG BUILDNODE=unspecified
ARG SOURCE_COMMIT=unspecified

HEALTHCHECK NONE

RUN dpkg --add-architecture i386 &&`
    apt-get update && apt-get install -y `
        ca-certificates lib32gcc-s1 libcurl4-gnutls-dev:i386 libncurses5:i386 libsdl2-2.0-0:i386 libstdc++6 libstdc++6:i386 libtcmalloc-minimal4:i386 locales locales-all tmux &&`
    apt-get clean &&`
    echo "LC_ALL=en_US.UTF-8" >> /etc/environment &&`
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*;

ENV LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8

LABEL maintainer="Laclede's LAN <contact @lacledeslan.com>" `
      com.lacledeslan.build-node=$BUILDNODE `
      org.label-schema.schema-version="1.0" `
      org.label-schema.url="https://github.com/LacledesLAN/README.1ST" `
      org.label-schema.vcs-ref=$SOURCE_COMMIT `
      org.label-schema.vendor="Laclede's LAN" `
      org.label-schema.description="Team Fortress 2 Dedicated Server" `
      org.label-schema.vcs-url="https://github.com/LacledesLAN/gamesvr-tf2"

# Set up Environment
RUN useradd --home /app --gid root --system TF2 &&`
    mkdir -p /app/ll-tests &&`
    chown TF2:root -R /app;

COPY --chown=TF2:root dist/linux/ll-tests /app/ll-tests

RUN chmod +x /app/ll-tests/*.sh;

COPY --chown=TF2:root --from=tf2-builder /output /app

USER TF2

RUN echo $'\n\nLinking steamclient.so to prevent srcds_run errors' &&`
        mkdir -p /app/.steam/sdk32 &&`
        ln -s /app/bin/steamclient.so /app/.steam/sdk32/steamclient.so;

WORKDIR /app

CMD ["/bin/bash"]

ONBUILD USER root
