# DHCP Relay 検証環境

Vagrant で「Linux Client / DHCP Relay / DHCP Server」を 2 セグメントに分けた構成を再現します。

## 構成の考え方

- **Linux Client** と **DHCP Relay** は **同一 NW**（192.168.56.0/24）
- **DHCP Server** は **別 NW**（192.168.57.0/24）
- Relay が 2 つの NW にまたがり、クライアントの DHCP 要求をサーバへ中継する「あるべき形」の構成です（RFC 1542 等で規定される一般的な DHCP Relay の使い方です）。

```
[ 192.168.56.0/24 ]              [ 192.168.57.0/24 ]
  Linux Client                      DHCP Server
  192.168.56.10                     192.168.57.3
        |                                    ^
        | (DHCP broadcast)                    | (unicast)
        v                                    |
  DHCP Relay  -------- 192.168.56.2  192.168.57.2 -------
```

## 必要なもの

- VirtualBox
- Vagrant

## 使い方

```bash
# 全 VM 起動（初回は box 取得とプロビジョニングで時間がかかります）
make up
# または
vagrant up

# 各マシンに SSH
make ssh-client    # vagrant ssh client
make ssh-relay     # vagrant ssh relay
make ssh-dhcpserver # vagrant ssh dhcpserver

# 停止
make down
```

## DHCP 取得のテスト（Client 側）

Client は起動時は 192.168.56.10 の静的 IP です。Relay 経由で DHCP を取得するテストをする場合:

```bash
vagrant ssh client
# クライアントNWのインターフェース名を確認（例: eth1 や enp0s8）
ip -4 addr show
# 静的IPをパージしてから DHCP 取得（例: eth1 の場合）
sudo ip addr flush dev eth1
sudo dhclient -v eth1
# 192.168.56.100〜200 の範囲でアドレスが取れれば成功
```

補足: `ip addr flush dev eth1` でインターフェースから静的アドレス（192.168.56.10）を削除します。`dhclient -r` は DHCP リースの解放のみで、Vagrant が付与した静的IPは残るため、flush してから dhclient するのが確実です。

## 参考

- freepbx フォルダの Vagrantfile / Makefile をベースにしています。
# dhcp-relay
