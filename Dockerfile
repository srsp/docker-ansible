FROM debian:testing as build

RUN apt-get update && apt-get dist-upgrade -y && apt-get install ansible rsync openssh-client git gnupg jq -y
RUN apt-get clean
RUN	find /usr/lib/ -name '__pycache__' -print0 | xargs -0 -n1 rm -rf \
	&& find /usr/lib/ -name '*.pyc' -print0 | xargs -0 -n1 rm -rf


FROM debian:testing

COPY --from=build /lib/ /lib/
COPY --from=build /usr/lib/python3/ /usr/lib/python3/
COPY --from=build /usr/lib/python3.10/ /usr/lib/python3.10/
COPY --from=build /usr/lib/python3.9/ /usr/lib/python3.9/
COPY --from=build /usr/bin/ /usr/bin/

RUN mkdir -p /root/.ssh && chmod go-rwx /root/.ssh

