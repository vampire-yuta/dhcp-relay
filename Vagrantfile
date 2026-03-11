# -*- mode: ruby -*-
# vi: set ft=ruby -*-
#
# DHCP Relay 検証環境
# - Linux Client と Relay が同一NW（192.168.56.0/24）
# - DHCP Server は別NW（192.168.57.0/24）
# - Relay が2つのNWにまたがり中継

Vagrant.configure("2") do |config|
  config.vm.box = "generic/debian12"
  config.vm.box_check_update = true

  # ---------------------------------------------------------------------------
  # Linux Client（DHCPでIPを取得する側）
  # ---------------------------------------------------------------------------
  config.vm.define "client" do |client|
    client.vm.hostname = "linux-client"
    client.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
      vb.gui = false
    end
    # クライアントNWのみ（Relayと同じセグメント）
    # 検証時は静的IP。DHCP取得テストは client で sudo dhclient <iface> で可能
    client.vm.network "private_network", ip: "192.168.56.10",
      virtualbox__intnet: "dhcp-client-net"
  end

  # ---------------------------------------------------------------------------
  # DHCP Relay Server（クライアントNWとサーバNWの両方に接続）
  # ---------------------------------------------------------------------------
  config.vm.define "relay" do |relay|
    relay.vm.hostname = "dhcp-relay"
    relay.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
      vb.gui = false
    end
    # クライアント側NW（Clientと同じセグメント）
    relay.vm.network "private_network", ip: "192.168.56.2",
      virtualbox__intnet: "dhcp-client-net"
    # サーバ側NW（DHCP Serverと同じセグメント）
    relay.vm.network "private_network", ip: "192.168.57.2",
      virtualbox__intnet: "dhcp-server-net"
    relay.vm.provision "shell", path: "provision/relay.sh"
  end

  # ---------------------------------------------------------------------------
  # DHCP Server（別NW、Relay経由でクライアントに応答）
  # ---------------------------------------------------------------------------
  config.vm.define "dhcpserver" do |dhcpserver|
    dhcpserver.vm.hostname = "dhcp-server"
    dhcpserver.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
      vb.gui = false
    end
    # サーバNWのみ（Relayの2枚目NICと同じセグメント）
    dhcpserver.vm.network "private_network", ip: "192.168.57.3",
      virtualbox__intnet: "dhcp-server-net"
    dhcpserver.vm.provision "shell", path: "provision/dhcp-server.sh"
  end
end
