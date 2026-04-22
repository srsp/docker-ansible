![build](https://github.com/srsp/docker-ansible/actions/workflows/docker-publish.yml/badge.svg)
[![Docker Hub](https://img.shields.io/docker/v/srsp/ansible?label=Docker%20Hub&logo=docker&logoColor=white)](https://hub.docker.com/r/srsp/ansible)

# docker-ansible

Docker image with

* ansible
* ansible-galaxy
* ansible-lint
* curl
* git
* openssh-client
* python3-hcloud
* rsync

## Usage
```bash
docker pull srsp/ansible
```

## Developers
This image uses the latest Ubuntu LTS release as base image and installs the latest `ansible`
package that the official Ansible Ubuntu PPA provides. `ansible-lint` is installed in its own
virtual environment to avoid distro package compatibility issues with the PPA Ansible packages.

If you want to build it yourself with 

```bash
docker build -f Dockerfile -t ansible:test .
```

the build might fail with an error complaining about not finding a particular python version. 
This can happen, if Ubuntu decides to ship a new minor version of `python`. In this case
you can check which versions are actually ship and update them in the `Dockerfile`.
