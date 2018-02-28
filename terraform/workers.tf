# Security Group for nomad workers
module "workers-sg" {
  source      = "ketzacoatl/fpc-ops/aws//modules/security-group-base"
  version     = "0.7.0-rc2"
  name        = "${var.name}-workers"
  description = "security group for worker instances in the private subnet"
  vpc_id      = "${module.vpc.vpc_id}"
}

module "workers-vpc-ssh-rule" {
  source            = "ketzacoatl/fpc-ops/aws//modules/ssh-sg"
  version           = "0.7.0-rc2"
  cidr_blocks       = ["${var.vpc_cidr}"]
  security_group_id = "${module.workers-sg.id}"
}

module "workers-open-egress-rule" {
  source            = "ketzacoatl/fpc-ops/aws//modules/open-egress-sg"
  version           = "0.7.0-rc2"
  security_group_id = "${module.workers-sg.id}"
}

module "workers-consul-agent-rule" {
  source            = "ketzacoatl/fpc-ops/aws//modules/consul-agent-sg"
  version           = "0.7.0-rc2"
  cidr_blocks       = ["${var.vpc_cidr}"]
  security_group_id = "${module.workers-sg.id}"
}

module "workers-nomad-agent-rule" {
  source            = "ketzacoatl/fpc-ops/aws//modules/nomad-agent-sg"
  version           = "0.7.0-rc2"
  cidr_blocks        = ["${var.vpc_cidr}"]
  security_group_id  = "${module.workers-sg.id}"
}

module "workers-nomad-app-ports-rule" {
  source            = "ketzacoatl/fpc-ops/aws//modules/nomad-agent-worker-ports-sg"
  version           = "0.7.0-rc2"
  cidr_blocks        = ["${var.vpc_cidr}"]
  security_group_id  = "${module.workers-sg.id}"
}

module "workers-hashi-ui-rule" {
  source            = "ketzacoatl/fpc-ops/aws//modules/single-port-sg"
  version           = "0.7.0-rc2"
  port              = "3000"
  description       = "allow ingress to hashi-ui on port 3000 (TCP)"
  cidr_blocks       = ["${var.vpc_cidr}"]
  security_group_id = "${module.workers-sg.id}"
}

module "workers-nomad-exporter-rule" {
  source            = "ketzacoatl/fpc-ops/aws//modules/single-port-sg"
  version           = "0.7.0-rc2"
  port              = "9172"
  description       = "allow ingress to nomad-exporter on port 9172 (TCP)"
  cidr_blocks       = ["${var.vpc_cidr}"]
  security_group_id = "${module.workers-sg.id}"
}

module "workers-consul-exporter-rule" {
  source            = "ketzacoatl/fpc-ops/aws//modules/single-port-sg"
  version           = "0.7.0-rc2"
  port              = "9107"
  description       = "allow ingress to consul-exporter on port 9107 (TCP)"
  cidr_blocks       = ["${var.vpc_cidr}"]
  security_group_id = "${module.workers-sg.id}"
}

module "workers-cadvisor-rule" {
  source            = "ketzacoatl/fpc-ops/aws//modules/single-port-sg"
  version           = "0.7.0-rc2"
  port              = "9111"
  description       = "allow ingress to cadvisor on port 9111 (TCP)"
  cidr_blocks       = ["${var.vpc_cidr}"]
  security_group_id = "${module.workers-sg.id}"
}

module "workers-node_exporter-rule" {
  source            = "ketzacoatl/fpc-ops/aws//modules/single-port-sg"
  version           = "0.7.0-rc2"
  port              = "9100"
  description       = "allow ingress to the node_exporter on port 9100 (TCP)"
  cidr_blocks       = ["${var.vpc_cidr}"]
  security_group_id = "${module.workers-sg.id}"
}

module "workers-prometheus-rule" {
  source            = "ketzacoatl/fpc-ops/aws//modules/single-port-sg"
  version           = "0.7.0-rc2"
  port              = "9090"
  description       = "allow ingress to prometheus on port 9090 (TCP)"
  cidr_blocks       = ["${var.vpc_cidr}"]
  security_group_id = "${module.workers-sg.id}"
}

#module "worker-hostname" {
#  source          = "github.com/fpco/fpco-terraform-aws//tf-modules/init-snippet-hostname-simple?ref=data-ops-eval"
#  hostname_prefix = "${var.name}-worker"
#}

data "template_file" "worker_user_data" {
  template = "${file("templates/worker-init.tpl")}"

  vars {
#   init_prefix = "${module.worker-hostname.init_snippet}"
    init_prefix = ""
    log_prefix  = "OPS-LOG: "
    log_level   = "info"

    # for managing the hostname
    hostname_prefix = "workers"

    # file path to bootstrap.sls pillar file
    bootstrap_pillar_file = "/srv/pillar/bootstrap.sls"

    # consul formula config params
    consul_disable_remote_exec = "true"
    consul_datacenter          = "${var.name}-${var.region}"
    consul_secret_key          = "${var.consul_secret_key}"
    consul_leader_ip           = "${data.template_file.core_leaders_private_ips.0.rendered}"

    # these tokens should live elsewhere, like in credstash
    consul_client_token = "${var.consul_master_token}"

    # nomad formula config params
    nomad_node_class = "compute"
    nomad_datacenter = "${var.name}.${var.region}"
    nomad_secret     = "${var.nomad_secret}"
    nomad_region     = "${var.region}"
  }
}

module "workers" {
  source      = "ketzacoatl/fpc-ops/aws//modules/asg"
  version     = "0.7.0-rc2"
  name_prefix = "${var.name}"
  name_suffix = "workers-${var.region}"
  key_name    = "${aws_key_pair.main.key_name}"
  ami         = "${var.ami}"

  ##iam_profile = ""
  instance_type    = "${var.instance_type["workers"]}"
  min_nodes        = "0"
  max_nodes        = "10"
  desired_capacity = "2"
  public_ip        = "false"
  subnet_ids       = ["${module.vpc.private_subnet_ids}"]
  # select availability zones based on private subnets in use
  azs = ["${slice(data.aws_availability_zones.available.names, 0, length(var.private_subnet_cidrs))}"]

  security_group_ids = ["${module.workers-sg.id}"]
  root_volume_size   = "30"
  user_data          = "${data.template_file.worker_user_data.rendered}"
}
