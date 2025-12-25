ARG BASE_IMAGE=ghcr.io/eddict/eddictwareelec-noble:latest
FROM ${BASE_IMAGE} AS builder

# Copy repo into the image so the project's build scripts can run
COPY . /src
RUN sudo chown -R docker:docker /src
WORKDIR /src

ENV DEBIAN_FRONTEND=noninteractive

# Add build arguments for EE variables
ARG DISTRO=noble
ARG PROJECT=RPi
ARG DEVICE=RPi4
ARG ARCH=aarch64

# Build host-toolchain packages into a temporary build dir inside the image.
# Adjust the package list if you need more/less prebuilt packages.
RUN set -eux; \
    echo "Building for Distro: $DISTRO, Project: $PROJECT, Device: $DEVICE, Arch: $ARCH"; \
    mkdir -p /tmp/prebuild; \
    export BUILD_DIR=/tmp/prebuild; \
    # Run host-toolchain builds in parallel
    ( \
        # run a minimal host-toolchain bootstrap; change package list as appropriate
        # normal
        # /src/scripts/build pkg-config:host || true; \
        # quiet, only errors shown in build log)
        # /src/scripts/build pkg-config:host > /dev/null 2>&1 || true; \
        # keep logs for debugging
        # /src/scripts/build pkg-config:host > /tmp/prebuild/pkg-config-host.log 2>&1 || true; \
        /src/scripts/build pkg-config:host > /dev/null 2>&1 & \
        /src/scripts/build gettext:host > /dev/null 2>&1 & \
        /src/scripts/build xxHash:host > /dev/null 2>&1 & \
        /src/scripts/build cmake:host > /dev/null 2>&1 & \
        /src/scripts/build toolchain:host > /dev/null 2>&1 & \
        /src/scripts/build linux:host > /dev/null 2>&1 & \
        /src/scripts/build rpi-eeprom:host > /dev/null 2>&1 & \
        /src/scripts/build mesa:host > /dev/null 2>&1 & \
        /src/scripts/build zstd:host > /dev/null 2>&1 & \
        wait \
    ); \
    # Diagnostic: show contents of /tmp/prebuild and /tmp/prebuild/toolchain after build
    echo "--- DIAGNOSTIC: /tmp/prebuild ---"; \
    ls -l /tmp/prebuild || true; \
    echo "--- DIAGNOSTIC: /tmp/prebuild/toolchain ---"; \
    ls -l /tmp/prebuild/toolchain || true; \
    # Copy any produced toolchain trees into /opt/prebuilt-toolchain
    sudo mkdir -p /opt/prebuilt-toolchain; \
    # Copy all toolchain directories found under /tmp/prebuild (recursively)
    find /tmp/prebuild -type d -name 'toolchain' | while read tcdir; do \
      name=$(basename $(dirname "$tcdir")); \
      sudo cp -a "$tcdir" "/opt/prebuilt-toolchain/${name}-toolchain" || true; \
    done; \
    # Also copy /tmp/prebuild/toolchain directly if it exists (flat layout)
    if [ -d /tmp/prebuild/toolchain ]; then \
      sudo cp -a /tmp/prebuild/toolchain /opt/prebuilt-toolchain/ || true; \
    fi; \
    # Diagnostic: confirm /opt/prebuilt-toolchain presence and permissions
    echo "--- DIAGNOSTIC: /opt/prebuilt-toolchain ---"; \
    ls -l /opt/prebuilt-toolchain || true; \
    find /opt/prebuilt-toolchain -type f | xargs ls -l || true; \
    stat /opt/prebuilt-toolchain || true

FROM ${BASE_IMAGE}
COPY --from=builder /opt/prebuilt-toolchain /opt/prebuilt-toolchain
LABEL org.opencontainers.image.title="EddictwareELEC prebuilt toolchain" \
      org.opencontainers.image.description="Prebuilt host-toolchain trees for EddictwareELEC builds (placed in /opt/prebuilt-toolchain)."

# Default entrypoint is inherited from base image; this image's job is to provide /opt/prebuilt-toolchain
