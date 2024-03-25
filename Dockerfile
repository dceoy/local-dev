FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive

ADD https://bootstrap.pypa.io/get-pip.py /tmp/get-pip.py

RUN set -e \
      && apt-get -y update \
      && apt-get -y upgrade \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        ansible apt-transport-https apt-file apt-utils aptitude \
        build-essential ca-certificates cifs-utils colordiff corkscrew curl \
        htop g++ git gnupg golang libncurses5-dev locales lua5.4 luajit nkf \
        nmap npm p7zip-full pandoc pbzip2 pigz pkg-config python3-dev \
        python3-distutils r-base rake rename ruby shellcheck \
        software-properties-common sqlite3 ssh sshfs systemd-timesyncd \
        texlive-fonts-recommended texlive-plain-generic texlive-xetex time \
        tmux traceroute tree unzip wakeonlan wget whois zip zsh \
      && apt-get -y autoremove \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*

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

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN set -e \
      && chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/zsh", "-l"]
