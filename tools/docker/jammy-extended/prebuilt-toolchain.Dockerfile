ARG REPO_OWNER=eddict
ARG OS=jammy-extended
ARG BASE_IMAGE=ghcr.io/${REPO_OWNER}/eddictwareelec:${OS}
FROM ${BASE_IMAGE} AS builder

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
    chown -R docker:docker $SRC_DIR $BUILD_DIR $PREBUILD_TC_DIR

USER docker

# Cache mounts live outside the layer, so their contents survive even if the RUN exits non-zero
ARG DOCKER_UID=1000
ARG DOCKER_GID=1000
RUN --mount=type=cache,id=prebuild-logs,target=$BUILD_DIR,sharing=locked,uid=$DOCKER_UID,gid=$DOCKER_GID \
    echo "Building for Distro: $DISTRO, Project: $PROJECT, Device: $DEVICE, Arch: $ARCH"; \
    # sudo chmod u=rwx,g=rwxs,o=rx "$BUILD_DIR"; \
    export BUILD_DIR="$BUILD_DIR"; \
    # export PKG_MAKE_OPTS_HOST="-j$(nproc) -l$(nproc)"; \
    export PKG_MAKE_OPTS_HOST="--silent --jobs=$(nproc)"; \
    echo "PKG_MAKE_OPTS_HOST=$PKG_MAKE_OPTS_HOST"; \
    # export PKG_CONFIGURE_OPTS_HOST probably not work as package.mk overwrites it
    export PKG_CONFIGURE_OPTS_HOST="--disable-dependency-tracking"; \
    echo "PKG_CONFIGURE_OPTS_HOST=$PKG_CONFIGURE_OPTS_HOST"; \
    for pkg in \
        make:host \
        pkg-config:host gettext:host xxHash:host \
        cmake:host \
        zstd:host rpi-eeprom:host \
        toolchain:host \
        linux:host \
        mesa:host; \
    do \
        name="${pkg%%:*}"; \
        log="$BUILD_DIR/${pkg//:/-}.log"; \
        start=$(date +%s); \
        if [ "$name" = "gettext" ]; then \
            pkgmk=$(find /src/packages -type f -path "*/${name}/package.mk" | head -n1); \
            if [ -n "$pkgmk" ]; then \
                echo 'PKG_CONFIGURE_OPTS_HOST+=" --disable-dependency-tracking --disable-openmp --disable-libasprintf --disable-acl --without-git --without-cvs"' >> "$pkgmk"; \
            fi; \
        fi; \
        if ! /src/scripts/build "$pkg" >"$log" 2>&1; then \
            echo "$pkg failed after $(( $(date +%s) - start ))s"; \
            # ::group:: makes it foldable in GitHub Actions logs
            echo "::group::Build failed: $pkg (full log)"; \
            # tail -n 200 "$log"; \
            cat "$log"; \
            echo "::endgroup::"; \
            exit 1; \
        fi; \
        echo "$pkg took $(( $(date +%s) - start ))s"; \
    done; \
    # Diagnostic: show contents of $BUILD_DIR and $BUILD_DIR/toolchain after build
    echo "--- DIAGNOSTIC: $BUILD_DIR ---"; \
    ls -l "$BUILD_DIR" || true; \
    echo "--- DIAGNOSTIC: $BUILD_DIR/toolchain ---"; \
    ls -l "$BUILD_DIR/toolchain" || true; \
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

# --- tiny stage whose only job is exposing the log cache as real files ---
# use the same cache ID as the builder stage to persist logs
FROM busybox AS export-logs
ARG DOCKER_UID=1000
ARG DOCKER_GID=1000
RUN --mount=type=cache,id=prebuild-logs,target=/cache,sharing=locked,uid=$DOCKER_UID,gid=$DOCKER_GID \
    mkdir -p /logs && cp -a /cache/. /logs/

# --- final image ---
FROM ${BASE_IMAGE}
ARG OS=jammy-extended
ARG BUILD_DIR=/opt/tmp/prebuild
ARG PREBUILD_TC_DIR=/opt/prebuilt-toolchain

COPY --from=builder ${PREBUILD_TC_DIR} ${PREBUILD_TC_DIR}
LABEL org.opencontainers.image.title="EddictwareELEC ${OS} prebuilt toolchain" \
      org.opencontainers.image.description="Prebuilt host-toolchain trees for EddictwareELEC ${OS} builds (placed in /opt/prebuilt-toolchain)."

# Default entrypoint is inherited from base image; this image's job is to provide /opt/prebuilt-toolchain
