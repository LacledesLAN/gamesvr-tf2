# escape=`
FROM local/tf2-base:latest

ARG BUILDNODE=unspecified
ARG SOURCE_COMMIT=unspecified

HEALTHCHECK NONE

RUN apt-get update &&`
    apt-get install -y `
        lib32gcc-s1 libcurl4-gnutls-dev:i386 libncurses5:i386 libsdl2-2.0-0:i386 libstdc++6 libstdc++6:i386 libtcmalloc-minimal4:i386 `
        --no-install-recommends --no-install-suggests --no-upgrade &&`
    apt-get clean &&`
    echo "LC_ALL=en_US.UTF-8" >> /etc/environment &&`
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* &&`
    ln -sf /app/.steam/sdk64/steamclient.so /app/bin/steamclient.so;

ENV LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8

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

RUN chmod +x /app/ll-tests/*.sh;

USER TF2

ONBUILD USER root
