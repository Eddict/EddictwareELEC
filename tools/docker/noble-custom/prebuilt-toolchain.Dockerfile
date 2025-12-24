ARG BASE_IMAGE=ghcr.io/eddict/eddictwareelec-noble:latest
FROM ${BASE_IMAGE} AS builder

# Copy repo into the image so the project's build scripts can run
COPY . /src
RUN sudo chown -R docker:docker /src
WORKDIR /src

ENV DEBIAN_FRONTEND=noninteractive

# Build host-toolchain packages into a temporary build dir inside the image.
# Adjust the package list if you need more/less prebuilt packages.
RUN set -eux; \
    mkdir -p /tmp/prebuild; \
    export BUILD_DIR=/tmp/prebuild; \
    # run a minimal host-toolchain bootstrap; change package list as appropriate
    # normal
    # /src/scripts/build pkg-config:host || true; \
    # quiet, only errors shown in build log)
    # /src/scripts/build pkg-config:host > /dev/null 2>&1 || true; \
    # keep logs for debugging
    # /src/scripts/build pkg-config:host > /tmp/prebuild/pkg-config-host.log 2>&1 || true; \
    /src/scripts/build pkg-config:host > /dev/null 2>&1 || true; \
    /src/scripts/build gettext:host > /dev/null 2>&1 || true; \
    /src/scripts/build xxHash:host > /dev/null 2>&1 || true; \
    /src/scripts/build cmake:host > /dev/null 2>&1 || true; \
    /src/scripts/build toolchain:host > /dev/null 2>&1 || true; \
    /src/scripts/build linux:host > /dev/null 2>&1 || true; \
    /src/scripts/build rpi-eeprom:host > /dev/null 2>&1 || true; \
    /src/scripts/build mesa:host > /dev/null 2>&1 || true; \
    /src/scripts/build zstd:host > /dev/null 2>&1 || true; \
    # copy any produced toolchain trees into /opt/prebuilt-toolchain
    sudo mkdir -p /opt/prebuilt-toolchain; \
    for d in /tmp/prebuild/*; do \
      if [ -d "$d/toolchain" ]; then \
        name=$(basename "$d"); \
        sudo cp -a "$d/toolchain" "/opt/prebuilt-toolchain/${name}-toolchain" || true; \
      fi; \
    done

FROM ${BASE_IMAGE}
COPY --from=builder /opt/prebuilt-toolchain /opt/prebuilt-toolchain
LABEL org.opencontainers.image.title="EddictwareELEC prebuilt toolchain" \
      org.opencontainers.image.description="Prebuilt host-toolchain trees for EddictwareELEC builds (placed in /opt/prebuilt-toolchain)."

# Default entrypoint is inherited from base image; this image's job is to provide /opt/prebuilt-toolchain
