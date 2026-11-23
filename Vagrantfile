
class VagrantPlugins::ProviderVirtualBox::Action::Network
    def dhcp_server_matches_config?(dhcp_server, config)
      true
    end
  end

BOX_CATALOG_URL = "https://moustafamariam.github.io/cs-e4300-netsec/boxes"

Vagrant.configure("2") do |config|

    if Vagrant.has_plugin?("vagrant-vbguest")
        config.vbguest.auto_update = false
    end

    # The WAN side of the lab: a VirtualBox NAT network
    # Runs before either VM comes up, since both are attached to it.
    config.trigger.before :up do |trigger|
        trigger.info = "Creating isp-network"
        trigger.run = {inline: "VBoxManage natnetwork add --dhcp off --netname isp-network --network 100.97.252.0/24"}
        trigger.on_error = :continue
    end
    config.trigger.before :up do |trigger|
        trigger.info = "Disabling DHCP on isp-network"
        trigger.run = {inline: "VBoxManage natnetwork modify --dhcp off --netname isp-network"}
        trigger.on_error = :continue
    end

    config.vm.define "pfsense" do |pfsense|
        pfsense.vm.guest = :freebsd
        pfsense.vm.box = "cs-e4300/router-pfsense"
        pfsense.vm.box_url = "#{BOX_CATALOG_URL}/metadata-router-pfsense.json"
        pfsense.ssh.shell = "sh"
        pfsense.ssh.insert_key = false
        pfsense.vm.synced_folder '.', '/vagrant', disabled: true
        # to access pfSense on https://localhost:8080 or https://127.0.0.1:8080/
        pfsense.vm.network :forwarded_port, guest: 443, host: 8080, host_ip: "127.0.0.1"

        # NIC2 (em1): WAN
        pfsense.vm.network "private_network",
            auto_config: false,
            virtualbox__intnet: "isp-placeholder"

        # NIC3 (em2): 802.1Q trunk to network-hosts, carrying VLANs 14-18
        pfsense.vm.network "private_network",
            auto_config: false,
            virtualbox__intnet: "company-trunk"

        pfsense.vm.provider "virtualbox" do |vb|
            vb.name = "cs-e4300-pfsense"
            vb.memory = 1024
            # Intel PRO/1000, not virtio: VLAN tagging and macvlan both rely on it
            vb.default_nic_type = "82540EM"
            vb.customize ["modifyvm", :id, "--nic2", "natnetwork", "--nat-network2", "isp-network"]
            vb.customize ["modifyvm", :id, "--groups", "/company_network"]
        end

        pfsense.trigger.after :destroy do |trigger|
            trigger.info = "Removing isp-network after destroying pfsense VM"
            trigger.run = {inline: "VBoxManage natnetwork remove --netname isp-network"}
            trigger.on_error = :continue
        end

        # Provisioning:
        pfsense.vm.provision "file",
            source: "./provisions/pfsense/config.xml",
            destination: "/tmp/config.xml"
        # vagrant cannot transfer directly to location, so the temp location is chosen
        pfsense.vm.provision "shell",
            inline: "mv /tmp/config.xml /cf/conf/config.xml"
        # reboot so pfSense starts with the new configuration
        pfsense.vm.provision "shell",
            inline: "sudo /etc/rc.reboot "
    end

    # One VM that runs every end host of the topology as a Docker container
    # (pc1, llm-server, agent-runner, printer, proxy, remote-user). See provisions/network-hosts/compose.yaml.
    config.vm.define "network-hosts" do |hosts|
        hosts.vm.box = "cs-e4300/network-hosts"
        hosts.vm.box_url = "#{BOX_CATALOG_URL}/metadata-network-hosts.json"
        hosts.vm.hostname = "network-hosts"
        hosts.vm.synced_folder '.', '/vagrant', disabled: true

        # NIC2: WAN side (isp-network), parent of remote-user.
        # The MACs are fixed so provision.sh can rename the NICs to wan0 and trunk0.
        hosts.vm.network "private_network",
            auto_config: false,
            virtualbox__intnet: "isp-placeholder",
            mac: "080027AC0E02"

        # NIC3: 802.1Q trunk to pfsense
        hosts.vm.network "private_network",
            auto_config: false,
            virtualbox__intnet: "company-trunk",
            mac: "080027AC0E03"

        hosts.vm.provider "virtualbox" do |vb|
            vb.name = "cs-e4300-network-hosts"
            vb.cpus = 1
            vb.memory = 1536
            vb.default_nic_type = "82540EM"
            vb.customize ["modifyvm", :id, "--nic2", "natnetwork", "--nat-network2", "isp-network"]
            # promisc required for macvlan driver
            vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
            vb.customize ["modifyvm", :id, "--groups", "/company_network"]
        end

        hosts.vm.provision "file",
            source: "./provisions/network-hosts",
            destination: "/tmp/network-hosts",
            run: "always"
        hosts.vm.provision "shell",
            path: "./provisions/network-hosts/provision.sh",
            run: "always"
    end

end
