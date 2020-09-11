#!/usr/bin/env bash
#
# Set up a minimal development server
#
# Usage:
#   setup_minimal_dev.sh [--debug]
#   setup_minimal_dev.sh --version
#   setup_minimal_dev.sh -h|--help
#
# Options:
#   --debug           Debug mode
#   --version         Print version
#   -h, --help        Print usage

set -euo pipefail

if [[ ${#} -ge 1 ]]; then
  for a in "${@}"; do
    [[ "${a}" = '--debug' ]] && set -x && break
  done
fi

COMMAND_PATH=$(realpath "${0}")
COMMAND_NAME=$(basename "${COMMAND_PATH}")
COMMAND_VERSION='v0.0.1'

function print_version {
  echo "${COMMAND_NAME}: ${COMMAND_VERSION}"
}

function print_usage {
  sed -ne '1,2d; /^#/!q; s/^#$/# /; s/^# //p;' "${COMMAND_PATH}"
}

function abort {
  {
    if [[ ${#} -eq 0 ]]; then
      cat -
    else
      COMMAND_NAME=$(basename "${COMMAND_PATH}")
      echo "${COMMAND_NAME}: ${*}"
    fi
  } >&2
  exit 1
}

while [[ ${#} -ge 1 ]]; do
  case "${1}" in
    '--debug' )
      shift 1
      ;;
    '--version' )
      print_version && exit 0
      ;;
    '-h' | '--help' )
      print_usage && exit 0
      ;;
    * )
      abort "invalid argument: ${1}"
      ;;
  esac
done

sudo -v
ZSH='/usr/bin/zsh'
PYTHON='/usr/bin/python3'

cat << EOF > /tmp/sudo_install.sh
export DEBIAN_FRONTEND=noninteractive;
ln -sf bash /bin/sh && ln -s python3 /usr/bin/python;

apt-get -y update \
  && apt-get -y dist-upgrade \
  && apt-get -y install --no-install-recommends --no-install-suggests \
    apt-transport-https apt-file apt-utils aptitude build-essential \
    cifs-utils colordiff corkscrew curl docker.io htop git gnupg golang \
    libluajit-5.1-dev libncurses5-dev locales lua5.1 luajit mercurial nkf \
    nmap npm p7zip-full pandoc pbzip2 pigz pkg-config python3-dev \
    python3-distutils r-base rake rename ruby shellcheck \
    software-properties-common sqlite3 ssh sshfs supervisor systemd-timesyncd \
    texlive-fonts-recommended texlive-plain-generic texlive-xetex time tmux \
    traceroute tree unzip wakeonlan wget whois zip zsh \
  && apt-get -y autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*;

apt-file update;
locale-gen en_US.UTF-8 && update-locale;

[[ $(grep -ce ${ZSH} /etc/shells) -eq 0 ]] && tee ${ZSH} | tee -a /etc/shells;
chsh $(whoami) -s ${ZSH};

curl -L https://bootstrap.pypa.io/get-pip.py | ${PYTHON};
/usr/local/bin/pip install -U pip;
EOF

sudo -E bash -x /tmp/sudo_install.sh
rm -f /tmp/sudo_install.sh

set -x

cd "${HOME}"

export PATH="${HOME}/.local/bin:${PATH}"
/usr/local/bin/pip install -U --no-cache-dir --user pip
pip install -U --no-cache-dir \
  ansible ansible-lint autopep8 bash_kernel csvkit cython docker-compose \
  docopt flake8 flake8-bugbear flake8-isort ggplot grip jupyter \
  jupyter_contrib_nbextensions jupyterthemes matplotlib pandas \
  pep8-naming pip psutil pynvim scikit-learn scipy seaborn sklearn-pandas \
  statsmodels tqdm vim-vint vulture yamllint

curl -L \
  https://raw.githubusercontent.com/dceoy/ansible-dev/master/roles/vim/files/vimrc \
  -o ~/.vimrc
curl -L \
  https://raw.githubusercontent.com/dceoy/ansible-dev/master/roles/cli/files/zshrc \
  -o ~/.zshrc

curl -L \
  https://raw.githubusercontent.com/dceoy/install-latest-vim/master/install_latest_vim.sh \
  -o /tmp/install_latest_vim.sh
bash /tmp/install_latest_vim.sh --dein || :
rm -f /tmp/install_latest_vim.sh
