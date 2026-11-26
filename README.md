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

Image tags are the ansible-core version (`2.22.0`, `2.22`).

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
`Tag ansible version`, which tags a new ansible-core version and triggers `Docker Publish`.

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
