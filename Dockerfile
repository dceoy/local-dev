# syntax=docker/dockerfile:1
ARG UBUNTU_VERSION=24.04
FROM public.ecr.aws/docker/library/ubuntu:${UBUNTU_VERSION} AS builder

ARG PYTHON_VERSION=3.13

ENV DEBIAN_FRONTEND noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONIOENCODING=utf-8
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1
ENV POETRY_HOME=/opt/poetry
ENV POETRY_VIRTUALENVS_CREATE=false
ENV POETRY_NO_INTERACTION=true

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN \
      rm -f /etc/apt/apt.conf.d/docker-clean \
      && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' \
        > /etc/apt/apt.conf.d/keep-cache

# hadolint ignore=DL3008
RUN \
      --mount=type=cache,target=/var/cache/apt,sharing=locked \
      --mount=type=cache,target=/var/lib/apt,sharing=locked \
      apt-get -y update \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        ca-certificates curl gnupg lsb-release software-properties-common \
      && add-apt-repository ppa:deadsnakes/ppa

RUN \
      curl -fSL https://apt.releases.hashicorp.com/gpg \
        | gpg --dearmor \
        | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg \
      && gpg --no-default-keyring \
        --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
        --fingerprint \
      && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
        | tee /etc/apt/sources.list.d/hashicorp.list

# hadolint ignore=SC1091
RUN \
      install -m 0755 -d /etc/apt/keyrings \
      && curl -fSL -o /etc/apt/keyrings/docker.asc https://download.docker.com/linux/ubuntu/gpg \
      && chmod a+r /etc/apt/keyrings/docker.asc \
      && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
        | tee /etc/apt/sources.list.d/docker.list

# hadolint ignore=DL3008
RUN \
      --mount=type=cache,target=/var/cache/apt,sharing=locked \
      --mount=type=cache,target=/var/lib/apt,sharing=locked \
      apt-get -y update \
      && apt-get -y upgrade \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        curl docker-ce docker-ce-cli containerd.io docker-buildx-plugin \
        docker-compose-plugin gcc git libc6-dev libncurses-dev make \
        "python${PYTHON_VERSION}-dev" terraform unzip

RUN \
      --mount=type=cache,target=/root/.cache \
      ln -s "python${PYTHON_VERSION}" /usr/bin/python \
      && curl -fSL -o /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py \
      && /usr/bin/python /tmp/get-pip.py \
      && /usr/bin/python -m pip install -U --prefix=/usr/local pip setuptools wheel \
      && /usr/bin/python -m pip install -U --prefix=/usr/local \
        ansible-lint autopep8 csvkit docopt ipython pandas pipx poetry polars \
        psutil pydantic pynvim pyright ruff scikit-learn scipy seaborn \
        statsmodels tqdm typer uv vim-vint vulture yamllint \
      && rm -f /tmp/get-pip.py

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
      print-github-tags --release --latest gruntwork-io/terragrunt \
        | xargs -I{} -t curl -sSL -o /usr/local/bin/terragrunt \
          "https://github.com/gruntwork-io/terragrunt/releases/download/{}/terragrunt_linux_$(uname -m | sed 's/^x86_64$/amd64/')" \
      && chmod +x /usr/local/bin/terragrunt

RUN \
      --mount=type=cache,target=/root/.cache \
      curl -fSL -o /usr/local/bin/install_latest_vim.sh \
        https://raw.githubusercontent.com/dceoy/install-latest-vim/refs/heads/master/install_latest_vim.sh \
      && curl -fSL -o /usr/local/bin/update_vim_plugins.sh \
        https://raw.githubusercontent.com/dceoy/install-latest-vim/refs/heads/master/update_vim_plugins.sh \
      && chmod +x /usr/local/bin/install_latest_vim.sh /usr/local/bin/update_vim_plugins.sh \
      && /usr/local/bin/install_latest_vim.sh --lua --python3="/usr/bin/python${PYTHON_VERSION}" --vim-plug /usr/local

RUN \
      --mount=type=bind,source=.,target=/mnt/host \
      cp /mnt/host/entrypoint.sh /usr/local/bin/entrypoint.sh \
      && chmod +x /usr/local/bin/entrypoint.sh


FROM public.ecr.aws/docker/library/ubuntu:${UBUNTU_VERSION} AS cli

ARG PYTHON_VERSION=3.13
ARG USER_NAME=cli
ARG USER_UID=1001
ARG USER_GID=1001

COPY --from=builder /usr/local /usr/local
COPY --from=builder /etc/apt/apt.conf.d/keep-cache /etc/apt/apt.conf.d/keep-cache

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONIOENCODING=utf-8

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN \
      ln -s "python${PYTHON_VERSION}" /usr/bin/python \
      && rm -f /etc/apt/apt.conf.d/docker-clean

# hadolint ignore=DL3008
RUN \
      --mount=type=cache,target=/var/cache/apt,sharing=locked \
      --mount=type=cache,target=/var/lib/apt,sharing=locked \
      apt-get -y update \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        gnupg software-properties-common \
      && add-apt-repository ppa:deadsnakes/ppa

COPY --from=builder /etc/apt/sources.list.d/hashicorp.list /etc/apt/sources.list.d/hashicorp.list
COPY --from=builder /usr/share/keyrings/hashicorp-archive-keyring.gpg /usr/share/keyrings/hashicorp-archive-keyring.gpg

# hadolint ignore=DL3008
RUN \
      --mount=type=cache,target=/var/cache/apt,sharing=locked \
      --mount=type=cache,target=/var/lib/apt,sharing=locked \
      apt-get -y update \
      && apt-get -y upgrade \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        apt-transport-https apt-file apt-utils aptitude aria2 build-essential \
        ca-certificates cifs-utils colordiff corkscrew curl fd-find file git \
        golang htop locales nkf nmap npm p7zip-full pandoc pbzip2 pigz \
        "python${PYTHON_VERSION}-dev" r-base rake rename ruby shellcheck ssh \
        sudo systemd-timesyncd terraform time tmux traceroute tree unzip \
        wakeonlan wget whois zip zsh

RUN \
      apt-file update

RUN \
      locale-gen en_US.UTF-8 \
      && update-locale

RUN \
      groupadd --gid "${USER_GID}" "${USER_NAME}" \
      && useradd --uid "${USER_UID}" --gid "${USER_GID}" --shell /usr/bin/zsh --create-home "${USER_NAME}" \
      && echo "${USER_NAME} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USER_NAME}" \
      && chmod 0440 "/etc/sudoers.d/${USER_NAME}"

USER ${USER_NAME}
WORKDIR /home/${USER_NAME}

RUN \
      curl -fSL -o /tmp/install-ohmyzsh.sh \
        https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
      && chmod +x /tmp/install-ohmyzsh.sh \
      && /tmp/install-ohmyzsh.sh --unattended \
      && rm -f /tmp/install-ohmyzsh.sh

RUN \
      curl -fSL -o "${HOME}/.oh-my-zsh/custom/themes/dceoy.zsh-theme" \
        https://raw.githubusercontent.com/dceoy/ansible-dev-server/refs/heads/master/roles/cli/files/dceoy.zsh-theme \
      && sed -ie 's/^ZSH_THEME=.*/ZSH_THEME="dceoy"/' "${HOME}/.zshrc"


RUN \
      curl -fSL -o "${HOME}/.vimrc" \
        https://raw.githubusercontent.com/dceoy/ansible-dev-server/refs/heads/master/roles/vim/files/vimrc \
      && /usr/local/bin/update_vim_plugins.sh

RUN \
      git config --global color.ui auto \
      && git config --global core.editor vim \
      && git config --global core.excludesfile "${HOME}/.gitignore" \
      && git config --global core.precomposeunicode false \
      && git config --global core.quotepath false \
      && git config --global gui.encoding utf-8 \
      && git config --global pull.rebase true \
      && git config --global push.default matching \
      && echo '.DS_Store' > "${HOME}/.gitignore"

HEALTHCHECK NONE

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/zsh", "-l"]
