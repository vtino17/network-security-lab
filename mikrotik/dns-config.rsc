/ip dns
set servers=10.0.20.20,1.1.1.1 allow-remote-requests=yes cache-size=8192

/ip dns static
add name=wazuh.internal address=10.0.20.5
add name=grafana.internal address=10.0.20.11
add name=prometheus.internal address=10.0.20.10
add name=elk.internal address=10.0.20.15
add name=dns.internal address=10.0.20.20

/ip dns static
add name=malware-block.local address=0.0.0.0
add name=phishing-block.local address=0.0.0.0
add name=cnc-block.local address=0.0.0.0
