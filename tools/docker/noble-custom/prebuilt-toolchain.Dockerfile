ARG REPO_OWNER=eddict
ARG OS=noble
ARG BASE_IMAGE=ghcr.io/${REPO_OWNER}/eddictwareelec:${OS}
# ARG BASE_IMAGE=ghcr.io/eddict/eddictwareelec:noble-custom
FROM ${BASE_IMAGE} AS builder

# Copy repo into the image so the project's build scripts can run
COPY . /src
#RUN sudo chown -R docker:docker /src
WORKDIR /src

ENV DEBIAN_FRONTEND=noninteractive

# Add build arguments for EE variables
ARG DISTRO=EddictwareELEC
ARG PROJECT=RPi
ARG DEVICE=RPi4
ARG ARCH=aarch64
ARG DIAG_OUTPUT=false
ARG SRC_DIR=/src
ARG BUILD_DIR=/opt/tmp/prebuild
ARG PREBUILD_TC_DIR=/opt/prebuilt-toolchain
ENV SRC_DIR=${SRC_DIR}
ENV BUILD_DIR=${BUILD_DIR}
ENV PREBUILD_TC_DIR=${PREBUILD_TC_DIR}

# Set the default shell for all subsequent RUN commands to Bash
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

USER root
RUN mkdir -p $SRC_DIR $BUILD_DIR $PREBUILD_TC_DIR && \
    chown -R docker:docker $SRC_DIR $BUILD_DIR $PREBUILD_TC_DIR && \
    ls -al /src/tools/download-tool

USER docker

# RUN export DISTRO="$DISTRO" PROJECT="$PROJECT" DEVICE="$DEVICE" ARCH="$ARCH"; \
#     echo "Downloading sources for Distro: $DISTRO, Project: $PROJECT, Device: $DEVICE, Arch: $ARCH"; \
#     export BUILD_DIR="$BUILD_DIR"; \
#     # pre-fetch the source packages
#     # /src/tools/download-tool > "$BUILD_DIR/download-tool.log" 2>&1; \
#     /src/tools/download-tool 2>&1 | tee "$BUILD_DIR/download-tool.log"; \
#     echo "--- DIAGNOSTIC: $BUILD_DIR/download-tool.log ---"; \
#     cat "$BUILD_DIR/download-tool.log" || true;

RUN echo "Building for Distro: $DISTRO, Project: $PROJECT, Device: $DEVICE, Arch: $ARCH"; \
    # sudo chmod u=rwx,g=rwxs,o=rx "$BUILD_DIR"; \
    export BUILD_DIR="$BUILD_DIR"; \
    # Build make:host first, sequentially, since toolchain:host depends on it
    # and building it concurrently with other host packages races on shared
    # source/build state.
    # /src/scripts/build make:host > "$BUILD_DIR/make-host.log" 2>&1; \
    # /src/scripts/build make:host 2>&1 | tee "$BUILD_DIR/make-host.log"; \
    # /src/tools/download-tool 2>&1 | tee "$BUILD_DIR/download-tool.log"; \
    # export PKG_MAKE_OPTS_HOST="-j$(nproc) -l$(nproc)"; \
    export PKG_MAKE_OPTS_HOST="--silent --jobs=$(nproc)"; \
    echo "PKG_MAKE_OPTS_HOST=$PKG_MAKE_OPTS_HOST"; \
    # export NINJA_OPTS="--quiet"; \
    # echo "NINJA_OPTS=$NINJA_OPTS"; \
    # # Build make:host first, since toolchain:host depends on it
    # /src/scripts/build make:host       2>&1 | tee "$BUILD_DIR/make-host.log"; \
    # # small utility packages frequently needed by later builds
    # /src/scripts/build pkg-config:host 2>&1 | tee "$BUILD_DIR/pkg-config-host.log"; \
    # /src/scripts/build gettext:host    2>&1 | tee "$BUILD_DIR/gettext-host.log"; \
    # /src/scripts/build xxHash:host     2>&1 | tee "$BUILD_DIR/xxHash-host.log"; \
    # # many subsequent packages may use cmake
    # /src/scripts/build cmake:host      2>&1 | tee "$BUILD_DIR/cmake-host.log"; \
    # # relatively lightweight
    # /src/scripts/build zstd:host       2>&1 | tee "$BUILD_DIR/zstd-host.log"; \
    # /src/scripts/build rpi-eeprom:host 2>&1 | tee "$BUILD_DIR/rpi-eeprom-host.log"; \
    # # before major consumers
    # /src/scripts/build toolchain:host  2>&1 | tee "$BUILD_DIR/toolchain-host.log"; \
    # # heavy
    # /src/scripts/build linux:host      2>&1 | tee "$BUILD_DIR/linux-host.log"; \
    # # usually one of the heaviest builds and often benefits from a fully warmed toolchain and dependency stack
    # /src/scripts/build mesa:host       2>&1 | tee "$BUILD_DIR/mesa-host.log"; \

    for pkg in \
        make:host \
        pkg-config:host gettext:host xxHash:host \
        cmake:host \
        zstd:host rpi-eeprom:host \
        toolchain:host \
        linux:host \
        mesa:host; \
    do \
        log="$BUILD_DIR/${pkg//:/-}.log"; \
        if ! /src/scripts/build "$pkg" >"$log" 2>&1; then \
            echo "Build failed: $pkg"; \
            tail -n 50 "$log"; \
            exit 1; \
        fi; \
    done; \

    # Run remaining host-toolchain builds in parallel
    # ( \
    #     # run a minimal host-toolchain bootstrap; change package list as appropriate
    #     # normal
    #     # /src/scripts/build pkg-config:host || true; \
    #     # quiet, only errors shown in build log)
    #     # /src/scripts/build pkg-config:host > /dev/null 2>&1 || true; \
    #     # keep logs for debugging
    #     # /src/scripts/build pkg-config:host > /tmp/prebuild/pkg-config-host.log 2>&1 || true; \
    #     /src/scripts/build pkg-config:host 2>&1 | tee "$BUILD_DIR/pkg-config-host.log" & \
    #     /src/scripts/build gettext:host 2>&1 | tee "$BUILD_DIR/gettext-host.log" & \
    #     /src/scripts/build xxHash:host 2>&1 | tee "$BUILD_DIR/xxHash-host.log" & \
    #     /src/scripts/build cmake:host 2>&1 | tee "$BUILD_DIR/cmake-host.log" & \
    #     /src/scripts/build toolchain:host 2>&1 | tee "$BUILD_DIR/toolchain-host.log" & \
    #     /src/scripts/build linux:host 2>&1 | tee "$BUILD_DIR/linux-host.log" & \
    #     /src/scripts/build rpi-eeprom:host 2>&1 | tee "$BUILD_DIR/rpi-eeprom-host.log" & \
    #     /src/scripts/build mesa:host 2>&1 | tee "$BUILD_DIR/mesa-host.log" & \
    #     /src/scripts/build zstd:host 2>&1 | tee "$BUILD_DIR/zstd-host.log" & \
    #     wait \
    # ); \
    # Diagnostic: show contents of $BUILD_DIR and $BUILD_DIR/toolchain after build
    echo "--- DIAGNOSTIC: $BUILD_DIR ---"; \
    ls -l "$BUILD_DIR" || true; \
    echo "--- DIAGNOSTIC: $BUILD_DIR/toolchain ---"; \
    ls -l "$BUILD_DIR/toolchain" || true; \
    # echo "--- DIAGNOSTIC: $BUILD_DIR/make-host.log ---"; \
    # cat "$BUILD_DIR/make-host.log" || true; \
    # echo "--- DIAGNOSTIC: $BUILD_DIR/toolchain-host.log ---"; \
    # cat "$BUILD_DIR/toolchain-host.log" || true; \
    # Copy the first found toolchain dir as /opt/prebuilt-toolchain/toolchain (flat, predictable path)
    tcdir=$(find "$BUILD_DIR" -type d -name 'toolchain' | head -n1); \
    if [ -n "$tcdir" ]; then \
      cp -a "$tcdir" "$PREBUILD_TC_DIR/toolchain"; \
    fi; \
    # Diagnostic: confirm /opt/prebuilt-toolchain presence and permissions
    echo "--- DIAGNOSTIC: $PREBUILD_TC_DIR ---"; \
    ls -l "$PREBUILD_TC_DIR" || true; \
    find "$PREBUILD_TC_DIR" -type f | xargs ls -l || true; \
    stat "$PREBUILD_TC_DIR" || true

# # Build host-toolchain packages into a temporary build dir inside the image.
# # Adjust the package list if you need more/less prebuilt packages.
# RUN set -eu; \
#     if [ "$DIAG_OUTPUT" = "true" ]; then \
#         set -x; \
#     fi; \
#     echo "Building for Distro: $DISTRO, Project: $PROJECT, Device: $DEVICE, Arch: $ARCH"; \
#     mkdir -p /tmp/prebuild; \
#     export BUILD_DIR=/tmp/prebuild; \
#     # Keep the toolchain log only when diagnostics are on, otherwise discard it
#     if [ "$DIAG_OUTPUT" = "true" ]; then \
#         toolchain_log=/tmp/prebuild/toolchain-host.log; \
#     else \
#         toolchain_log=/dev/null; \
#     fi; \
#     # Run host-toolchain builds in parallel
#     ( \
#         # run a minimal host-toolchain bootstrap; change package list as appropriate
#         # normal
#         # /src/scripts/build pkg-config:host || true; \
#         # quiet, only errors shown in build log)
#         # /src/scripts/build pkg-config:host > /dev/null 2>&1 || true; \
#         # keep logs for debugging
#         # /src/scripts/build pkg-config:host > /tmp/prebuild/pkg-config-host.log 2>&1 || true; \
#         /src/scripts/build pkg-config:host > /dev/null 2>&1 & \
#         /src/scripts/build gettext:host > /dev/null 2>&1 & \
#         /src/scripts/build xxHash:host > /dev/null 2>&1 & \
#         /src/scripts/build cmake:host > /dev/null 2>&1 & \
#         /src/scripts/build toolchain:host > "$toolchain_log" 2>&1 & \
#         /src/scripts/build linux:host > /dev/null 2>&1 & \
#         /src/scripts/build rpi-eeprom:host > /dev/null 2>&1 & \
#         /src/scripts/build mesa:host > /dev/null 2>&1 & \
#         /src/scripts/build zstd:host > /dev/null 2>&1 & \
#         wait \
#     ); \
#     if [ "$DIAG_OUTPUT" = "true" ]; then \
#         # Diagnostic: show contents of /tmp/prebuild and /tmp/prebuild/toolchain after build
#         echo "--- DIAGNOSTIC: /tmp/prebuild ---"; \
#         ls -l /tmp/prebuild || true; \
#         echo "--- DIAGNOSTIC: /tmp/prebuild/toolchain ---"; \
#         ls -l /tmp/prebuild/toolchain || true; \
#         echo "--- DIAGNOSTIC: /tmp/prebuild/toolchain-host.log ---"; \
#         cat /tmp/prebuild/toolchain-host.log || true; \
#         # Copy the first found toolchain dir as /opt/prebuilt-toolchain/toolchain (flat, predictable path)
#         sudo mkdir -p /opt/prebuilt-toolchain; \
#         tcdir=$(find /tmp/prebuild -type d -name 'toolchain' | head -n1); \
#         if [ -n "$tcdir" ]; then \
#         sudo cp -a "$tcdir" /opt/prebuilt-toolchain/toolchain; \
#         fi; \
#         # Diagnostic: confirm /opt/prebuilt-toolchain presence and permissions
#         echo "--- DIAGNOSTIC: /opt/prebuilt-toolchain ---"; \
#         ls -l /opt/prebuilt-toolchain || true; \
#         find /opt/prebuilt-toolchain -type f | xargs ls -l || true; \
#         stat /opt/prebuilt-toolchain || true; \
#     fi;

FROM ${BASE_IMAGE}
ARG BUILD_DIR=/opt/tmp/prebuild
ARG PREBUILD_TC_DIR=/opt/prebuilt-toolchain
COPY --from=builder $PREBUILD_TC_DIR $PREBUILD_TC_DIR
LABEL org.opencontainers.image.title="EddictwareELEC prebuilt toolchain" \
      org.opencontainers.image.description="Prebuilt host-toolchain trees for EddictwareELEC builds (placed in /opt/prebuilt-toolchain)."

# Default entrypoint is inherited from base image; this image's job is to provide /opt/prebuilt-toolchain
