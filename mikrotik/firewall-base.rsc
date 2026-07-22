/ip firewall filter
add chain=input connection-state=invalid action=drop
add chain=input connection-state=established action=accept
add chain=input connection-state=related action=accept
add chain=input protocol=icmp action=accept

add chain=input protocol=tcp psd=21,3s,3,1 action=add-src-to-address-list address-list=scanner address-list-timeout=1d
add chain=input src-address-list=scanner action=drop

add chain=input protocol=tcp dst-port=22 src-address-list=mgmt-hosts action=accept
add chain=input protocol=tcp dst-port=8291 src-address-list=mgmt-hosts action=accept
add chain=input protocol=tcp dst-port=443 action=accept

add chain=input action=drop

/ip firewall nat
add chain=srcnat out-interface=pppoe-out action=masquerade
