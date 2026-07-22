# Network Security Lab Tutorial

## Prerequisites

Before starting, ensure you have:

- Docker and Docker Compose installed
- A hypervisor (VirtualBox, Proxmox, or VMware) for pfSense and MikroTik VMs
- At least 8GB RAM allocated to lab VMs
- Network interface capable of promiscuous mode (for virtual networking)

## Step 1: Deploy Monitoring Stack

The monitoring stack (Wazuh, Prometheus, Grafana, AdGuard) runs in Docker and provides the visibility layer for the entire lab.

```bash
# Clone the repository
git clone https://github.com/vtino17/network-security-lab.git
cd network-security-lab/docker

# Start all services
docker compose up -d

# Verify services are running
docker ps --format "table {{.Names}}\t{{.Status}}"
```

Expected output:

```
NAMES              STATUS
wazuh-manager      Up 10 seconds
wazuh-indexer      Up 10 seconds
wazuh-dashboard    Up 10 seconds
prometheus         Up 10 seconds
grafana            Up 10 seconds
adguard            Up 10 seconds
```

Access points:

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| Wazuh Dashboard | https://localhost | admin:admin |
| Grafana | http://localhost:3000 | admin:changeme |
| Prometheus | http://localhost:9090 | - |
| AdGuard | http://localhost:80 | - |

## Step 2: Configure Network Segmentation

### Create virtual network

In your hypervisor, create the following virtual networks:

| Network | Subnet | VLAN | Purpose |
|---------|--------|------|---------|
| mgmt-net | 10.0.10.0/24 | 10 | Management |
| server-net | 10.0.20.0/24 | 20 | Internal services |
| iot-net | 10.0.30.0/24 | 30 | IoT devices |
| guest-net | 10.0.40.0/24 | 40 | Guest access |
| voip-net | 10.0.50.0/24 | 50 | Voice traffic |

### Deploy MikroTik CHR

1. Download MikroTik CHR image from https://mikrotik.com/download
2. Create a VM with the CHR image
3. Attach one interface per VLAN network
4. Boot and login (default: admin with no password)

### Apply VLAN configuration

```bash
# Copy config to MikroTik
scp mikrotik/vlan-config.rsc admin@10.0.10.1:/

# Import via SSH
ssh admin@10.0.10.1 "/import vlan-config.rsc"
```

### Apply firewall rules

```bash
scp mikrotik/firewall-base.rsc admin@10.0.10.1:/
ssh admin@10.0.10.1 "/import firewall-base.rsc"
```

### Configure DNS

```bash
scp mikrotik/dns-config.rsc admin@10.0.10.1:/
ssh admin@10.0.10.1 "/import dns-config.rsc"
```

## Step 3: Deploy pfSense

1. Download pfSense ISO from https://www.pfsense.org/download/
2. Create VM with:
   - WAN interface (bridged to your physical network)
   - LAN interface (connected to mgmt-net)
3. Install and configure:
   - WAN: DHCP or static IP
   - LAN: 10.0.10.254/24
4. Apply firewall rules:

```bash
# Access pfSense web interface at https://10.0.10.254
# Navigate to Diagnostics > Backup & Restore
# Upload pfsense/firewall-rules.xml
# Upload pfsense/nat-rules.xml
```

## Step 4: Connect Monitoring to Network

### Configure Wazuh syslog listener

Wazuh is already configured to accept syslog from MikroTik and pfSense.

### Configure MikroTik logging

```bash
ssh admin@10.0.10.1 "/system logging action set 0 remote=10.0.20.5 remote-port=1514"
ssh admin@10.0.10.1 "/system logging add action=remote topics=info,error,warning,firewall"
```

### Configure pfSense syslog

1. Navigate to Status > System Logs > Settings
2. Enable "Send log messages to remote syslog server"
3. Set server: 10.0.20.5:514
4. Save

## Step 5: Deploy Endpoint Hardening

### Windows endpoint (run as Administrator)

```powershell
# Clone repo on the Windows endpoint
git clone https://github.com/vtino17/network-security-lab.git
cd network-security-lab\endpoints

# Execute hardening script
powershell -ExecutionPolicy Bypass -File windows-hardening.ps1
```

What this does:
- Disables SMBv1 (prevents EternalBlue-style attacks)
- Enforces NTLMv2 only (prevents pass-the-hash relay)
- Restricts anonymous access
- Configures advanced audit logging
- Enables Windows Defender with cloud protection

### Linux endpoint

```bash
# Copy and run
chmod +x endpoints/linux-hardening.sh
sudo bash endpoints/linux-hardening.sh

# Or run from the repo
sudo bash network-security-lab/endpoints/linux-hardening.sh
```

What this does:
- Kernel hardening via sysctl (40+ security parameters)
- SSH lockdown (key-only, rate limiting, no root password login)
- File permission hardening
- Password policy enforcement
- Disables unnecessary services (avahi, cups, bluetooth)

## Step 6: Automate with Ansible

For managing multiple endpoints:

```bash
# Install Ansible
pip install ansible

# Navigate to ansible directory
cd network-security-lab/ansible

# Run the playbook
ansible-playbook -i inventory.yml site.yml -k
```

## Step 7: Verify Everything

```bash
# Run connectivity tests
bash tests/test_connectivity.sh
```

Expected output:

```
PASS: 10.0.10.1 is reachable
PASS: 10.0.20.5 is reachable
PASS: 10.0.20.10 is reachable
PASS: 10.0.30.1 is reachable
PASS: 10.0.40.1 is reachable
PASS: 10.0.50.1 is reachable
PASS: 10.0.20.5:443 is open
PASS: 10.0.20.5:1514 is open
PASS: 10.0.20.10:9090 is open
PASS: 10.0.20.11:3000 is open
PASS: 10.0.20.15:9200 is open
PASS: wazuh.internal resolves to 10.0.20.5
PASS: grafana.internal resolves to 10.0.20.11
```

## Step 8: Daily Operations

Refer to the operations runbook at `docs/runbook.md` for:

- Daily health checks
- Security alert review procedures
- Incident response steps
- Backup and recovery procedures

## Troubleshooting

### Wazuh not receiving logs

```bash
# Check Wazuh manager status
docker logs wazuh-manager --tail 50

# Verify syslog listener is active
docker exec wazuh-manager netstat -tlnp | grep 1514
```

### MikroTik config import fails

```bash
# Check file exists
ssh admin@10.0.10.1 "/file print"

# Verify file content
ssh admin@10.0.10.1 "/file print detail where name=vlan-config.rsc"
```

### Docker containers not starting

```bash
# Check Docker logs
docker compose logs wazuh-manager --tail 30
docker compose logs prometheus --tail 30

# Verify port availability
netstat -tlnp | grep -E ":(1514|9090|3000|9200)"
```
