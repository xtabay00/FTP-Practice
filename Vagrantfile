# -*- mode: ruby -*-
# FTP Practice -- Antonia Sáez Camacho

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bullseye64"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "256"
    vb.linked_clone = true
  end

  config.vm.define "ftp" do |ftp|
    ftp.vm.hostname = "ftp"
    ftp.vm.network :private_network, ip: "192.168.57.20"
    ftp.vm.network :private_network, ip: "192.168.57.30"
    ftp.vm.provision "shell", path: "provision-ftp.sh"
  end

  config.vm.define "dns" do |dns|
    dns.vm.hostname = "dns"
    dns.vm.network :private_network, ip: "192.168.57.10"
    dns.vm.provision "shell", path: "provision-dns.sh"
  end
end