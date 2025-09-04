#!/bin/sh

# =================================================================
# OpenWrt MLO Creation Script - Revised
# =================================================================

set -e

# --- Configuration Section ---
MLO_SSID="OpenWrt_mld"
MLO_KEY="12345678"
COUNTRY_CODE="US"
# --- End of Configuration Section ---

# --- Pre-run Check ---
WIRELESS_CONFIG_FILE="/etc/config/wireless"
if [ ! -f "$WIRELESS_CONFIG_FILE" ]; then
    exit 1
fi
# --- End of Check ---

# --- 1. Clear All Existing Wi-Fi Interfaces ---
while uci -q delete wireless.@wifi-iface[0]; do :; done
while uci -q delete wireless.@wifi-mld[0]; do :; done

# --- 2. Discover Radio Devices ---
echo "Discovering radio devices..."
RADIO_2G_ID=""
RADIO_5G_ID=""
RADIO_6G_ID=""
for section in $(uci show wireless | grep '=wifi-device' | awk -F'[.=]' '{print $2}'); do
    band=$(uci -q get wireless."$section".band)
    case "$band" in
        "2g") RADIO_2G_ID="$section" ;;
        "5g") RADIO_5G_ID="$section" ;;
        "6g") RADIO_6G_ID="$section" ;;
    esac
done

if [ -z "$RADIO_2G_ID" ] || [ -z "$RADIO_5G_ID" ] || [ -z "$RADIO_6G_ID" ]; then
    exit 1
fi

# --- 3. Configure the Physical Radios ---
uci -q batch <<-EOF
    set wireless.${RADIO_2G_ID}.country='${COUNTRY_CODE}'
    set wireless.${RADIO_2G_ID}.cell_density='0'
    set wireless.${RADIO_2G_ID}.channel='6'
    set wireless.${RADIO_2G_ID}.htmode='EHT40'
    set wireless.${RADIO_2G_ID}.disabled='0'

    set wireless.${RADIO_5G_ID}.channel='100'
    set wireless.${RADIO_5G_ID}.htmode='EHT160'
    set wireless.${RADIO_5G_ID}.cell_density='3'
    set wireless.${RADIO_5G_ID}.txpower='14'
    set wireless.${RADIO_5G_ID}.country='${COUNTRY_CODE}'
    set wireless.${RADIO_5G_ID}.disabled='0'

    set wireless.${RADIO_6G_ID}.htmode='EHT320'
    set wireless.${RADIO_6G_ID}.country='${COUNTRY_CODE}'
    set wireless.${RADIO_6G_ID}.cell_density='3'
    set wireless.${RADIO_6G_ID}.channel='69'
    set wireless.${RADIO_6G_ID}.txpower='27'
    set wireless.${RADIO_6G_ID}.disabled='0'
EOF

# --- 4. Build the MLO Interface ---
uci add wireless wifi-iface

uci add_list wireless.@wifi-iface[-1].device="${RADIO_2G_ID}"
uci add_list wireless.@wifi-iface[-1].device="${RADIO_5G_ID}"
uci add_list wireless.@wifi-iface[-1].device="${RADIO_6G_ID}"

uci set wireless.@wifi-iface[-1].network='lan'
uci set wireless.@wifi-iface[-1].mode='ap'
uci set wireless.@wifi-iface[-1].ssid="${MLO_SSID}"
uci set wireless.@wifi-iface[-1].encryption='sae'
uci set wireless.@wifi-iface[-1].sae_pwe='2'
uci set wireless.@wifi-iface[-1].key="${MLO_KEY}"
uci set wireless.@wifi-iface[-1].ieee80211w='2'
uci set wireless.@wifi-iface[-1].mlo='1'
uci set wireless.@wifi-iface[-1].disabled='0'

uci rename wireless.@wifi-iface[-1]=mldssid

# --- 5. Commit and Apply Changes ---
uci commit wireless
wifi reload

exit 0