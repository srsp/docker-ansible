FROM ubuntu:24.04 AS build

# Create dirs for both archs although in the end only one will be used
RUN mkdir -p /usr/lib/x86_64-linux-gnu && mkdir -p /usr/lib/aarch64-linux-gnu

RUN apt-get update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt install software-properties-common tzdata -y && ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime
RUN add-apt-repository --yes --update ppa:ansible/ansible
RUN apt-get update && apt-get dist-upgrade -y
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install curl rsync openssh-client git gnupg jq ca-certificates software-properties-common python3-hcloud python3-pip python3-venv -y
RUN apt-get install ansible -y
RUN python3 -m venv /opt/ansible-lint \
	&& /opt/ansible-lint/bin/pip install --no-cache-dir --upgrade pip \
	&& /opt/ansible-lint/bin/pip install --no-cache-dir ansible-lint

COPY scripts/verify-tools.sh /usr/local/bin/verify-tools
RUN chmod +x /usr/local/bin/verify-tools && /usr/local/bin/verify-tools

# This is an alternative way to install ansible, but it leads to a bigger image.
#RUN apt-get update && apt-get dist-upgrade -y && apt-get install rsync openssh-client git gnupg jq ca-certificates pipx -y
#RUN pipx install ansible --include-deps
#RUN for package in ansible-lint flake8 flake8-print molecule yamllint pytest; do pipx install "$package"; done; pipx install flake8-mutable --include-deps

# Cleanup
RUN apt-get clean
RUN	find /usr/lib/ -name '__pycache__' -print0 | xargs -0 -n1 rm -rf \
	&& find /usr/lib/ -name '*.pyc' -print0 | xargs -0 -n1 rm -rf

FROM ubuntu:24.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install ca-certificates -y && apt-get clean
RUN update-ca-certificates --fresh

RUN mkdir -p /root/.ssh && chmod go-rwx /root/.ssh

COPY --from=build /lib/ /lib/
COPY --from=build /usr/lib/aarch64-linux-gnu /usr/lib/aarch64-linux-gnu
COPY --from=build /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu
COPY --from=build /usr/lib/python3/ /usr/lib/python3/
COPY --from=build /usr/lib/python3.12/ /usr/lib/python3.12/
COPY --from=build /usr/bin/ /usr/bin/
COPY --from=build /usr/local/bin/verify-tools /usr/local/bin/verify-tools
COPY --from=build /opt/ansible-lint/ /opt/ansible-lint/

ENV SSL_CERT_DIR=/etc/ssl/certs
ENV PATH="/opt/ansible-lint/bin:${PATH}"

RUN rmdir /usr/lib/aarch64-linux-gnu || rmdir /usr/lib/x86_64-linux-gnu || true
RUN /usr/local/bin/verify-tools

CMD ["/bin/sh"]
