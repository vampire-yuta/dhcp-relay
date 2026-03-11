#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y isc-dhcp-relay

# DHCP Server のアドレス（サーバNW側）
DHCP_SERVER="192.168.57.3"
# クライアントがいるインターフェース（ブロードキャストを受信する側のみ）
# 192.168.56.2 が付いているNICを自動検出（Debian は enp0s8 等の可能性あり）
CLIENT_IF_1=$(ip -o -4 addr show | grep "192.168.56.2" | awk '{print $2}' | head -1)
CLIENT_IF_2=$(ip -o -4 addr show | grep "192.168.57.2" | awk '{print $2}' | head -1)
INTERFACES="${CLIENT_IF_1:-eth1} ${CLIENT_IF_2:-eth2}"

cat > /etc/default/isc-dhcp-relay << EOF
SERVERS="$DHCP_SERVER"
INTERFACES="$INTERFACES"
OPTIONS=""
EOF

systemctl enable isc-dhcp-relay
systemctl restart isc-dhcp-relay
