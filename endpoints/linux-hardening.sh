#!/bin/bash
set -euo pipefail

HARDENING_LEVEL="${1:-level1}"

sysctl_harden() {
    cat > /etc/sysctl.d/99-security.conf << 'EOF'
net.ipv4.tcp_syncookies = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_sack = 0
net.ipv4.tcp_dsack = 0
net.ipv4.tcp_fack = 0
net.core.bpf_jit_enable = 0
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.printk = 3 3 3 3
kernel.kexec_load_disabled = 1
kernel.unprivileged_bpf_disabled = 1
net.core.bpf_jit_harden = 2
EOF
    sysctl --system
}

ssh_harden() {
    sed -i 's/^#PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
    sed -i 's/^#MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
    sed -i 's/^#ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
    sed -i 's/^#ClientAliveCountMax.*/ClientAliveCountMax 2/' /etc/ssh/sshd_config
    systemctl restart sshd
}

file_permissions_harden() {
    chmod 644 /etc/passwd
    chmod 640 /etc/shadow
    chmod 644 /etc/group
    chmod 640 /etc/gshadow
    chmod 750 /etc/sudoers.d
    chmod 440 /etc/sudoers
    find / -xdev -perm -0002 -type d 2>/dev/null | xargs chmod o-w
    find / -xdev -nouser -o -nogroup 2>/dev/null | xargs rm -f
}

pam_harden() {
    if command -v pwquality &>/dev/null; then
        cat > /etc/security/pwquality.conf << 'PAMEOF'
minlen = 14
dcredit = -1
ucredit = -1
ocredit = -1
lcredit = -1
minclass = 4
maxrepeat = 3
gecoscheck = 1
enforce_for_root
PAMEOF
    fi
}

service_harden() {
    local services=("avahi-daemon" "cups" "rpcbind" "bluetooth" "cron")
    for svc in "${services[@]}"; do
        systemctl disable --now "$svc" 2>/dev/null || true
    done
}

sysctl_harden
ssh_harden
file_permissions_harden
pam_harden
service_harden

echo "Linux hardening baseline applied (level: $HARDENING_LEVEL)"
