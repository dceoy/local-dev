#!/usr/bin/env bash

set -euox pipefail

git config --global safe.directory "${PWD}"
exec "${@}"
