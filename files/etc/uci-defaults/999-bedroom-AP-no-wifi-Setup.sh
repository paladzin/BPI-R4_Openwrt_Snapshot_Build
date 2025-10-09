#!/bin/sh

# --- Configuration Section ---

AP_IPADDR="192.168.1.3"        ### - Set AP router's IP
AP_NETMASK="255.255.255.0"     ### - Set AP router's netmask
AP_GATEWAY="192.168.1.1"       ### - Set gateway to your main router's IP
AP_DNS="192.168.1.1"           ### - Set dns to your main router's IP

uci batch <<-EOF
  set network.lan.proto='static'
  set network.lan.ipaddr='${AP_IPADDR}'
  set network.lan.netmask='${AP_NETMASK}'
  set network.lan.gateway='${AP_GATEWAY}'
  set network.lan.dns='${AP_DNS}'
  set network.lan.ip6assign='60'
EOF

uci commit network

uci batch <<-EOF
  set dhcp.lan.ignore='1'
  set dhcp.lan.ra='disabled'
  set dhcp.lan.dhcpv6='disabled'
EOF

/etc/init.d/dnsmasq disable
/etc/init.d/firewall disable
/etc/init.d/odhcpd disable

uci commit

exit 0