FROM public.ecr.aws/docker/library/ubuntu:24.04

ENV DEBIAN_FRONTEND noninteractive

ADD https://bootstrap.pypa.io/get-pip.py /tmp/get-pip.py
ADD https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip /tmp/awscliv2.zip
ADD https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh /tmp/install_homebrew.sh

RUN set -e \
      && apt-get -y update \
      && apt-get -y upgrade \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        ansible apt-transport-https apt-file apt-utils aptitude aria2 \
        build-essential ca-certificates cifs-utils colordiff corkscrew curl \
        file g++ git gnupg golang htop libncurses5-dev locales lua5.4 luajit nkf \
        nmap npm p7zip-full pandoc pbzip2 pigz pkg-config procps python3-dev \
        python3-distutils r-base rake rename ruby shellcheck \
        software-properties-common sqlite3 ssh sshfs systemd-timesyncd \
        texlive-fonts-recommended texlive-plain-generic texlive-xetex time \
        tmux traceroute tree unzip wakeonlan wget whois zip zsh \
      && apt-get -y autoremove \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*

RUN set -e \
      && /bin/bash /tmp/install_homebrew.sh \
      && brew update \
      && brew upgrade \
      && brew install terragrunt tfenv tflint tfsec \
      && brew cleanup \
      && tfenv install latest

RUN set -e \
      && unzip -d /tmp /tmp/awscliv2.zip \
      && /tmp/aws/install

ENV SHELL /usr/bin/zsh

RUN set -e \
      && apt-file update

RUN set -e \
      && locale-gen en_US.UTF-8 \
      && update-locale

RUN set -e \
      && ln -s python3 /usr/bin/python \
      && /usr/bin/python3 /tmp/get-pip.py \
      && pip install -U --no-cache-dir pip \
      && pip install -U --no-cache-dir \
        ansible-lint autopep8 bandit black csvkit docker-compose docopt \
        flake8 flake8-bugbear flake8-isort ipython pandas mypy pep8-naming \
        poetry polars psutil pydantic pynvim pyright ruff scikit-learn scipy \
        seaborn statsmodels tqdm vim-vint vulture yamllint

RUN set -e \
      && echo '.DS_Store' >> /root/.gitignore \
      && git config --global core.editor vim \
      && git config --global core.excludesfile /root/.gitignore \
      && git config --global color.ui auto \
      && git config --global pull.rebase true \
      && git config --global push.default matching

ADD https://raw.githubusercontent.com/dceoy/git-rewind-days/master/git-rewind-days /usr/local/bin/git-rewind-days
ADD https://raw.githubusercontent.com/dceoy/git-rewind-days/master/git-rewind-hours /usr/local/bin/git-rewind-hours
ADD https://raw.githubusercontent.com/dceoy/print-github-tags/master/print-github-tags /usr/local/bin/print-github-tags
ADD https://raw.githubusercontent.com/dceoy/install-latest-vim/master/install_latest_vim.sh /tmp/install_latest_vim.sh
ADD https://raw.githubusercontent.com/dceoy/ansible-dev/master/roles/vim/files/vimrc /root/.vimrc
ADD https://raw.githubusercontent.com/dceoy/ansible-dev/master/roles/cli/files/zshrc /root/.zshrc
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN set -e \
      && chmod +x \
        /usr/local/bin/git-rewind-days /usr/local/bin/git-rewind-hours \
        /usr/local/bin/print-github-tags /usr/local/bin/entrypoint.sh \
        /tmp/install_latest_vim.sh

RUN set -e \
      && /tmp/install_latest_vim.sh --lua --dein /usr/local \
      && rm -f /tmp/install_latest_vim.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/zsh", "-l"]
