#!/usr/bin/env bash
# Runs on every `vagrant up` / `vagrant reload` of network-hosts:
# names the two lab NICs and starts the containers.
set -euo pipefail

SRC=/tmp/network-hosts
DEST=/opt/network-hosts
TRUNK_MAC=08:00:27:ac:0e:03
WAN_MAC=08:00:27:ac:0e:02

# The Vagrantfile uploads this directory to /tmp on every run
if [ -d "$SRC" ]; then
    mkdir -p "$DEST"
    cp -r "$SRC"/. "$DEST"/
    rm -rf "$SRC"
fi

rename_nic() {
    local mac=$1 name=$2 current
    current=$(ip -o link | awk -v mac="$mac" '$2 !~ /@/ && tolower($0) ~ mac { sub(":", "", $2); print $2; exit }')
    if [ -z "$current" ]; then
        echo "No NIC with MAC $mac" >&2
        exit 1
    fi
    if [ "$current" != "$name" ]; then
        ip link set dev "$current" down
        ip link set dev "$current" name "$name"
    fi
}

rename_nic "$TRUNK_MAC" trunk0
rename_nic "$WAN_MAC" wan0

# Same names after a reboot, and no addresses: the VM itself must not be reachable
# on the lab networks, or it could route around pfSense
cat > /etc/netplan/60-lab-nics.yaml <<EOF
network:
  version: 2
  ethernets:
    trunk0:
      match: {macaddress: "$TRUNK_MAC"}
      set-name: trunk0
      dhcp4: false
      dhcp6: false
      accept-ra: false
      link-local: []
      optional: true
    wan0:
      match: {macaddress: "$WAN_MAC"}
      set-name: wan0
      dhcp4: false
      dhcp6: false
      accept-ra: false
      link-local: []
      optional: true
EOF
chmod 600 /etc/netplan/60-lab-nics.yaml

cat > /etc/sysctl.d/60-lab.conf <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
sysctl -q -p /etc/sysctl.d/60-lab.conf

for nic in trunk0 wan0; do
    ip addr flush dev "$nic"
    ip link set dev "$nic" up
done
# The NIC's own MAC filter drops replies to the macvlan containers' MACs (needs --nicpromisc3 allow-all too)
ip link set dev trunk0 promisc on

cd "$DEST"
docker compose up -d --remove-orphans

install -m 0644 lab-aliases.sh /etc/profile.d/lab-aliases.sh

docker compose ps --format 'table {{.Name}}\t{{.Status}}'
