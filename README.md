local-dev
=========

Dockerfile for a local development environment

[![CI](https://github.com/dceoy/local-dev/actions/workflows/docker-build-and-push.yml/badge.svg)](https://github.com/dceoy/local-dev/actions/workflows/docker-build-and-push.yml)

Docker image
-------------

Pull the image from [GitHub Container Registry](https://github.com/dceoy/local-dev/pkgs/container/local-dev).

```sh
$ docker image pull ghcr.io/dceoy/local-dev:latest
```

Run Zsh in the container.

```sh
$ docker container run --rm -it \
    -v "${PWD}:/wd" -v "${HOME}/.ssh:/root/.ssh:ro" -w /wd \
    ghcr.io/dceoy/local-dev:latest
```
