/ip firewall filter
add chain=input connection-state=invalid action=drop
add chain=input connection-state=established action=accept
add chain=input connection-state=related action=accept
add chain=input protocol=icmp limit=5,5:packet action=accept comment="rate-limit icmp"
add chain=input protocol=icmp action=drop

add chain=input protocol=tcp psd=21,3s,3,1 action=add-src-to-address-list address-list=scanner address-list-timeout=1d
add chain=input src-address-list=scanner action=drop

add chain=input protocol=tcp dst-port=22 src-address-list=mgmt-hosts action=accept comment="ssh mgmt only"
add chain=input protocol=tcp dst-port=8291 src-address-list=mgmt-hosts action=accept comment="winbox mgmt only"
add chain=input protocol=tcp dst-port=443 src-address-list=mgmt-hosts action=accept comment="https mgmt only"

add chain=input action=drop

/ip firewall nat
add chain=srcnat out-interface=pppoe-out action=masquerade
