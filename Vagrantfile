# -*- mode: ruby -*-
# vi: set ft=ruby -*-
#
# DHCP Relay 検証環境（3 セグメント + ルータ + DHCP Server）
# - 56.0: Client1, Relay1, Router
# - 57.0: Client2, Relay2, Router
# - 58.0: Client3, Relay3, Router
# - 59.0: Router, DHCP Server

Vagrant.configure("2") do |config|
  config.vm.box = "generic/debian12"
  config.vm.box_check_update = true

  # ---------------------------------------------------------------------------
  # Client1 (56.0)
  # ---------------------------------------------------------------------------
  config.vm.define "client1" do |vm|
    vm.vm.hostname = "linux-client1"
    vm.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
      vb.gui = false
    end
    vm.vm.network "private_network", ip: "192.168.56.10",
      virtualbox__intnet: "net56"
  end

  # ---------------------------------------------------------------------------
  # Relay1 (56.0) → ルータ経由で DHCP Server へ
  # ---------------------------------------------------------------------------
  config.vm.define "relay1" do |vm|
    vm.vm.hostname = "dhcp-relay1"
    vm.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
      vb.gui = false
    end
    vm.vm.network "private_network", ip: "192.168.56.2",
      virtualbox__intnet: "net56"
    vm.vm.provision "shell", path: "provision/relay1.sh"
  end

  # ---------------------------------------------------------------------------
  # Client2 (57.0)
  # ---------------------------------------------------------------------------
  config.vm.define "client2" do |vm|
    vm.vm.hostname = "linux-client2"
    vm.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
      vb.gui = false
    end
    vm.vm.network "private_network", ip: "192.168.57.10",
      virtualbox__intnet: "net57"
  end

  # ---------------------------------------------------------------------------
  # Relay2 (57.0)
  # ---------------------------------------------------------------------------
  config.vm.define "relay2" do |vm|
    vm.vm.hostname = "dhcp-relay2"
    vm.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
      vb.gui = false
    end
    vm.vm.network "private_network", ip: "192.168.57.2",
      virtualbox__intnet: "net57"
    vm.vm.provision "shell", path: "provision/relay2.sh"
  end

  # ---------------------------------------------------------------------------
  # Client3 (58.0)
  # ---------------------------------------------------------------------------
  config.vm.define "client3" do |vm|
    vm.vm.hostname = "linux-client3"
    vm.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
      vb.gui = false
    end
    vm.vm.network "private_network", ip: "192.168.58.10",
      virtualbox__intnet: "net58"
  end

  # ---------------------------------------------------------------------------
  # Relay3 (58.0)
  # ---------------------------------------------------------------------------
  config.vm.define "relay3" do |vm|
    vm.vm.hostname = "dhcp-relay3"
    vm.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
      vb.gui = false
    end
    vm.vm.network "private_network", ip: "192.168.58.2",
      virtualbox__intnet: "net58"
    vm.vm.provision "shell", path: "provision/relay3.sh"
  end

  # ---------------------------------------------------------------------------
  # Router (56, 57, 58, 59 の 4 セグメントに接続・Debian)
  # ---------------------------------------------------------------------------
  config.vm.define "router" do |vm|
    vm.vm.hostname = "router"
    vm.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
      vb.gui = false
    end
    vm.vm.network "private_network", ip: "192.168.56.1",
      virtualbox__intnet: "net56"
    vm.vm.network "private_network", ip: "192.168.57.1",
      virtualbox__intnet: "net57"
    vm.vm.network "private_network", ip: "192.168.58.1",
      virtualbox__intnet: "net58"
    vm.vm.network "private_network", ip: "192.168.59.1",
      virtualbox__intnet: "net59"
    vm.vm.provision "shell", path: "provision/router.sh"
  end

  # ---------------------------------------------------------------------------
  # DHCP Server (59.0 のみ)
  # ---------------------------------------------------------------------------
  config.vm.define "dhcpserver" do |vm|
    vm.vm.hostname = "dhcp-server"
    vm.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
      vb.gui = false
    end
    vm.vm.network "private_network", ip: "192.168.59.3",
      virtualbox__intnet: "net59"
    vm.vm.provision "shell", path: "provision/dhcp-server.sh"
  end
end
