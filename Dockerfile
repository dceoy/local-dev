# syntax=docker/dockerfile:1
ARG UBUNTU_VERSION=24.04
FROM public.ecr.aws/docker/library/ubuntu:${UBUNTU_VERSION} AS base

ARG USER=dev
ARG UID=1001
ARG GID=1001

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONIOENCODING=UTF-8
ENV PIP_NO_CACHE_DIR=off
ENV PIP_DISABLE_PIP_VERSION_CHECK=on
ENV PATH="/opt/tfenv/bin:${PATH}"

RUN \
      rm -f /etc/apt/apt.conf.d/docker-clean \
      && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' \
        > /etc/apt/apt.conf.d/keep-cache

RUN \
      --mount=type=cache,target=/var/cache/apt,sharing=locked \
      --mount=type=cache,target=/var/lib/apt,sharing=locked \
      apt-get -y update \
      && apt-get -y upgrade \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        sudo zsh

RUN \
      groupadd -g "${GID}" "${USER}" \
      && useradd -u "${UID}" -g "${GID}" -s /usr/bin/zsh -m "${USER}" \
      && echo "${USER} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USER}" \
      && chmod 0440 "/etc/sudoers.d/${USER}"

RUN \
      --mount=type=cache,target=/var/cache/apt,sharing=locked \
      --mount=type=cache,target=/var/lib/apt,sharing=locked \
      apt-get -y update \
      && apt-get -y upgrade \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        ansible apt-transport-https apt-file apt-utils aptitude aria2 \
        build-essential ca-certificates cifs-utils colordiff corkscrew curl \
        file g++ git gnupg golang htop libncurses5-dev locales lua5.4 luajit \
        nkf nmap npm p7zip-full pandoc pbzip2 pigz pkg-config procps \
        python3-dev python3-pip python3-venv r-base rake rename ruby \
        shellcheck software-properties-common sqlite3 ssh systemd-timesyncd \
        texlive-fonts-recommended texlive-plain-generic texlive-xetex time \
        tmux traceroute tree unzip vim-gtk3 wakeonlan wget whois zip

RUN \
      --mount=type=cache,target=/root/.cache \
      ln -s python3 /usr/bin/python \
      && /usr/bin/python3 -m venv /opt/venv \
      && /opt/venv/bin/pip install -U pip setuptools wheel \
      && /opt/venv/bin/pip install -U \
        ansible-lint autopep8 bandit black csvkit docopt flake8 \
        flake8-bugbear flake8-isort ipython pandas mypy pep8-naming poetry \
        polars psutil pydantic pynvim pyright ruff scikit-learn scipy seaborn \
        statsmodels tqdm vim-vint vulture yamllint

RUN \
      --mount=type=cache,target=/root/.cache \
      curl -sSL -o /tmp/awscliv2.zip \
        "https://awscli.amazonaws.com/awscli-exe-linux-$([ "$(uname -m)" = 'x86_64' ] && echo 'x86_64' || echo 'aarch64').zip" \
      && unzip /tmp/awscliv2.zip -d /tmp \
      && /tmp/aws/install \
      && rm -rf /tmp/awscliv2.zip /tmp/aws

RUN \
      curl -sSL -o /usr/local/bin/git-rewind-days \
        https://raw.githubusercontent.com/dceoy/git-rewind-days/master/git-rewind-days \
      && curl -sSL -o /usr/local/bin/git-rewind-hours \
        https://raw.githubusercontent.com/dceoy/git-rewind-days/master/git-rewind-hours \
      && curl -sSL -o /usr/local/bin/print-github-tags \
        https://raw.githubusercontent.com/dceoy/print-github-tags/master/print-github-tags \
      && chmod +x \
        /usr/local/bin/git-rewind-days /usr/local/bin/git-rewind-hours \
        /usr/local/bin/print-github-tags

RUN \
      --mount=type=cache,target=/root/.cache \
      print-github-tags --debug --release --latest --tar tfutils/tfenv \
        | xargs -t curl -sSL -o /tmp/tfenv.tar.gz \
      && tar xvf /tmp/tfenv.tar.gz -C /opt/ \
      && mv /opt/tfenv-* /opt/tfenv \
      && /opt/tfenv/bin/tfenv install latest \
      && /opt/tfenv/bin/tfenv use latest

RUN \
      print-github-tags --release --latest gruntwork-io/terragrunt \
        | xargs -I{} -t curl -sSL -o /usr/local/bin/terragrunt \
          "https://github.com/gruntwork-io/terragrunt/releases/download/{}/terragrunt_linux_$(uname -m | sed 's/^x86_64$/amd64/')" \
      && chmod +x /usr/local/bin/terragrunt

RUN \
      --mount=type=cache,target=/root/.cache \
      curl -sSL -o /tmp/install-docker.sh https://get.docker.com \
      && bash /tmp/install-docker.sh \
      && usermod -aG docker "${USER}" \
      && rm -f /tmp/install-docker.sh

RUN \
      apt-file update

RUN \
      locale-gen en_US.UTF-8 \
      && update-locale

RUN \
      mkdir -p /opt/dotfiles \
      && echo '.DS_Store' > /opt/dotfiles/gitignore \
      && curl -sSL -o /opt/dotfiles/vimrc \
        https://raw.githubusercontent.com/dceoy/ansible-dev/master/roles/vim/files/vimrc \
      && curl -sSL -o /opt/dotfiles/zshrc \
        https://raw.githubusercontent.com/dceoy/ansible-dev/master/roles/cli/files/zshrc

RUN \
      --mount=type=cache,target=/root/.cache \
      mkdir -p /opt/vim \
      && curl -sSL -o /opt/vim/dein-installer.sh \
        https://raw.githubusercontent.com/Shougo/dein-installer.vim/master/installer.sh \
      && chmod +x /opt/vim/dein-installer.sh \
      && { \
        echo '#!/usr/bin/env bash'; \
        echo 'set -euox pipefail'; \
        echo "vim -N -u ~/.vimrc -U NONE -i NONE -V1 -e -s -c 'try | call dein#update() | finally | qall! | endtry'"; \
      } > /usr/local/bin/vim-plugin-update \
      && chmod +x /usr/local/bin/vim-plugin-update

RUN \
      --mount=type=bind,source=.,target=/mnt/host \
      cp /mnt/host/entrypoint.sh /usr/local/bin/entrypoint.sh \
      && chmod +x /usr/local/bin/entrypoint.sh

HEALTHCHECK NONE

FROM base AS cli

USER "${USER}"
WORKDIR "/home/${USER}"

RUN \
      ln -s /opt/dotfiles/gitignore "${HOME}/.gitignore" \
      && ln -s /opt/dotfiles/vimrc "${HOME}/.vimrc" \
      && ln -s /opt/dotfiles/zshrc "${HOME}/.zshrc" \
      && git config --global core.editor vim \
      && git config --global core.excludesfile "${HOME}/.gitignore" \
      && git config --global color.ui auto \
      && git config --global pull.rebase true \
      && git config --global push.default matching

RUN \
      /opt/vim/dein-installer.sh --use-vim-config \
      && /usr/local/bin/vim-plugin-update

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/zsh", "-l"]
