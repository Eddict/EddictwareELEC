FROM debian:sid

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get dist-upgrade -y -q \
 && apt-get install -y -q locales sudo

RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen \
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# RUN useradd docker -U -G sudo -m -s /bin/bash \
#  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
# ---- EF: Custom part ----
ARG USER_UID
ENV USER_UID=${USER_UID:-1234}
# make sure any user/group in image do not use the UUID/GUID of the host docker user/group
RUN <<EOF
  # https://www.kevinguay.com/posts/next-uid-gid/
  newid=$(cat /etc/group /etc/passwd | cut -d ":" -f 3 | grep "^1...$" | sort -n | tail -n 1 | awk '{ print $1+1 }')
  echo ${newid}
  # do we have a group with same GID
  if groupname=$(getent group ${USER_UID}); then
    echo ${groupname}
    groupmod --gid ${newid} ${groupname}
  fi
  # do we have a user with same UID
  if username=$(getent passwd ${USER_UID}); then
    echo ${username}
    usermod --uid ${newid} ${username}
  fi
  #groupadd --gid ${USER_UID} docker
  #useradd docker --uid ${USER_UID} --no-user-group --groups docker,sudo --create-home --shell /bin/bash
  useradd docker --uid ${USER_UID} --user-group --groups sudo --create-home --shell /bin/bash
  echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
EOF

RUN apt-get install -y -q \
    curl bash bc gcc sed patch patchutils tar bzip2 gzip xz-utils zstd perl gawk gperf zip \
      unzip diffutils lzop make file g++ xfonts-utils xsltproc default-jre-headless python3 \
      libc6-dev libncurses5-dev libjson-perl libxml-parser-perl libparse-yapp-perl rdfind \
      golang-1.25-go git openssh-client rsync \
    --no-install-recommends \
    && ln -s /usr/lib/go-1.25 /usr/lib/go \
    && ln -s /usr/lib/go-1.25/bin/go /usr/bin/go \
    && ln -s /usr/lib/go-1.25/bin/gofmt /usr/bin/gofmt

RUN if [ "$(uname -m)" = "aarch64" ]; then \
  apt-get install -y libc6-amd64-cross qemu-user-binfmt crossbuild-essential-amd64 --no-install-recommends; \
 fi

RUN apt-get install -y -q \
    build-essential binutils binutils-gold lld mold ca-certificates libtinyxml2-11 \
    --no-install-recommends

RUN rm -rf /var/lib/apt/lists/*

USER docker
