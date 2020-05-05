FROM ubuntu:latest

ENV DEBIAN_FRONTEND noninteractive

ADD . /tmp/minimal-dev

RUN set -e \
      && apt-get -y update \
      && apt-get -y dist-upgrade \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        sudo \
      && apt-get -y autoremove \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*

RUN set -e \
      && groupadd wheel \
      && echo '%wheel  ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers \
      && echo 'Set disable_coredump false' >> /etc/sudo.conf \
      && useradd -m -d /home/dev -g wheel dev

USER dev

RUN set -e \
      && /tmp/minimal-dev/setup_minimal_dev.sh --debug

ENTRYPOINT ["/usr/bin/zsh", "-lc"]
