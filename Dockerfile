FROM cytopia/ansible:2.11-tools

RUN mkdir -p /root/.ssh && chmod go-rwx /root/.ssh

RUN apk update

RUN apk add rsync openssh git
