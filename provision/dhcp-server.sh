#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y isc-dhcp-server

# 59.0 の NIC で listen（Vagrant が eth1/enp0s8 等に割り当て）
sleep 3
SERVER_IF=$(ip -o -4 addr show | grep "192.168.59" | awk '{print $2}' | head -1)
if [ -z "$SERVER_IF" ]; then
  SERVER_IF=$(ip -o -4 addr show | awk '{print $2}' | grep -v "^lo$" | tail -n +2 | head -1)
fi
SERVER_IF="${SERVER_IF:-eth1}"
cat > /etc/default/isc-dhcp-server << EOF
INTERFACESv4="$SERVER_IF"
INTERFACESv6=""
EOF

# 56/57/58 はリレー経由（giaddr で識別）。59 はサーバ直結（定義のみ）
cat > /etc/dhcp/dhcpd.conf << 'EOF'
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet 192.168.56.0 netmask 255.255.255.0 {
  range 192.168.56.100 192.168.56.200;
  option routers 192.168.56.2;
  option subnet-mask 255.255.255.0;
}
subnet 192.168.57.0 netmask 255.255.255.0 {
  range 192.168.57.100 192.168.57.200;
  option routers 192.168.57.2;
  option subnet-mask 255.255.255.0;
}
subnet 192.168.58.0 netmask 255.255.255.0 {
  range 192.168.58.100 192.168.58.200;
  option routers 192.168.58.2;
  option subnet-mask 255.255.255.0;
}
subnet 192.168.59.0 netmask 255.255.255.0 {
}
EOF

systemctl enable isc-dhcp-server
systemctl start isc-dhcp-server || true
if ! systemctl is-active --quiet isc-dhcp-server; then
  echo "Warning: isc-dhcp-server failed to start. Check: systemctl status isc-dhcp-server"
  echo "  Try: vagrant ssh dhcpserver -c 'sudo systemctl start isc-dhcp-server'"
fi

# 56/57/58 宛はルータ (192.168.59.1) 経由で返す
ip route add 192.168.56.0/24 via 192.168.59.1 || true
ip route add 192.168.57.0/24 via 192.168.59.1 || true
ip route add 192.168.58.0/24 via 192.168.59.1 || true
