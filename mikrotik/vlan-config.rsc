/interface bridge
add name=bridge-local vlan-filtering=yes

/interface bridge port
add bridge=bridge-local interface=ether2
add bridge=bridge-local interface=ether3
add bridge=bridge-local interface=ether4
add bridge=bridge-local interface=ether5

/interface vlan
add name=vlan-mgmt vlan-id=10 interface=bridge-local
add name=vlan-server vlan-id=20 interface=bridge-local
add name=vlan-iot vlan-id=30 interface=bridge-local
add name=vlan-guest vlan-id=40 interface=bridge-local
add name=vlan-voip vlan-id=50 interface=bridge-local

/interface bridge vlan
add bridge=bridge-local tagged=bridge-local untagged=ether2 vlan-ids=10
add bridge=bridge-local tagged=bridge-local untagged=ether3 vlan-ids=20
add bridge=bridge-local tagged=bridge-local untagged=ether4 vlan-ids=30,40,50

/interface bridge vlan
add bridge=bridge-local tagged=bridge-local,ether5 vlan-ids=10,20

/ip address
add address=10.0.10.1/24 interface=vlan-mgmt
add address=10.0.20.1/24 interface=vlan-server
add address=10.0.30.1/24 interface=vlan-iot
add address=10.0.40.1/24 interface=vlan-guest
add address=10.0.50.1/24 interface=vlan-voip
