#!/bin/bash

set -x

${init_prefix}

# create a unique hostname
HN_PREFIX="${hostname_prefix}"
INSTANCE_ID="`ec2metadata --instance-id`"
HOSTNAME="$$HN_PREFIX-$$INSTANCE_ID"
hostnamectl set-hostname $$HOSTNAME

# write out bootstrap.sls
cat <<EOT >> ${bootstrap_pillar_file}
# pillar for hostname updates
hostname: $$HOSTNAME

# pillar for consul.service formula
consul:
  datacenter: ${consul_datacenter}
  disable_remote_exec: ${consul_disable_remote_exec}
  secret_key: '${consul_secret_key}'
  client_token: '${consul_client_token}'
  leaders:
    - ${consul_leader_ip}

# pillar for nomad.service formula
nomad:
  datacenter: ${nomad_datacenter}
  region: ${nomad_region}
  secret: ${nomad_secret}
  consul:
    token: ${consul_client_token}
  node_class: ${nomad_node_class}
  options:
    'driver.raw_exec.enable': 1
EOT

echo "role: workers" > /etc/salt/grains

echo "${log_prefix} ensure all pieces have the new hostname"
salt-call --local state.sls hostname,salt.minion

echo "${log_prefix} restart dnsmasq to be sure it is online"
service dnsmasq restart

echo "${log_prefix} apply the consul.service salt formula to run the agent"
salt-call --local state.sls consul.service --log-level=${log_level}

echo "${log_prefix} apply the nomad.service salt formula to run the agent"
salt-call --local state.sls nomad
salt-call --local state.sls nomad.consul_check_agent --log-level=${log_level}

echo "${log_prefix} apply the docker.registry.systemd salt formula to run Docker Registry"
salt-call --local state.sls docker.registry.systemd $VERBOSE

# hack this for the moment..
rm -rf /home/consul/conf.d/consul_template_service.json

# hashi-ui
ufw allow 3000
# nomad-exporter
ufw allow 9172
# cadvisor
ufw allow 9111
# node_exporter
ufw allow 9100
# prometheus
ufw allow 9090
# consul-exporter
ufw allow 9107

# setup a demo of some kind..
#git clone https://github.com/ketzacoatl/explore-openresty
#cd explore-openresty/demo
#make build

