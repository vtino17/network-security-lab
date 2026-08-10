#!/bin/bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"

check_requirements() {
    local deps=("docker" "ansible-playbook")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: $cmd not found"
            exit 1
        fi
    done
    if ! docker compose version &>/dev/null; then
        echo "Error: Docker Compose v2 plugin not found"
        exit 1
    fi
    echo "All requirements satisfied"
}

deploy_monitoring() {
    echo "Deploying monitoring stack..."
    local grafana_secret="$LAB_DIR/docker/secrets/grafana_admin_password.txt"
    if [[ ! -s "$grafana_secret" ]]; then
        echo "Error: create a non-empty Grafana password at $grafana_secret" >&2
        return 1
    fi
    chmod 600 "$grafana_secret"
    cd "$LAB_DIR/docker"
    docker compose pull
    docker compose up -d
    echo "Monitoring stack deployed"
}

configure_mikrotik() {
    local router_ip="${1:-10.0.10.1}"
    local ssh_user="${2:-admin}"
    if [[ ! "$router_ip" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ || ! "$ssh_user" =~ ^[A-Za-z_][A-Za-z0-9_.-]*$ ]]; then
        echo "Error: invalid MikroTik host or SSH user" >&2
        return 1
    fi
    echo "Configuring MikroTik at $router_ip..."
    if command -v sshpass &>/dev/null; then
        if [[ -z "${MIKROTIK_PASSWORD:-}" ]]; then
            echo "Error: set MIKROTIK_PASSWORD before automated deployment" >&2
            return 1
        fi
        for config in "$LAB_DIR/mikrotik/"*.rsc; do
            local remote_name
            remote_name="$(basename "$config")"
            SSHPASS="$MIKROTIK_PASSWORD" sshpass -e scp -o StrictHostKeyChecking=accept-new "$config" "$ssh_user@$router_ip:$remote_name"
            SSHPASS="$MIKROTIK_PASSWORD" sshpass -e ssh -o StrictHostKeyChecking=accept-new "$ssh_user@$router_ip" "/import file-name=$remote_name"
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

main() {
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
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
