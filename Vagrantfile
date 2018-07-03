# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  proxy = ENV['HTTP_PROXY']

  (1..2).each do |i|
      config.vm.define "lxc#{i}" do |host|
        host.vm.box = "ubuntu/bionic64"
        host.vm.network "private_network", ip: "192.168.1.#{i+1}", auto_config: false, virtualbox__intnet: "lxc2to3"
        host.vm.hostname = "lxc#{i}"
        host.vm.provision :shell, path: "setup_lxc.sh", env: { "HTTP_PROXY" => proxy }
        host.vm.provision "puppet" do |puppet|
          puppet.module_path = "puppet/modules"
          puppet.manifests_path = "puppet/manifests"
        end
      end
      config.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
        v.memory = 8192
        v.cpus = 4
      end
  end
  (1..2).each do |i|
      config.vm.define "lxd#{i}" do |host|
        host.vm.box = "ubuntu/bionic64"
        host.vm.network "private_network", ip: "10.10.0.#{i+1}", virtualbox__intnet: "mgmtlxd2to3"
        host.vm.network "private_network", ip: "192.168.1.#{i+1}", auto_config: false, virtualbox__intnet: "lxd2to3"
        host.vm.hostname = "lxd#{i}"
        host.vm.provision :shell, path: "setup_lxd.sh", env: { "HTTP_PROXY" => proxy }
      end
      config.vm.provider "virtualbox" do |v|
        # Strictly speaking mgmtlxd2to3 doesn't really need promisc, but do it
        # anyway
        v.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
        v.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
        v.memory = 8192
        v.cpus = 4
      end
  end
end
