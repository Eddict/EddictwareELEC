ARG BASE_IMAGE=ghcr.io/eddict/eddictwareelec-noble:latest
FROM ${BASE_IMAGE} AS builder

# Copy repo into the image so the project's build scripts can run
COPY . /src
RUN sudo chown -R docker:docker /src
WORKDIR /src

ENV DEBIAN_FRONTEND=noninteractive

# Add build arguments for EE variables
ARG DISTRO=EddictwareELEC
ARG PROJECT=RPi
ARG DEVICE=RPi4
ARG ARCH=aarch64

# Build host-toolchain packages into a temporary build dir inside the image.
# Adjust the package list if you need more/less prebuilt packages.
RUN set -eux; \
    echo "Building for Distro: $DISTRO, Project: $PROJECT, Device: $DEVICE, Arch: $ARCH"; \
    mkdir -p /tmp/prebuild; \
    export BUILD_DIR=/tmp/prebuild; \
      # Run host-toolchain builds in parallel, log errors separately
      ( \
        /src/scripts/build pkg-config:host > /tmp/prebuild/pkg-config-host.log 2> /tmp/prebuild/pkg-config-host.err & \
        /src/scripts/build gettext:host > /tmp/prebuild/gettext-host.log 2> /tmp/prebuild/gettext-host.err & \
        /src/scripts/build xxHash:host > /tmp/prebuild/xxHash-host.log 2> /tmp/prebuild/xxHash-host.err & \
        /src/scripts/build cmake:host > /tmp/prebuild/cmake-host.log 2> /tmp/prebuild/cmake-host.err & \
        /src/scripts/build toolchain:host > /tmp/prebuild/toolchain-host.log 2> /tmp/prebuild/toolchain-host.err & \
        /src/scripts/build linux:host > /tmp/prebuild/linux-host.log 2> /tmp/prebuild/linux-host.err & \
        /src/scripts/build rpi-eeprom:host > /tmp/prebuild/rpi-eeprom-host.log 2> /tmp/prebuild/rpi-eeprom-host.err & \
        /src/scripts/build mesa:host > /tmp/prebuild/mesa-host.log 2> /tmp/prebuild/mesa-host.err & \
        /src/scripts/build zstd:host > /tmp/prebuild/zstd-host.log 2> /tmp/prebuild/zstd-host.err & \
        wait \
      ); \
    # Show only errors from host builds
    echo "--- ERRORS FROM HOST BUILDS ---"; \
    for f in /tmp/prebuild/*.err; do \
    echo "== $f =="; \
    cat "$f"; \
    done; \
    # Show regular output from host builds
    echo "--- OUTPUT FROM HOST BUILDS ---"; \
    for f in /tmp/prebuild/*.log; do \
    echo "== $f =="; \
    cat "$f"; \
    done; \
    # Diagnostic: show contents of /tmp/prebuild and /tmp/prebuild/toolchain after build
    echo "--- DIAGNOSTIC: /tmp/prebuild ---"; \
    ls -l /tmp/prebuild || true; \
    echo "--- DIAGNOSTIC: /tmp/prebuild/toolchain ---"; \
    ls -l /tmp/prebuild/toolchain || true; \
    # Diagnostic: Show regular output from host build logs
    # for f in /tmp/prebuild/*.log; do \
    #   echo "--- DIAGNOSTIC: $f ---"; \
    #   cat "$f" || true; \
    # done; \
    # Diagnostic: Show only errors from host build logs
    for f in /tmp/prebuild/*.err; do \
      echo "--- DIAGNOSTIC: $f ---"; \
      cat "$f" || true; \
    done; \
    # Copy all host build output directories into /opt/prebuilt-toolchain
    sudo mkdir -p /opt/prebuilt-toolchain; \
    for d in pkg-config gettext xxHash cmake toolchain linux rpi-eeprom mesa zstd; do \
      srcdir="/tmp/prebuild/$d"; \
      if [ -d "$srcdir" ]; then \
        sudo cp -a "$srcdir" "/opt/prebuilt-toolchain/$d"; \
      fi; \
    done; \
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
