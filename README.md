local-dev
=========

Dockerfile for a local development environment

[![CI](https://github.com/dceoy/local-dev/actions/workflows/ci.yml/badge.svg)](https://github.com/dceoy/local-dev/actions/workflows/ci.yml)

Docker image
-------------

Pull the image from [GitHub Container Registry](https://github.com/dceoy/local-dev/pkgs/container/local-dev).

```sh
$ docker image pull ghcr.io/dceoy/local-dev:latest
```

Run the container.

```sh
$ docker container run --rm -it -v "${PWD}:/wd" -w /wd ghcr.io/dceoy/local-dev:latest
```

Run the container using Docker Compose.

```sh
$ docker compose run --rm local-dev
```
