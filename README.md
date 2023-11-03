![build](https://github.com/srsp/docker-ansible/actions/workflows/docker-image.yml/badge.svg)
[![Docker Hub](https://img.shields.io/docker/v/srsp/ansible?label=Docker%20Hub&logo=docker&logoColor=white)](https://hub.docker.com/r/srsp/ansible)

# docker-ansible

Docker image with

* ansible
* ansible-galaxy
* ansible-lint
* curl
* rsync
* openssh-client
* git

## Usage
```bash
docker pull srsp/ansible
```

## Developers
This image uses `debian:testing` as base image and then just installs the latest `ansible`
package that `testing` provides. I build new releases on a regular basis and publish them 
to docker hub. 

If you want to build it yourself with 

```bash
docker build -f Dockerfile -t srsp/ansible:latest .
```

the build might fail with an error complaining about not finding a particular python version. 
This can happen, if `testing` decided to ship a new minor version of `python`. In this case
you can check which versions are actually ship and update them in the `Dockerfile`.