FROM ubuntu:22.04 as build

# Create dirs for both archs although in the end only one will be used
RUN mkdir -p /usr/lib/x86_64-linux-gnu && mkdir -p /usr/lib/aarch64-linux-gnu

RUN apt-get update && apt install software-properties-common -y && add-apt-repository --yes --update ppa:ansible/ansible
RUN apt-get update && apt-get dist-upgrade -y && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install curl rsync openssh-client git gnupg jq ca-certificates software-properties-common python3-hcloud -y
RUN apt-get install ansible ansible-lint -y

# This is an alternative way to install ansible, but it leads to a bigger image.
#RUN apt-get update && apt-get dist-upgrade -y && apt-get install rsync openssh-client git gnupg jq ca-certificates pipx -y
#RUN pipx install ansible --include-deps
#RUN for package in ansible-lint flake8 flake8-print molecule yamllint pytest; do pipx install "$package"; done; pipx install flake8-mutable --include-deps

# Cleanup
RUN apt-get clean
RUN	find /usr/lib/ -name '__pycache__' -print0 | xargs -0 -n1 rm -rf \
	&& find /usr/lib/ -name '*.pyc' -print0 | xargs -0 -n1 rm -rf
RUN update-ca-certificates --fresh


FROM ubuntu:22.04

RUN mkdir -p /root/.ssh && chmod go-rwx /root/.ssh

COPY --from=build /lib/ /lib/
COPY --from=build /usr/lib/aarch64-linux-gnu /usr/lib/aarch64-linux-gnu
COPY --from=build /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu
COPY --from=build /usr/lib/python3/ /usr/lib/python3/
COPY --from=build /usr/lib/python3.10/ /usr/lib/python3.10/
COPY --from=build /usr/lib/python3.11/ /usr/lib/python3.11/
COPY --from=build /usr/bin/ /usr/bin/
COPY --from=build /etc/ssl/certs /etc/ssl/certs

ENV SSL_CERT_DIR=/etc/ssl/certs

RUN rmdir /usr/lib/aarch64-linux-gnu || rmdir /usr/lib/x86_64-linux-gnu || true

CMD ["/bin/sh"]
