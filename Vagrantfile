# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  (1..4).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.box = "ubuntu-16.04"
      node.vm.hostname="node#{i}"
      node.vm.network "private_network", ip: "192.168.59.1#{i}"
      node.vm.synced_folder "./share", "/home/ubuntu/share"
      node.vm.provider "virtualbox" do |v|
        v.name = "node#{i}"
        v.memory = 2048
        v.cpus = 1
      end
      node.vm.provision "shell", inline: <<-SHELL
        sudo su -c "cat /home/ubuntu/share/sources.list > /etc/apt/sources.list"
        sudo su -c "cat /home/ubuntu/share/authorized_keys >> /home/ubuntu/.ssh/authorized_keys"
        sudo apt-get update
        sudo apt-get -y install openjdk-8-jre
        sudo apt-get -y install python-minimal python2.7
      SHELL
    end
  end
end
