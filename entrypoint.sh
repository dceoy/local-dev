#!/usr/bin/env bash

set -euox pipefail

HOST_DOCKER_SOCK_PATH='/mnt/host/var/run/docker.sock'
if [[ -f "${HOST_DOCKER_SOCK_PATH}" ]]; then
  socat \
    UNIX-LISTEN:/var/run/docker.sock,fork,group=docker \
    "UNIX-CONNECT:${HOST_DOCKER_SOCK_PATH}" &
fi

git config --global safe.directory "${PWD}"
exec "${@}"
