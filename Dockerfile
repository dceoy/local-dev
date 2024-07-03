FROM public.ecr.aws/docker/library/ubuntu:24.04

ARG USER=dev
ARG UID=1001
ARG GID=1001

ENV DEBIAN_FRONTEND noninteractive

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN set -e \
      && apt-get -y update \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        sudo zsh

RUN set -e \
      && groupadd -g "${GID}" "${USER}" \
      && useradd -u "${UID}" -g "${GID}" -s /usr/bin/zsh -m "${USER}" \
      && echo "${USER} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USER}" \
      && chmod 0440 "/etc/sudoers.d/${USER}"

RUN set -e \
      && apt-get -y upgrade \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        ansible apt-transport-https apt-file apt-utils aptitude aria2 \
        build-essential ca-certificates cifs-utils colordiff corkscrew curl \
        file g++ git gnupg golang htop libncurses5-dev locales lua5.4 luajit \
        nkf nmap npm p7zip-full pandoc pbzip2 pigz pkg-config procps \
        python3-dev r-base rake rename ruby shellcheck \
        software-properties-common sqlite3 ssh sshfs systemd-timesyncd \
        texlive-fonts-recommended texlive-plain-generic texlive-xetex time \
        tmux traceroute tree unzip wakeonlan wget whois zip \
      && apt-get -y autoremove \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*

RUN set -e \
      && curl -sSL -o /tmp/install_homebrew.sh https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh \
      && /bin/bash /tmp/install_homebrew.sh \
      && brew update \
      && brew upgrade \
      && brew install terragrunt tfenv tflint tfsec \
      && brew cleanup \
      && tfenv install latest

RUN set -e \
      && curl -sSL -o /tmp/awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip \
      && unzip /tmp/awscliv2.zip -d /tmp \
      && /tmp/aws/install \
      && rm -rf /tmp/awscliv2.zip /tmp/aws

RUN set -e \
      && apt-file update

RUN set -e \
      && locale-gen en_US.UTF-8 \
      && update-locale

RUN set -e \
      && ln -s python3 /usr/bin/python

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN set -e \
      && curl -sSL -o /usr/local/bin/git-rewind-days https://raw.githubusercontent.com/dceoy/git-rewind-days/master/git-rewind-days \
      && curl -sSL -o /usr/local/bin/git-rewind-hours https://raw.githubusercontent.com/dceoy/git-rewind-days/master/git-rewind-hours \
      && curl -sSL -o /usr/local/bin/print-github-tags https://raw.githubusercontent.com/dceoy/print-github-tags/master/print-github-tags \
      && curl -sSL -o /tmp/install_latest_vim.sh https://raw.githubusercontent.com/dceoy/install-latest-vim/master/install_latest_vim.sh \
      && chmod +x \
        /usr/local/bin/git-rewind-days /usr/local/bin/git-rewind-hours \
        /usr/local/bin/print-github-tags /usr/local/bin/entrypoint.sh

RUN set -e \
      && curl -sSL -o /tmp/install-docker.sh https://get.docker.com \
      && bash /tmp/install-docker.sh \
      && usermod -aG docker "${USER}" \
      && rm -f /tmp/install-docker.sh

HEALTHCHECK NONE

USER "${USER}"

RUN set -e \
      && curl -sSL -o /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py \
      && /usr/bin/python3 /tmp/get-pip.py \
      && /usr/bin/python3 -m pip install -U --no-cache-dir pip \
      && /usr/bin/python3 -m pip install -U --no-cache-dir --user \
        ansible-lint autopep8 bandit black csvkit docker-compose docopt \
        flake8 flake8-bugbear flake8-isort ipython pandas mypy pep8-naming \
        poetry polars psutil pydantic pynvim pyright ruff scikit-learn scipy \
        seaborn statsmodels tqdm vim-vint vulture yamllint

RUN set -e \
      && curl -sSL -o "${HOME}/.vimrc" https://raw.githubusercontent.com/dceoy/ansible-dev/master/roles/vim/files/vimrc \
      && curl -sSL -o "${HOME}/.zshrc" https://raw.githubusercontent.com/dceoy/ansible-dev/master/roles/cli/files/zshrc \
      && bash /tmp/install_latest_vim.sh --lua --dein /usr/local \
      && rm -f /tmp/install_latest_vim.sh

RUN set -e \
      && echo '.DS_Store' >> "${HOME}/.gitignore" \
      && git config --global core.editor vim \
      && git config --global core.excludesfile "${HOME}/.gitignore" \
      && git config --global color.ui auto \
      && git config --global pull.rebase true \
      && git config --global push.default matching

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/zsh", "-l"]
