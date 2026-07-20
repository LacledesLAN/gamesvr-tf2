FROM lacledeslan/gamesvr-tf2:base-latest

ARG BUILD_NODE=unspecified
ARG GIT_REVISION=unspecified

ENV LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8

HEALTHCHECK NONE

LABEL architecture="i386" \
    com.lacledeslan.build-node=$BUILD_NODE \
    maintainer="Laclede's LAN <contact@lacledeslan.com>" \
    org.opencontainers.image.description="Team Fortress 2 Dedicated Server (32-bit)" \
    org.opencontainers.image.revision=$GIT_REVISION \
    org.opencontainers.image.source="https://github.com/LacledesLAN/gamesvr-tf2" \
    org.opencontainers.image.vendor="Laclede's LAN"

COPY --chown=TF2:root dist/linux-x86 /app/tf2

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y \
        lib32gcc-s1 libcurl4-gnutls-dev:i386 libsdl2-2.0-0:i386 libstdc++6 libstdc++6:i386 libtcmalloc-minimal4:i386 \
        --no-install-recommends --no-install-suggests --no-upgrade && \
    apt-get clean && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* && \
    mkdir -p /app/tf2/.steam/sdk32 && \
    ln -s /app/tf2/bin/steamclient.so /app/tf2/.steam/sdk32/steamclient.so && \
    chmod +x /app/tf2/ll-tests/*.sh && \
    rm -f  /app/tf2/srcds_run_64;

USER TF2

ONBUILD USER root
