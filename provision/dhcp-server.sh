#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y isc-dhcp-server

# 192.168.57.3 が付いているNICを検出（Debian は enp0s8 等の可能性あり）
SERVER_IF=$(ip -o -4 addr show | grep "192.168.57.3" | awk '{print $2}' | head -1)
SERVER_IF="${SERVER_IF:-eth1}"
cat > /etc/default/isc-dhcp-server << EOF
INTERFACESv4="$SERVER_IF"
INTERFACESv6=""
EOF

# クライアントNW用のサブネット（Relay経由で配布）
# Relay の giaddr で 192.168.56.0/24 と判断される
cat > /etc/dhcp/dhcpd.conf << 'EOF'
default-lease-time 600;
max-lease-time 7200;
authoritative;

# クライアントがいるネットワーク（Relay経由で来る）
subnet 192.168.56.0 netmask 255.255.255.0 {
  range 192.168.56.100 192.168.56.200;
  option routers 192.168.56.2;
  option subnet-mask 255.255.255.0;
}

# サーバが直接接続しているネットワーク（存在しないと起動エラーになるため定義）
subnet 192.168.57.0 netmask 255.255.255.0 {
  range 192.168.57.10 192.168.57.20;
}
EOF

systemctl enable isc-dhcp-server
systemctl restart isc-dhcp-server
