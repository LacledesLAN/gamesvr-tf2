# escape=`

FROM lacledeslan/steamcmd:linux as tf2-builder

RUN echo $'\n\nDownloading LL custom content from public ftp server' &&`
    mkdir --parents /tmp/maps/ &&`
    cd /tmp/maps/ &&`
    wget -m `
        ftp://llgameserverbot:6gDyfNJhm4UsraE5@raw.content.lacledeslan.net/tf2/maps/ `
            -nH --no-verbose --cut-dirs 4 &&`
        rm -f .listing &&`
    echo "Decompressing downloaded content" &&`
        bzip2 --decompress /tmp/maps/*.*.bz2 &&`
        rm -f /tmp/maps/*.bz2 &&`
    echo "Moving uncompressed files to destination" &&`
        mkdir /output/tf/maps --parents &&`
        mv /tmp/maps/*.* /output/tf/maps;

#=======================================================================
FROM debian:stretch-slim

HEALTHCHECK NONE

ARG BUILDNODE="unspecified"
ARG SOURCE_COMMIT

LABEL maintainer="Laclede's LAN <contact@lacledeslan.com>" `
      com.lacledeslan.build-node=$BUILDNODE `
      org.label-schema.schema-version="1.0" `
      org.label-schema.url="https://github.com/LacledesLAN/README.1ST" `
      org.label-schema.vcs-ref=$SOURCE_COMMIT `
      org.label-schema.vendor="Laclede's LAN" `
      org.label-schema.description="Team Fortress 2 Server in Docker" `
      org.label-schema.vcs-url="https://github.com/LacledesLAN/gamesvr-tf2"

RUN dpkg --add-architecture i386 &&`
    apt-get update && apt-get install -y `
        ca-certificates lib32gcc1 lib32tinfo5 libcurl3-gnutls libstdc++6 libstdc++6:i386 libz1 &&`
    apt-get clean &&`
    rm -rf /var/lib/apt/lists/*;

## TF2 is so large we can't reliably use multi-stage builds in docker cloud

# Copy 'output files' in from builder
COPY --from=tf2-builder /output /app

# Copy cached build files (if any)
COPY ./build-cache /app

#Pull in SteamCMD
COPY --from=csgo-builder /app /app/steamcmd

# Install TF2 using SteamCMD
RUN echo $'\n\nDownloading Team Fortress 2 via SteamCMD' &&`
        /app/steamcmd/steamcmd.sh `
            +login anonymous `
            +force_install_dir /app `
            +app_update 232250 validate `
            +quit;

RUN echo $'\n\nLinking steamclient.so to prevent srcds_run errors' &&`
        mkdir --parents /app/.steam/sdk32 &&`
        ln -s /app/bin/steamclient.so /app/.steam/sdk32/steamclient.so

## Add in tests
COPY ./tests /app/ll-tests

RUN echo $'\n\nCreating user "TF2" (to group "root" until [github.com/moby/moby/pull/34263] makes it into CE stable)' &&`
        useradd --home /app --gid root --system `
            TF2 &&`
    echo 'Setting user directory permissions' &&`
        chown TF2:root /app &&`
        find /app -type d -exec chmod 775 {} + &&`
        chmod +x /app/ll-tests/*.sh

# Intentionally set after all build steps
USER TF2

WORKDIR /app

ONBUILD USER root
