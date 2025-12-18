FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get dist-upgrade -y \
 && apt-get install -y locales sudo

RUN locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN useradd docker -U -G sudo -m -s /bin/bash \
 && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN apt-get update \
 && apt-get install -y \
    curl bash bc gcc-14 cpp-14 sed patch patchutils tar bzip2 gzip xz-utils zstd perl gawk gperf zip \
    unzip diffutils lzop make file g++-14 xfonts-utils xsltproc default-jre-headless python3 \
    libc6-dev libncurses5-dev libjson-perl libxml-parser-perl libparse-yapp-perl rdfind \
    golang-1.23-go git openssh-client rsync upx-ucl \
    cmake automake autoconf libtool m4 pkg-config ninja-build \
    --no-install-recommends \
    && ln -s /usr/lib/go-1.23 /usr/lib/go \
    && ln -s /usr/lib/go-1.23/bin/go /usr/bin/go \
    && ln -s /usr/lib/go-1.23/bin/gofmt /usr/bin/gofmt

# build system tools required by package builds
# cmake automake autoconf libtool m4 pkg-config ninja-build

RUN if [ "$(uname -m)" = "aarch64" ]; then \
  apt-get install -y libc6-amd64-cross qemu-user-binfmt --no-install-recommends; \
 fi

RUN rm -rf /var/lib/apt/lists/*

# Configure compiler alternatives: register gcc and its slaves, then
# only install `cpp` if it's not already registered to avoid master/slave conflicts.
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-14 \
  --slave /usr/bin/gcov gcov /usr/bin/gcov-14 \
  --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-14 \
  --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-14 && \
  if update-alternatives --query cpp >/dev/null 2>&1; then \
    echo "cpp already registered, skipping cpp install"; \
  else \
    update-alternatives --install /usr/bin/cpp cpp /usr/bin/cpp-14 100; \
  fi && \
  update-alternatives --set gcc /usr/bin/gcc-14

USER docker
