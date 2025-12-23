ARG BASE_IMAGE=ghcr.io/eddict/eddictwareelec-noble:latest
FROM ${BASE_IMAGE} AS builder

# Copy repo into the image so the project's build scripts can run
COPY . /src
WORKDIR /src

ENV DEBIAN_FRONTEND=noninteractive

# Build host-toolchain packages into a temporary build dir inside the image.
# Adjust the package list if you need more/less prebuilt packages.
USER root
RUN set -eux; \
    mkdir -p /tmp/prebuild; \
    export BUILD_DIR=/tmp/prebuild; \
    # run a minimal host-toolchain bootstrap; change package list as appropriate
    /src/scripts/build pkg-config:host || true; \
    /src/scripts/build gettext:host || true; \
    /src/scripts/build xxHash:host || true; \
    /src/scripts/build cmake:host || true; \
    # copy any produced toolchain trees into /opt/prebuilt-toolchain
    mkdir -p /opt/prebuilt-toolchain; \
    for d in /tmp/prebuild/*; do \
      if [ -d "$d/toolchain" ]; then \
        name=$(basename "$d"); \
        cp -a "$d/toolchain" "/opt/prebuilt-toolchain/${name}-toolchain" || true; \
      fi; \
    done

FROM ${BASE_IMAGE}
COPY --from=builder /opt/prebuilt-toolchain /opt/prebuilt-toolchain
LABEL org.opencontainers.image.title="EddictwareELEC prebuilt toolchain" \
      org.opencontainers.image.description="Prebuilt host-toolchain trees for EddictwareELEC builds (placed in /opt/prebuilt-toolchain)."

USER docker

# Default entrypoint is inherited from base image; this image's job is to provide /opt/prebuilt-toolchain
