FROM lacledeslan/gamesvr-tf2:base-latest

ARG BUILD_DATE=unspecified \
    BUILD_NODE=unspecified \
    GIT_REVISION=unspecified

ENV LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8

HEALTHCHECK NONE

LABEL architecture="amd64" \
      com.lacledeslan.build-node=$BUILD_NODE \
      maintainer="Laclede's LAN <contact@lacledeslan.com>" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.description="Team Fortress 2 Dedicated Server" \
      org.opencontainers.image.revision=$GIT_REVISION \
      org.opencontainers.image.source="https://github.com/LacledesLAN/gamesvr-tf2" \
      org.opencontainers.image.vendor="Laclede's LAN"

COPY --chown=TF2:root dist/linux-x64 /app/tf2

RUN apt-get update && \
    apt-get install -y \
        libcurl3-gnutls \
        --no-install-recommends --no-install-suggests --no-upgrade && \
    apt-get clean && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* && \
    ln -sf /app/tf2/.steam/sdk64/steamclient.so /app/tf2/bin/steamclient.so && \
    chmod +x /app/tf2/ll-tests/*.sh && \
    rm -f /app/tf2/srcds_run;

USER TF2

ONBUILD USER root
