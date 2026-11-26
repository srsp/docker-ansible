#!/bin/sh
set -eu

WORK=$(mktemp -d /tmp/verify-tools-XXXXXX)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

echo "==> Checking tool availability..."
for tool in ansible ansible-playbook ansible-galaxy ansible-inventory ansible-vault ansible-doc ansible-lint; do
  command -v "$tool" >/dev/null || { echo "FAIL: $tool not on PATH" >&2; exit 1; }
done
ansible --version >/dev/null
ansible-galaxy --version >/dev/null
ansible-lint --version >/dev/null

# Implicit localhost runs modules with Ansible's own interpreter, inventory hosts
# with ansible_connection=local use interpreter discovery. Both must find the libraries.
echo "==> Checking the system Python has Ansible's libraries..."
/usr/bin/python3 -c 'import ansible, hcloud, requests, jmespath' \
  || { echo "FAIL: /usr/bin/python3 cannot import Ansible's libraries" >&2; exit 1; }

echo "==> Checking hetzner.hcloud collection..."
ansible-galaxy collection list 2>/dev/null | grep -q 'hetzner.hcloud' \
  || { echo "FAIL: hetzner.hcloud collection not found" >&2; exit 1; }

echo "==> Checking YAML inventory support..."
cat > inventory.yml <<'EOF'
all:
  hosts:
    testhost:
      ansible_connection: local
EOF
# A missing or unparsable inventory only warns and still exits 0.
ansible-inventory -i inventory.yml --list 2>/dev/null | grep -q '"testhost"' \
  || { echo "FAIL: YAML inventory parsing failed" >&2; exit 1; }

echo "==> Checking the hcloud inventory plugin loads..."
cat > check.hcloud.yml <<'EOF'
plugin: hetzner.hcloud.hcloud
api_token: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
api_endpoint: http://127.0.0.1:9/v1
EOF
out=$(ANSIBLE_INVENTORY_ENABLED=hetzner.hcloud.hcloud ansible-inventory -i check.hcloud.yml --list 2>&1 || true)
printf '%s\n' "$out" | grep -qi 'connection refused' \
  || { printf '%s\n' "$out" >&2; echo "FAIL: hcloud inventory plugin did not reach the API client" >&2; exit 1; }

echo "==> Checking hcloud and docker modules on the controller..."
cat > controller.yml <<'EOF'
- hosts: localhost
  gather_facts: false
  tasks:
    - hetzner.hcloud.server_info:
        api_token: "{{ 'x' * 64 }}"
        api_endpoint: http://127.0.0.1:9/v1
      register: hcloud
      ignore_errors: true
    - community.docker.docker_container:
        name: verify
        image: alpine
        docker_host: unix:///nonexistent.sock
      register: docker
      ignore_errors: true
    - ansible.builtin.assert:
        that:
          - hcloud.msg is search('Connection refused')
          - docker.msg is search('Error connecting')
          - (data | community.general.json_query('[0].a')) == 1
      vars:
        data: [{a: 1}]
EOF
printf 'localhost ansible_connection=local\n' > local.ini
ansible-playbook controller.yml >controller.log 2>&1 \
  || { cat controller.log >&2; echo "FAIL: modules on implicit localhost" >&2; exit 1; }
ansible-playbook -i local.ini controller.yml >controller.log 2>&1 \
  || { cat controller.log >&2; echo "FAIL: modules on inventory localhost" >&2; exit 1; }

echo "==> All checks passed."
