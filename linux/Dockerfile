# escape=`
FROM lacledeslan/steamcmd:linux as tf2-builder

ARG ftpServer=content.lacledeslan.net

RUN echo $'\n\nDownloading LL custom content from public ftp server' &&`
    mkdir --parents /tmp/maps/ &&`
    cd /tmp/maps/ &&`
    wget -m `
        ftp://llgameserverbot:6gDyfNJhm4UsraE5@$ftpServer/tf2/maps/ `
            -nH --no-verbose --cut-dirs 4 &&`
        rm -f .listing &&`
    echo "Decompressing downloaded content" &&`
        bzip2 --decompress /tmp/maps/*.*.bz2 &&`
        rm -f /tmp/maps/*.bz2 &&`
    echo "Moving uncompressed files to destination" &&`
        mkdir /output/tf/maps --parents &&`
        mv /tmp/maps/*.* /output/tf/maps;

#=======================================================================
FROM debian:stable-slim

ARG BUILDNODE=unspecified
ARG SOURCE_COMMIT=unspecified

HEALTHCHECK NONE

RUN dpkg --add-architecture i386 &&`
    apt-get update && apt-get install -y `
        ca-certificates lib32gcc1 lib32tinfo5 libcurl4-gnutls-dev:i386 libstdc++6 libstdc++6:i386 libtcmalloc-minimal4:i386 locales locales-all tmux &&`
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

# Set up Enviornment
RUN useradd --home /app --gid root --system TF2 &&`
    mkdir -p /app/ll-tests &&`
    chown TF2:root -R /app;

## TF2 Dedicated Server is so large we can't reliably use multi-stage builds in docker cloud

# Copy cached build files (if any)
COPY ./build-cache /app

# Copy 'output files' in from builder
COPY --from=tf2-builder /output /app
# Ownership shim until [github.com/moby/moby/pull/34263] makes it into Docker Cloud
RUN chown -R TF2:root /app;

#Pull in SteamCMD
COPY --from=tf2-builder /app /app/steamcmd

## Add in tests
COPY ./ll-tests /app/ll-tests

RUN chmod +rx /app/ll-tests/*.sh &&`
    chmod +rwx /app/ll-tests &&`
    chown TF2:root -R /app/ll-tests;

USER TF2

# Install TF2 Dedicated Server using SteamCMD
RUN echo $'\n\nDownloading TF2 Dedicated Server via SteamCMD' &&`
        /app/steamcmd/steamcmd.sh `
            +login anonymous `
            +force_install_dir /app `
            +app_update 232250 validate `
            +quit;

RUN echo $'\n\nLinking steamclient.so to prevent srcds_run errors' &&`
        mkdir -p /app/.steam/sdk32 &&`
        ln -s /app/bin/steamclient.so /app/.steam/sdk32/steamclient.so;

WORKDIR /app

ONBUILD USER root
