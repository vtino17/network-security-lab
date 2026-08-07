#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/deploy.sh

docker() { [[ "$1 $2" == "compose version" ]]; }
ansible-playbook() { :; }
check_requirements >/dev/null

calls=""
sshpass() {
    calls+="$*"$'\n'
}
export MIKROTIK_PASSWORD='test-only-secret'
configure_mikrotik router.example admin >/dev/null

[[ "$calls" == *"-e scp -o StrictHostKeyChecking=accept-new"* ]]
[[ "$calls" == *"-e ssh -o StrictHostKeyChecking=accept-new"* ]]
[[ "$calls" != *"StrictHostKeyChecking=no"* ]]

if configure_mikrotik '../invalid' admin >/dev/null 2>&1; then
    echo "unsafe host was accepted" >&2
    exit 1
fi
