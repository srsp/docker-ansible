FROM williamyeh/ansible:debian9

RUN mkdir -p /root/.ssh && chmod go-rwx /root/.ssh

RUN apt-get update && apt-get install -y rsync
