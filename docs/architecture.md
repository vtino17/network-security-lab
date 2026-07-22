# Architecture Document

## Overview

The Network Security Lab implements a defense-in-depth architecture with multiple security layers, network segmentation, centralized logging, and continuous monitoring.

## Network Segmentation

The lab uses five VLANs to enforce network segmentation:

- Management (VLAN 10): Administrative access only
- Server (VLAN 20): Internal services and applications
- IoT (VLAN 30): Isolated device network
- Guest (VLAN 40): Internet-only access
- VoIP (VLAN 50): Voice traffic

## Security Layers

### Perimeter Security

The pfSense firewall serves as the primary perimeter defense, providing:
- Stateful packet inspection
- VPN termination (OpenVPN/WireGuard)
- DNS filtering via AdGuard Home
- Intrusion prevention via Suricata package

### Network Security

MikroTik routers manage VLAN segmentation and inter-VLAN routing with:
- ACL-based traffic filtering between zones
- Port scan detection and mitigation
- DHCP snooping and ARP inspection
- Bandwidth management per VLAN

### Endpoint Security

All endpoints receive baseline hardening:
- Windows: SMBv1 disable, AppLocker, Defender ASR rules, audit policy
- Linux: Kernel hardening, SSH lockdown, file integrity monitoring

### Security Monitoring

Wazuh SIEM provides centralized log collection and analysis:
- Log collection from all network devices
- File integrity monitoring
- Vulnerability detection
- Compliance reporting (CIS benchmarks)

### Observability

Prometheus and Grafana provide:
- Network throughput metrics
- System resource utilization
- Alerting based on predefined thresholds
- Historical trend analysis

## Data Flow

External Traffic -> pfSense -> MikroTik (VLAN routing) -> Internal Services
                                                         -> Wazuh collects logs
                                                         -> Prometheus collects metrics
                                                         -> Grafana visualizes

## Compliance Mapping

| Control | Implementation |
|---------|---------------|
| AC-3 Access Enforcement | VLAN segmentation, firewall rules |
| AU-6 Audit Review | Wazuh SIEM alerting |
| SC-7 Boundary Protection | pfSense firewall, MikroTik ACLs |
| SI-4 System Monitoring | Prometheus + Grafana |
| CM-6 Configuration Settings | Ansible configuration management |
