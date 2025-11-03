FROM debian:sid

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get dist-upgrade -y \
 && apt-get install -y locales sudo

RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen \
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN useradd docker -U -G sudo -m -s /bin/bash \
 && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN echo "deb http://deb.debian.org/debian sid main" > /etc/apt/sources.list.d/sid.list

RUN apt-get update

# dist-upgrade needed?
# RUN apt-get dist-upgrade -y

RUN apt-get install -y \
    curl bash bc gcc sed patch patchutils tar bzip2 gzip xz-utils zstd perl gawk gperf zip \
      unzip diffutils lzop make file g++ xfonts-utils xsltproc default-jre-headless python3 \
      libc6-dev libncurses5-dev libjson-perl libxml-parser-perl libparse-yapp-perl rdfind \
      golang-1.25-go/bookworm-backports git openssh-client rsync \
    --no-install-recommends \
    && ln -s /usr/lib/go-1.25 /usr/lib/go \
    && ln -s /usr/lib/go-1.25/bin/go /usr/bin/go \
    && ln -s /usr/lib/go-1.25/bin/gofmt /usr/bin/gofmt

RUN rm -rf /var/lib/apt/lists/*

USER docker
