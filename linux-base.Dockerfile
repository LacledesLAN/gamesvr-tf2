FROM lacledeslan/steamcmd:linux AS tf2-builder

ARG SKIP_STEAMCMD=false

# Copy in local cache files (if any)
COPY --chown=SteamCMD:root ./cache/linux/tf2/ /output

# Download TF2 via SteamCMD
RUN if [ "$SKIP_STEAMCMD" = true ] ; then \
        echo "\n\nSkipping SteamCMD install -- using only contents from steamcmd-cache\n\n"; \
    else \
        echo "\n\nDownloading TF2 via SteamCMD"; \
        mkdir --parents /output; \
        /app/steamcmd.sh +force_install_dir /output +login anonymous +app_update 232250 validate +quit; \
    fi;

# Grab x64 version of steamclient.so
RUN mkdir --parents /output/.steam/sdk64/ /app/tf2/ll-tests && \
    cp /app/linux64/steamclient.so /output/.steam/sdk64/steamclient.so;


#---------------------------------
FROM debian:trixie-slim

ARG BUILD_DATE=unspecified \
    BUILD_NODE=unspecified \
    GIT_REVISION=unspecified

ENV LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8

LABEL architecture="amd64" \
      com.lacledeslan.build-node=$BUILD_NODE \
      maintainer="Laclede's LAN <contact@lacledeslan.com>" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.description="TF2 Dedicated Server Stock Content" \
      org.opencontainers.image.revision=$GIT_REVISION \
      org.opencontainers.image.source="https://github.com/LacledesLAN/gamesvr-tf2" \
      org.opencontainers.image.vendor="Laclede's LAN"

RUN apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
        ca-certificates locales locales-all tmux && \
    apt-get clean && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* && \
    echo "LC_ALL=en_US.UTF-8" >> /etc/environment && \
    useradd --home /app/tf2 --gid root --system TF2 && \
    mkdir --parents /app/tf2 && \
    chown TF2:root -R /app/tf2;

COPY --chown=TF2:root --from=tf2-builder /output /app/tf2

USER TF2

WORKDIR /app/tf2

CMD ["/bin/bash"]

ONBUILD USER root
