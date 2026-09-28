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
ARG LOG_DIR=/opt/tmp/logs
ENV SRC_DIR=${SRC_DIR}
ENV BUILD_DIR=${BUILD_DIR}
ENV PREBUILD_TC_DIR=${PREBUILD_TC_DIR}
ENV LOG_DIR=${LOG_DIR}

# Set the default shell for all subsequent RUN commands to Bash
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

USER root
RUN mkdir -p "$BUILD_DIR" "$PREBUILD_TC_DIR" "$LOG_DIR" \
 && chown docker:docker "$BUILD_DIR" "$PREBUILD_TC_DIR" "$LOG_DIR"

# Helper: build one or more packages, logging each to $LOG_DIR
COPY --chmod=755 <<'EOF' /usr/local/bin/build-pkg
#!/bin/bash
set -u
export PKG_MAKE_OPTS_HOST="--silent --jobs=$(nproc)"
for pkg in "$@"; do
    name="${pkg%%:*}"
    log="$LOG_DIR/${pkg//:/-}.log"
    start=$(date +%s)
    if [ "$name" = "gettext" ]; then
        pkgmk=$(find /src/packages -type f -path "*/${name}/package.mk" | head -n1)
        if [ -n "$pkgmk" ]; then
            echo 'PKG_CONFIGURE_OPTS_HOST+=" --disable-dependency-tracking --disable-openmp --disable-libasprintf --disable-acl --without-git --without-cvs"' >> "$pkgmk"
        fi
    fi
    if ! /src/scripts/build "$pkg" >"$log" 2>&1; then
        echo "Build $pkg failed after $(( $(date +%s) - start ))s"
        # ::group:: makes it foldable in GitHub Actions logs
        echo "::group::Build failed: $pkg (full log)"
        # tail -n 200 "$log"
        cat "$log"
        echo "::endgroup::"
        exit 1
    fi
    echo "Build $pkg took $(( $(date +%s) - start ))s"
done
EOF

# Copy only what the build needs; a broad COPY . /src invalidates everything below on any commit
COPY --chown=docker:docker scripts   ${SRC_DIR}/scripts
COPY --chown=docker:docker config    ${SRC_DIR}/config
COPY --chown=docker:docker distributions ${SRC_DIR}/distributions
COPY --chown=docker:docker projects  ${SRC_DIR}/projects
COPY --chown=docker:docker packages  ${SRC_DIR}/packages
WORKDIR ${SRC_DIR}

USER docker

# Cache mounts live outside the layer, so their contents survive even if the RUN exits non-zero
ARG DOCKER_UID=1000
ARG DOCKER_GID=1000
# One RUN per expensive package; cheap ones grouped. Order: least likely to change first.
RUN --mount=type=cache,id=prebuild-logs,target=${LOG_DIR},sharing=locked,uid=${DOCKER_UID},gid=${DOCKER_GID} \
    build-pkg make:host pkg-config:host

RUN --mount=type=cache,id=prebuild-logs,target=${LOG_DIR},sharing=locked,uid=${DOCKER_UID},gid=${DOCKER_GID} \
    build-pkg gettext:host xxHash:host

RUN --mount=type=cache,id=prebuild-logs,target=${LOG_DIR},sharing=locked,uid=${DOCKER_UID},gid=${DOCKER_GID} \
    build-pkg cmake:host

RUN --mount=type=cache,id=prebuild-logs,target=${LOG_DIR},sharing=locked,uid=${DOCKER_UID},gid=${DOCKER_GID} \
    build-pkg zstd:host rpi-eeprom:host

RUN --mount=type=cache,id=prebuild-logs,target=${LOG_DIR},sharing=locked,uid=${DOCKER_UID},gid=${DOCKER_GID} \
    build-pkg toolchain:host

RUN --mount=type=cache,id=prebuild-logs,target=${LOG_DIR},sharing=locked,uid=${DOCKER_UID},gid=${DOCKER_GID} \
    build-pkg linux:host

RUN --mount=type=cache,id=prebuild-logs,target=${LOG_DIR},sharing=locked,uid=${DOCKER_UID},gid=${DOCKER_GID} \
    build-pkg mesa:host

RUN tcdir=$(find "$BUILD_DIR" -type d -name toolchain | head -n1); \
    [ -n "$tcdir" ] && cp -a "$tcdir" "$PREBUILD_TC_DIR/toolchain"; \
    ls -l "$PREBUILD_TC_DIR"

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
