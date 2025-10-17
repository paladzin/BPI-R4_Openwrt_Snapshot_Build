#!/bin/sh

# --- Configuration Section ---

AP_IPADDR="192.168.1.1"        ### - Set main router's IP (leave for default)
AP_NETMASK="255.255.255.0"     ### - Set main router's netmask (leave for default)

### - Radio Hardware Configuration
COUNTRY_CODE="US"             ### - Set your country code

### - Legacy Network Credentials
LEGACY_2G_SSID="OpenWRT_2g"    ### - Set the ssid & key for 2ghz band
LEGACY_2G_KEY="12345678"    ### --------- password
# =======================
LEGACY_5G_SSID="OpenWRT_5g"    ### - Set the ssid & key for 5ghz band
LEGACY_5G_KEY="12345678"    ### --------- password
# ========================
LEGACY_6G_SSID="OpenWRT_6g"        ### - Set the ssid & key for 6ghz band
LEGACY_6G_KEY="12345678"    ### --------- password

### - MLO Network Credentials
MLD_SSID="OpenWRT_mld"         ### - Set the ssid & key for mlo
MLD_KEY="12345678"          ### --------- password

# --- End of Configuration ---

uci batch <<-EOF

  set wireless.@wifi-iface[0].ssid='${LEGACY_2G_SSID}'
  set wireless.@wifi-iface[0].key='${LEGACY_2G_KEY}'
  set wireless.@wifi-iface[0].encryption='psk2'
  set wireless.radio0.country='${COUNTRY_CODE}'
  set wireless.radio0.band='2g'
  set wireless.radio0.channel='6'
  set wireless.radio0.htmode='EHT40'
  set wireless.radio0.disabled='0'
  
  set wireless.@wifi-iface[1].ssid='${LEGACY_5G_SSID}'
  set wireless.@wifi-iface[1].key='${LEGACY_5G_KEY}'
  set wireless.@wifi-iface[1].encryption='psk2'
  set wireless.radio1.country='${COUNTRY_CODE}'
  set wireless.radio1.band='5g'
  set wireless.radio1.channel='100'
  set wireless.radio1.htmode='EHT160'
  set wireless.radio1.disabled='0'
  
  
  set wireless.@wifi-iface[2].ssid='${LEGACY_6G_SSID}'
  set wireless.@wifi-iface[2].key='${LEGACY_6G_KEY}'
  set wireless.@wifi-iface[2].encryption='sae'
  set wireless.@wifi-iface[2].ieee80211w='2'
  set wireless.@wifi-iface[2].sae_pwe='2'
  set wireless.radio2.country='${COUNTRY_CODE}'
  set wireless.radio2.band='6g'
  set wireless.radio2.channel='69'
  set wireless.radio2.htmode='EHT320'
  set wireless.radio2.disabled='0'
  
  #set wireless.@wifi-mld[0].ssid='${MLD_SSID}'
  #set wireless.@wifi-mld[0].key='${MLD_KEY}'
	

EOF

uci commit wireless

uci batch <<-EOF
  set network.lan.proto='static'
  set network.lan.ipaddr='${AP_IPADDR}'
  set network.lan.netmask='${AP_NETMASK}'

EOF

uci commit network

uci commit

exit 0