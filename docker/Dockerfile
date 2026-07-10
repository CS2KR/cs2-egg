# Dockerfile with SteamRT3
FROM        registry.gitlab.steamos.cloud/steamrt/sniper/platform:latest-container-runtime-depot
LABEL       author="CS2.KR" \
            maintainer="contact@cs2.kr" \
            org.opencontainers.image.description="CS2.KR CS2 egg image. Fork of K4ryuu/CS2-Egg (GPL-3.0) with a third-party plugin auto-updater." \
            org.opencontainers.image.source="https://github.com/CS2KR/cs2-egg" \
            org.opencontainers.image.licenses="GPL-3.0" \
            org.opencontainers.image.base.name="https://github.com/K4ryuu/CS2-Egg"

# Prep OS
RUN         mkdir -p /etc/sudoers.d && \
            echo "%sudo ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/flatdeb && \
            chmod 0440 /etc/sudoers.d/flatdeb

ENV         DEBIAN_FRONTEND=noninteractive
RUN         apt update && \
            apt install -y iproute2 jq unzip rsync curl && \
            apt-get clean

# Create directories and copy files
RUN         mkdir -p /scripts /utils
COPY        ./scripts /scripts/
COPY        ./utils /utils/
COPY        ./entrypoint.sh /entrypoint.sh

# Set permissions (read-only + executable)
RUN         chmod 555 /scripts/*.sh && \
            chmod 555 /scripts/updaters/*.sh && \
            chmod 555 /utils/*.sh && \
            chmod 555 /entrypoint.sh

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

CMD         [ "/bin/bash", "/entrypoint.sh" ]