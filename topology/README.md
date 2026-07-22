# Network Topology

Physical and logical topology documentation for the security lab.

## Physical Topology

Internet -- pfSense (192.168.1.1) -- Switch (Management VLAN 10)
                                    -- MikroTik CHR (VLAN routing)
                                    -- Wazuh Server (10.0.20.5)
                                    -- Prometheus + Grafana (10.0.20.10)
                                    -- ELK Stack (10.0.20.15)
                                    -- Endpoints (10.0.10.x)

## IP Address Management

### Management Network (10.0.10.0/24)

| Device | IP Address | Description |
|--------|------------|-------------|
| Management gateway | 10.0.10.1 | VLAN 10 gateway |
| Admin workstation | 10.0.10.10 | Daily administration |
| Backup server | 10.0.10.20 | Backup and recovery |
| Jump host | 10.0.10.100 | Secure access point |

### Server Network (10.0.20.0/24)

| Device | IP Address | Service |
|--------|------------|---------|
| Server gateway | 10.0.20.1 | VLAN 20 gateway |
| Wazuh manager | 10.0.20.5 | SIEM and alerting |
| Wazuh indexer | 10.0.20.6 | Log storage |
| Prometheus | 10.0.20.10 | Metrics collection |
| Grafana | 10.0.20.11 | Dashboard visualization |
| ELK node | 10.0.20.15 | Log aggregation |
| DNS server | 10.0.20.20 | Internal DNS resolution |
| DHCP server | 10.0.20.21 | Dynamic IP allocation |
| Repository mirror | 10.0.20.30 | Package and ISO cache |
