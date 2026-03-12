# DHCP Relay 検証環境

Vagrant で **3 セグメント（56/57/58）+ ルータ + DHCP Server（59.0）** の構成を再現します。各セグメントに Client と Relay がおり、ルータを経由して中央の DHCP Server と通信します。

## 構成の考え方

- **56.0/24**: Client1, Relay1, Router（1 本目）
- **57.0/24**: Client2, Relay2, Router（2 本目）
- **58.0/24**: Client3, Relay3, Router（3 本目）
- **59.0/24**: Router（4 本目）, DHCP Server

クライアントの DHCP ブロードキャストは同じセグメントのリレーが受け、リレーは DHCP サーバ (59.0) 宛にユニキャスト転送。ルータが 56/57/58 と 59 の間を転送し、サーバは 56/57/58 宛の応答をルータ経由で返します（RFC 1542 等の DHCP Relay の一般的な形）。

```
192.168.56.0/24    192.168.57.0/24    192.168.58.0/24    192.168.59.0/24
  Client1 .10          Client2 .10          Client3 .10          DHCP Server .3
  Relay1  .2           Relay2  .2           Relay3  .2               ^
      \                     \                     \                   |
       \_____________________\_____________________\______ Router _____/
                              .56.1   .57.1   .58.1   .59.1
```

### giaddr（Gateway IP Address）について

DHCP リレーでは、**どのネットワーク向けの要求か**をサーバが判断するために **giaddr** が使われます。

- **誰がセットするか**: リレーが、クライアントから受け取った DHCP パケットをサーバに転送するときに **giaddr を書き込む**。クライアント送信時点では giaddr は 0。
- **何が入るか**: リレーが持っている IP のうち、**クライアント側のインターフェースのアドレス**（例: Relay1 なら 192.168.56.2）。
- **サーバの使い方**: サーバは転送されてきたパケットの giaddr を見て、「この giaddr が属する subnet」の `subnet` ブロック（とその `range`）を選び、そこからアドレスを割り当てる。そのため、**どのセグメントのクライアントかは IP ではなく giaddr で識別される**（まだアドレスをもらっていないクライアントを IP では識別できないため）。

複数セグメント（56/57/58）がある場合も、各リレーがそれぞれのクライアント側 IF の IP を giaddr に付けるので、サーバは giaddr に応じて 56.x / 57.x / 58.x を自動的に振り分けます。

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
make ssh-client1     # vagrant ssh client1  (56.0)
make ssh-client2     # client2 (57.0)
make ssh-client3     # client3 (58.0)
make ssh-relay1      # relay1
make ssh-relay2      # relay2
make ssh-relay3      # relay3
make ssh-router      # ルータ（4 NIC）
make ssh-dhcpserver  # DHCP Server (59.0)

# 停止
make down
```

## DHCP 取得のテスト（Client 側）

各 Client は起動時は静的 IP（56.10 / 57.10 / 58.10）です。Relay → ルータ → DHCP Server 経由で DHCP を取得するテスト:

```bash
# 例: Client1 (56.0) で取得 → 192.168.56.100〜200 が取れれば成功
vagrant ssh client1
ip -4 addr show
sudo ip addr flush dev eth1
sudo dhclient -v eth1

# Client2 なら 57.100〜200、Client3 なら 58.100〜200 の範囲
```

補足: `ip addr flush dev eth1` でインターフェースから静的アドレスを削除してから `dhclient` すると確実です。`dhclient -r` だけでは Vagrant が付与した静的 IP は残ります。

## 別構成の例: DHCP Server が各セグメントに直結する場合

DHCP Server が 56/57/58 の各ネットワークに **直接** つながっている場合は、ルータは不要で、サーバの各 NIC で listen し、56/57/58 用の `subnet` を定義すればよいです。その場合は 56/57/58 宛のスタティックルートも不要です（本リポジトリの現在の構成は「ルータ経由で 59.0 にサーバ 1 台」です）。

## 参考

- freepbx フォルダの Vagrantfile / Makefile をベースにしています。
