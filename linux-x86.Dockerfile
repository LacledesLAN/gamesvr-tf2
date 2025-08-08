# escape=`
FROM lacledeslan/gamesvr-tf2:base-latest

ARG BUILDNODE=unspecified
ARG SOURCE_COMMIT=unspecified

ENV LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8

HEALTHCHECK NONE

LABEL maintainer="Laclede's LAN <contact @lacledeslan.com>" `
      com.lacledeslan.build-node=$BUILDNODE `
      org.label-schema.schema-version="1.0" `
      org.label-schema.url="https://github.com/LacledesLAN/README.1ST" `
      org.label-schema.vcs-ref=$SOURCE_COMMIT `
      org.label-schema.vendor="Laclede's LAN" `
      org.label-schema.description="Team Fortress 2 Dedicated Server" `
      org.label-schema.vcs-url="https://github.com/LacledesLAN/gamesvr-tf2" `
      architecture="i386"

COPY --chown=TF2:root dist/linux-x86 /app

RUN dpkg --add-architecture i386 &&`
    apt-get update &&`
    apt-get install -y `
        lib32gcc-s1 libcurl4-gnutls-dev:i386 libncurses5:i386 libsdl2-2.0-0:i386 libstdc++6 libstdc++6:i386 libtcmalloc-minimal4:i386 `
        --no-install-recommends --no-install-suggests --no-upgrade &&`
    apt-get clean &&`
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* &&`
    mkdir -p /app/.steam/sdk32 &&`
    ln -s /app/bin/steamclient.so /app/.steam/sdk32/steamclient.so &&`
    chmod +x /app/ll-tests/*.sh &&`
    rm -f  /app/srcds_run_64;

USER TF2

ONBUILD USER root
