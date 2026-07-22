# Operations Runbook

## Daily Operations

### Check System Health

```bash
# Check all services
docker ps --format "table {{.Names}}\t{{.Status}}"

# Check disk usage
df -h | grep -E "Filesystem|/dev/"

# Check memory usage
free -h

# Check system load
uptime
```

### Review Security Alerts

1. Open Wazuh dashboard: https://wazuh.internal (or https://10.0.20.5)
2. Check "Security Events" tab
3. Review alerts with level 10+
4. Acknowledge false positives
5. Escalate confirmed incidents

### Check Network Status

```bash
# Ping all gateways
for gw in 10.0.10.1 10.0.20.1 10.0.30.1 10.0.40.1 10.0.50.1; do
    ping -c 1 -W 2 $gw >/dev/null && echo "$gw OK" || echo "$gw DOWN"
done

# Check interface status on MikroTik
ssh admin@10.0.10.1 "/interface print where running"
```

## Incident Response

### Step 1: Isolate affected VLAN

```bash
# Block all traffic from suspicious VLAN
ssh admin@10.0.10.1 "/ip firewall filter add chain=forward in-interface=vlan-iot action=drop comment='Incident isolation'"
```

### Step 2: Collect forensic data

```bash
# Enable full packet capture
tcpdump -i any -w /tmp/incident-$(date +%Y%m%d).pcap

# Collect system logs
journalctl -u wazuh-agent --since "1 hour ago" > /tmp/wazuh-logs.txt
```

### Step 3: Analyze with pcap-forensics

```bash
pcap-forensics /tmp/incident-20260722.pcap --output incident-report.json --verbose
```

### Step 4: Reset after investigation

```bash
# Remove isolation rule
ssh admin@10.0.10.1 "/ip firewall filter remove [find comment='Incident isolation']"

# Rotate credentials
ssh admin@10.0.10.1 "/user set 0 password=new-password"
```

## Backup Procedures

### Configuration Backups

```bash
# Export MikroTik config
ssh admin@10.0.10.1 "/export file=backup-$(date +%Y%m%d)"

# Backup pfSense config
scp admin@pfsense:/cf/conf/config.xml /backups/pfsense/

# Backup Wazuh config
tar -czf /backups/wazuh-config-$(date +%Y%m%d).tar.gz /var/ossec/etc/
```

### Data Backups

```bash
# Backup Grafana dashboards
docker exec grafana grafana export > /backups/grafana-dashboards.json

# Backup Prometheus data (snapshot)
curl -X POST http://localhost:9090/api/v1/admin/tsdb/snapshot
```
