#!/bin/sh
set -eu

ansible --version >/dev/null
ansible-galaxy --version >/dev/null
/opt/ansible-lint/bin/ansible-lint --version >/dev/null
