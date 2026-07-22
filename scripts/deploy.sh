#!/bin/bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"

check_requirements() {
    local deps=("docker" "docker-compose" "ansible-playbook")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: $cmd not found"
            exit 1
        fi
    done
    echo "All requirements satisfied"
}

deploy_monitoring() {
    echo "Deploying monitoring stack..."
    cd "$LAB_DIR/docker"
    docker compose pull
    docker compose up -d
    echo "Monitoring stack deployed"
}

configure_mikrotik() {
    local router_ip="${1:-10.0.10.1}"
    local ssh_user="${2:-admin}"
    echo "Configuring MikroTik at $router_ip..."
    if command -v sshpass &>/dev/null; then
        for config in "$LAB_DIR/mikrotik/"*.rsc; do
            sshpass -p "$MIKROTIK_PASSWORD" ssh -o StrictHostKeyChecking=no "$ssh_user@$router_ip" "/import file-name=$(basename "$config")"
        done
        echo "MikroTik configured"
    else
        echo "sshpass not found. Import configs manually via WinBox."
    fi
}

run_ansible() {
    echo "Running Ansible playbooks..."
    cd "$LAB_DIR/ansible"
    ansible-galaxy collection install -r requirements.yml 2>/dev/null || true
    ansible-playbook -i inventory.yml site.yml --ask-become-pass
    echo "Ansible playbooks completed"
}

validate_deployment() {
    echo "Running validation tests..."
    cd "$LAB_DIR/tests"
    bash test_connectivity.sh
    echo "Validation completed"
}

case "${1:-all}" in
    check)
        check_requirements
        ;;
    monitoring)
        deploy_monitoring
        ;;
    mikrotik)
        configure_mikrotik "${2:-}"
        ;;
    ansible)
        run_ansible
        ;;
    validate)
        validate_deployment
        ;;
    all)
        check_requirements
        deploy_monitoring
        configure_mikrotik "${2:-}"
        run_ansible
        validate_deployment
        echo "Full deployment completed"
        ;;
    *)
        echo "Usage: $0 {check|monitoring|mikrotik|ansible|validate|all}"
        exit 1
        ;;
esac
