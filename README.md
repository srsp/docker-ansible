![build](https://github.com/srsp/docker-ansible/actions/workflows/docker-publish.yml/badge.svg)
[![Docker Hub](https://img.shields.io/docker/v/srsp/ansible?label=Docker%20Hub&logo=docker&logoColor=white)](https://hub.docker.com/r/srsp/ansible)

# docker-ansible

Docker image with

* ansible (the community package with all its collections) and ansible-core
* ansible-galaxy
* ansible-lint and yamllint
* Python libraries for common controller-side modules and plugins: hcloud, jmespath, paramiko,
  pyjwt, pywinrm, requests, xmltodict
* curl
* git
* gnupg
* jq
* openssh-client and sshpass
* rsync

Tags:

* `latest` and `main`: the current `main` branch. Every merged update, including library and
  collection bumps, publishes them after the image checks pass.
* `2.22.0`, `2.22`: the ansible-core version. These are published when a new ansible-core version
  is merged and don't change with later bumps of other packages.

## Usage
```bash
docker pull srsp/ansible
```

## Developers
This image uses the latest Ubuntu LTS release as base image and installs Ansible from PyPI with the
versions pinned in `requirements.txt`. The packages go into the system Python (`/usr/local`), not a
virtual environment, so modules run on the controller find their libraries both with implicit
localhost and with inventory hosts that set `ansible_connection=local` and use interpreter discovery.

Dependabot bumps the pins (`ansible` and `ansible-core` together). The `Dependabot pip auto-merge`
workflow builds the image, runs `verify-tools` and merges the pull request. It then starts
`Docker Publish` for `main`, which publishes `main` and `latest`, and `Tag ansible version`. If the
ansible-core version is new, that workflow creates the Git tag and release and publishes the
version tags.

Images built on top of this one should install extra Python libraries with
`pip install --break-system-packages`, not with apt `python3-*` packages. The libraries in
`/usr/local` take precedence over Ubuntu's, so an apt package can end up running against a newer
dependency than it supports: Ubuntu's `python3-openssl` fails to import with the `cryptography`
installed here.

Build the image with:
```bash
docker build -f Dockerfile -t ansible:test .
```

The build runs `verify-tools`: it checks that the Ansible tools run, that the system Python has the
libraries, that YAML and `hetzner.hcloud` inventories load, and that `hetzner.hcloud` and
`community.docker` modules on localhost fail on the unreachable API rather than on a missing library.
If a check fails, `docker build` fails immediately.

You can also re-run the same check against a built image:

```bash
docker run --rm ansible:test /usr/local/bin/verify-tools
```
