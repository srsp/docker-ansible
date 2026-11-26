FROM ubuntu:26.04 AS build

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y python3-pip

COPY requirements.txt /tmp/requirements.txt
# System Python rather than a venv: hosts with ansible_connection=local run modules
# with the discovered /usr/bin/python3, which must see the same libraries.
# --ignore-installed puts every dependency into /usr/local, the only part copied.
# No bytecode: compiling the collections would add about 190 MB.
RUN pip install --break-system-packages --ignore-installed --no-cache-dir --no-compile -r /tmp/requirements.txt
# Changelogs and coverage reports shipped inside the collections; nothing reads
# them at run time.
RUN find /usr/local/lib/python3*/dist-packages/ansible_collections -mindepth 3 -maxdepth 3 \
		\( -name changelogs -o -name 'CHANGELOG.*' -o -name htmlcov \) -exec rm -rf {} +

FROM ubuntu:26.04

RUN apt-get update && apt-get dist-upgrade -y \
	&& DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install --no-install-recommends -y \
		bzip2 ca-certificates curl git gnupg jq less openssh-client patch python3 python3-pip \
		rsync sshpass tzdata xz-utils \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/.ssh && chmod go-rwx /root/.ssh

COPY --from=build /usr/local/ /usr/local/
# PyPI's certifi ships its own CA list; Debian's used the system store, which also
# holds CAs added with update-ca-certificates.
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
ENV SSL_CERT_DIR=/etc/ssl/certs
COPY --chmod=755 scripts/verify-tools.sh /usr/local/bin/verify-tools
RUN PYTHONDONTWRITEBYTECODE=1 /usr/local/bin/verify-tools && rm -rf /root/.ansible

CMD ["/bin/sh"]
