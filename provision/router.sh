#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

# ルーティング有効化（56/57/58/59 間の転送）
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-ipforward.conf
sysctl -p /etc/sysctl.d/99-ipforward.conf
