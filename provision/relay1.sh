#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y isc-dhcp-relay

# DHCP Server (59.0) 宛に転送。ルータ経由で到達
DHCP_SERVER="192.168.59.3"
# クライアント側IF（192.168.56.2 が付いているNIC）
CLIENT_IF=$(ip -o -4 addr show | grep "192.168.56.2" | awk '{print $2}' | head -1)
CLIENT_IF="${CLIENT_IF:-eth1}"

cat > /etc/default/isc-dhcp-relay << EOF
SERVERS="$DHCP_SERVER"
INTERFACES="$CLIENT_IF"
OPTIONS=""
EOF

# 59.0 へはルータ (192.168.56.1) 経由
ip route add 192.168.59.0/24 via 192.168.56.1 || true

systemctl enable isc-dhcp-relay
systemctl restart isc-dhcp-relay
