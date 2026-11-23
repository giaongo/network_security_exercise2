###### CS-E4300 Network Security, Aalto University


*) _Note: Only install the GPLv3-licensed version of VirtualBox. Do not download the proprietary extension pack. Oracle states that it is free for personal and educational use, but that is just a legal trap. The Oracle lawyers will claim that it was downloaded for some other use._


## Network Setup

The lab runs as two virtual machines:

- `pfsense`: the router/firewall that you configure
- `network-hosts`: runs every other host of the company network, and the remote user, as a Docker container

You need a Windows or Linux PC with an amd64 processor and about 3 GB of free memory.

1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads) 7.2.22 and [Vagrant](https://developer.hashicorp.com/vagrant/install) 2.4.9.

The project has been tested with Vagrant 2.4.9 and VirtualBox 7.2.22. If Vagrant says that your VirtualBox version is not supported, install the latest Vagrant version.


2. Add VirtualBox to your PATH if your PC is not recognizing the `VBoxManage` command. `VBoxManage` is needed to create the external NAT network. 


3. Start the lab in this directory (where the Vagrantfile is located):

```bash
vagrant up
```

The first run of the above command downloads the two VM images (about 2 GB) and takes a while. Later runs are faster. 

### Useful Vagrant commands

Initialize a specific VM:

```bash
vagrant up [vm]
```

SSH into VM:

```bash
vagrant ssh [vm]
```

Halt and restart one VM or all VMs:

```bash
vagrant halt [vm]
vagrant up [vm]
```

Start from the beginning by destroying and recreating the VMs. *Be careful that configurations are reset when you destroy the VMs. Do not rely on any VM state that is lost during VM restart or reset!*

```bash
vagrant destroy -f
vagrant up
```

Destroy and recreate one VM or all VMs:

```bash
vagrant destroy [vm]
vagrant up [vm]
```

**Note:**
- The VMs in the network are `pfsense` and `network-hosts`.
- It may take `pfsense` a few minutes to boot up. The VM will display a welcome message when `pfsense` starts. Once the machine is booted you can access the web interface at https://localhost:8080. The username and password for the interface are *admin* and *cse4300*.
- The order of destroying the VMs on the external interface matters. You should destroy the `network-hosts` VM before destroying `pfsense`.

## Network topology

| Zone | Subnet | pfSense interface | Host |
|---|---|---|---|
| Users | 10.14.0.0/24 | USERS, 10.14.0.1 | `pc1` |
| AI Control | 10.15.0.0/24 | AI_CONTROL, 10.15.0.1 | `llm-server`, 10.15.0.10 |
| AI Sandbox | 10.16.0.0/24 | AI_SANDBOX, 10.16.0.1 | `agent-runner` |
| Facilities | 10.17.0.0/24 | FACILITIES, 10.17.0.1 | `printer` |
| DMZ | 10.18.0.0/24 | DMZ, 10.18.0.1 | `proxy`, 10.18.0.10 |
| Internet | 100.97.252.0/24 | WAN, 100.97.252.10 | `remote-user` |

## Using the hosts

Log in to the VM that runs the hosts, then type a host's name to get a shell on it:

```bash
vagrant ssh network-hosts
pc1
```

The host names are `pc1`, `llm-server`, `agent-runner`, `printer`, `proxy` and `remote-user`. `exit` takes you back to the VM.

Typing a host's name is a shortcut for `docker exec`. After `vagrant ssh network-hosts`, you can also open a host with:

```bash
docker exec -it pc1 bash
```

You can also open a host directly from your PC:

```bash
vagrant ssh network-hosts -c "docker exec -it pc1 bash"
```

Each host has `nc`, `ping`, `curl`, `tcpdump`, `traceroute`, `dig`, `ip` and `ssh`. For example, to test a connection from pc1 to llm-server:

```bash
llm-server> nc -l 443
pc1>        nc 10.15.0.10 443
```

The hosts are reset when the `network-hosts` VM is destroyed. Do not keep anything important on them.


## What should you modify?

You should create firewall rules that satisfy the high-level policies provided in the exercise description.

The username and password for the [pfSense web interface](https://localhost:8080) are *admin* and *cse4300*.


Background (not part of the task): the lab uses VLANs, which you learned about in the lectures. All five internal zones share one trunk link to pfSense, as VLANs 14 to 18. The VLAN ID is the same as the second number of the subnet, for example, VLAN 14 is 10.14.0.0/24. In pfSense, they appear as `em2.14` … `em2.18`, assigned to the interfaces USERS … DMZ. This is often how companies connect many networks to one firewall. The VLANs are already configured, and you can treat each VLAN as a separate interface.

 You do not need to set up any interfaces on the router or modify the `network-hosts` VM, just add the rules corresponding to the high-level policy.

## Submitting your solution

You can download your new firewall configuration from the pfSense web interface:

`Diagnostics > Backup & Restore > Download configuration as XML`

Please submit the XML file as: `lastname_firstname.xml`
