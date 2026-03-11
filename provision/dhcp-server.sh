#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y isc-dhcp-server

# ネットワーク付与を待ってからNICを検出（Vagrant が eth1/enp0s8 等に割り当て）
sleep 3
SERVER_IF=$(ip -o -4 addr show | grep "192.168.57" | awk '{print $2}' | head -1)
if [ -z "$SERVER_IF" ]; then
  # フォールバック: デフォルトルートでない方のインターフェース（2番目）
  SERVER_IF=$(ip -o -4 addr show | awk '{print $2}' | grep -v "^lo$" | tail -n +2 | head -1)
fi
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
# 起動失敗時は無視（次回 reboot や手動 start で対処可能）
systemctl start isc-dhcp-server || true
if ! systemctl is-active --quiet isc-dhcp-server; then
  echo "Warning: isc-dhcp-server failed to start. Check: systemctl status isc-dhcp-server"
  echo "  Interface may not be ready yet. Try: vagrant ssh dhcpserver -c 'sudo systemctl start isc-dhcp-server'"
fi

# クライアントNW (192.168.56.0/24) への戻り経路を追加
# Relay (192.168.57.2) が 192.168.56.0/24 を担当しているため、
# DHCP Server からクライアントへのユニキャスト応答が正しく返るようにする。
ip route add 192.168.56.0/24 via 192.168.57.2 || true
