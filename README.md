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

### giaddr（Gateway IP Address）について

DHCP リレーでは、**どのネットワーク向けの要求か**をサーバが判断するために **giaddr** が使われます。

- **誰がセットするか**: リレーが、クライアントから受け取った DHCP パケットをサーバに転送するときに **giaddr を書き込む**。クライアント送信時点では giaddr は 0。
- **何が入るか**: リレーが持っている IP のうち、**クライアント側のインターフェースのアドレス**。上図なら、クライアント NW 側の 192.168.56.2 が giaddr になる。
- **サーバの使い方**: サーバは転送されてきたパケットの giaddr を見て、「この giaddr が属する subnet」の `subnet` ブロック（とその `range`）を選び、そこからアドレスを割り当てる。そのため、**どのセグメントのクライアントかは IP ではなく giaddr で識別される**（まだアドレスをもらっていないクライアントを IP では識別できないため）。

複数セグメント（例: 56.0/24, 57.0/24）がある場合も、各リレーがそれぞれのクライアント側 IF の IP を giaddr に付けるので、サーバは giaddr に応じて 56.x / 57.x を自動的に振り分けられる。

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

## 別構成の例: DHCP Server が複数 NIC で各セグメントに直結

次のように **DHCP Server が 56/57/58 の各ネットワークに直接つながっている**場合は、Relay を跨ぐ必要がなく、各セグメントごとに `subnet` を定義し、その NIC で listen すればよいです。

```
192.168.56.0/24    192.168.57.0/24    192.168.58.0/24
  Client1             Client2             Client3
  Relay1              Relay2              Relay3
  DHCP Server -------- DHCP Server -------- DHCP Server
  (eth1 .56.x)        (eth2 .57.x)        (eth3 .58.x)
```

### `/etc/default/isc-dhcp-server`

各セグメント用の NIC をすべて指定します。

```
INTERFACESv4="eth1 eth2 eth3"
INTERFACESv6=""
```

### `/etc/dhcp/dhcpd.conf` の例

各ネットワークに 1 つずつ `subnet` を書き、`option routers` はそのセグメントのリレー（またはデフォルトゲートウェイ）の IP にします。サーバは全セグメントに直結しているので、**スタティックルートの追加は不要**です。

```
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
```

- 各 `subnet` は「そのセグメントにいるクライアント向け」の定義。
- `option routers` はそのセグメントのゲートウェイ（ここでは Relay1=56.2, Relay2=57.2, Relay3=58.2 を想定）。

## 参考

- freepbx フォルダの Vagrantfile / Makefile をベースにしています。
# dhcp-relay
