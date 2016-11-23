#!/usr/bin/env bash

INTERNAL_IP=$(ip -o -f inet addr show eth1 | awk '{print $4}' | cut -d/ -f1)
EXTERNAL_IP=$(ip -o -f inet addr show eth0 | awk '{print $4}' | cut -d/ -f1)

# Update package database
apt-get update
apt-get install -y unzip

# Install Consul and Nomad binaries
cd /usr/local/bin
# 5dbfc555352bded8a39c7a8bf28b5d7cf47dec493bc0496e21603c84dfe41b4b
wget "https://releases.hashicorp.com/consul/0.7.1/consul_0.7.1_linux_amd64.zip"
# 7f7b9af2b1ff3e2c6b837b6e95968415237bb304e1e82802bc42abf6f8645a43
wget "https://releases.hashicorp.com/nomad/0.5.0/nomad_0.5.0_linux_amd64.zip"
unzip consul_0.7.1_linux_amd64.zip
unzip nomad_0.5.0_linux_amd64.zip
rm *.zip

# Create users for Consul and Nomad services
adduser --system --group consul
adduser --system --group nomad

# Create Consul and Nomad directory structure
mkdir -p /etc/{consul.d,nomad.d}
mkdir -p /var/{consul,nomad}
chown consul:consul /var/consul
chown nomad:nomad /var/nomad

cd /home/consul
wget "https://releases.hashicorp.com/consul/0.7.1/consul_0.7.1_web_ui.zip"
unzip consul_0.7.1_web_ui.zip
rm consul_0.7.1_web_ui.zip
chown -R consul:consul /home/consul

# Consul config
cat << EOF > /etc/consul.d/server.json
{
    "server": true,
    "node_name": "%NODE_NAME%",
    "bootstrap": %BOOTSTRAP%,
    "datacenter": "%DC_NAME%",
    "data_dir": "/var/consul",
    "log_level": "INFO",
    "node_name": "%NODE_NAME%",
    "ui_dir": "/home/consul",
    "enable_syslog": true,
    "start_join": [%CONSUL_JOIN%],
    "bind_addr": "${INTERNAL_IP}",
    "client_addr": "0.0.0.0",
    "advertise_addr": "${INTERNAL_IP}"
}
EOF

# Consul upstart config
cat << EOF > /etc/init/consul.conf
description "Consul server process"

start on (local-filesystems and net-device-up IFACE=eth1)
stop on runlevel [!12345]

respawn

setuid consul
setgid consul

exec consul agent -config-dir /etc/consul.d
EOF

# Nomad server config
cat << EOF > /etc/nomad.d/server.hcl
name = "%NODE_NAME%"
bind_addr = "0.0.0.0"
data_dir = "/var/nomad"
region = "%REGION%"
datacenter = "%DC_NAME%"
enable_syslog = true

advertise {
        http = "${INTERNAL_IP}:4646"
        rpc = "${INTERNAL_IP}:4647"
        serf = "${INTERNAL_IP}:4648"
}

server {
        enabled = true
        bootstrap_expect = 1
}

consul {
        address = "127.0.0.1:8500"
}
EOF

# Nomad upstart config
cat << EOF > /etc/init/nomad.conf
description "Nomad server process"

start on (local-filesystems and net-device-up IFACE=eth1)
stop on runlevel [!12345]

respawn

setuid nomad
setgid nomad

exec nomad agent -config=/etc/nomad.d
EOF

start consul
sleep 5
start nomad

# To open Consul console:
# ssh -o StrictHostKeyChecking=no -NL 8500:localhost:8500 root@$(triton instance get nomad-server-1 | json -a ips.0) &
# open http://localhost:8500

# To use Nomad from local machine:
# brew install nomad
# ssh -o StrictHostKeyChecking=no -NL 4646:localhost:4646 root@$(triton instance get nomad-server-1 | json -a ips.0) &
# nomad server-members
