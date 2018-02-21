module "vpc" {
  source      = "ketzacoatl/fpc-ops/aws//modules/vpc-scenario-2"
  version     = "0.7.0-rc2"
  name_prefix = "${var.name}"
  region      = "${var.region}"
  cidr        = "${var.vpc_cidr}"
  azs         = ["${slice(data.aws_availability_zones.available.names, 0, 3)}"]
  extra_tags  = { demo = "monitoring", client = "vs" }
  public_subnet_cidrs  = ["${var.public_subnet_cidrs}"]
  private_subnet_cidrs = ["${var.private_subnet_cidrs}"]
}
