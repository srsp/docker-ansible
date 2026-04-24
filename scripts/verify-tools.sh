#!/bin/sh
set -eu

echo "==> Checking tool availability..."
ansible --version >/dev/null
ansible-galaxy --version >/dev/null
ansible-lint --version >/dev/null

echo "==> Checking ansible is the system binary (not venv)..."
ANSIBLE_PATH=$(command -v ansible)
case "$ANSIBLE_PATH" in
  /opt/ansible-lint/*) echo "FAIL: ansible resolves to venv: $ANSIBLE_PATH" >&2; exit 1 ;;
esac

echo "==> Checking hetzner.hcloud collection..."
ansible-galaxy collection list 2>/dev/null | grep -q 'hetzner.hcloud' \
  || { echo "FAIL: hetzner.hcloud collection not found" >&2; exit 1; }

echo "==> Checking YAML inventory support..."
TMPINV=$(mktemp /tmp/inv-XXXXXX.yml)
cat > "$TMPINV" <<'EOF'
all:
  hosts:
    testhost:
      ansible_connection: local
EOF
ansible-inventory -i "$TMPINV" --list >/dev/null \
  || { echo "FAIL: YAML inventory parsing failed" >&2; rm -f "$TMPINV"; exit 1; }
rm -f "$TMPINV"

echo "==> All checks passed."
