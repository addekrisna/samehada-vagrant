Vagrant.configure("2") do |config|

  config.vm.define "node1" do |node1|
    node1.vm.hostname = "node1"
    node1.vm.provision :shell, path: "install.sh"
    node1.vm.box = "ubuntu/bionic64"
    node1.vm.network "private_network",ip: "192.168.56.3"
      node1.vm.provider "virtualbox" do |v|
        v.memory = 1094
        v.cpus = 1
     end
  end




end
