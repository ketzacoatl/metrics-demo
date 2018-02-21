variable "name" {
  description = "name of the project, use as prefix to names of resources created"
  default     = "metrics-poc"
}

variable "region" {
  description = "Region where the project will be deployed"
  default = "us-east-2"
}

variable "ssh_pubkey" {
  description = "File path to SSH public key"
  default     = "./id_rsa.pub"
}

variable "ssh_key" {
  description = "File path to SSH public key"
  default     = "./id_rsa"
}

variable "ami" {
  description = "default AMI, FPCO build for SOA-driven infrastructure"
  default     = "ami-9e0fb2e6"
}

variable "instance_type" {
  description = "map of roles and instance types (VM sizes)"
  default     = {
    "bastion" = "t2.nano"
    "leaders" = "t2.micro"
    "workers" = "t2.small"
  }
}

variable "public_subnet_cidrs" {
  description = "A list of public subnet CIDRs to deploy inside the VPC"
  default     = ["10.23.11.0/24", "10.23.12.0/24", "10.23.13.0/24"]
}

variable "private_subnet_cidrs" {
  description = "A list of private subnet CIDRs to deploy inside the VPC"
  default     = ["10.23.21.0/24", "10.23.22.0/24", "10.23.23.0/24"]
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  default     = "10.23.0.0/16"
}

variable "consul_secret_key" {
  description = "maps to Consul's secret key config parameter"
  type        = "string"
}

variable "consul_master_token" {
  description = "master token (UUID) for consul's ACL system"
  type        = "string"
}

variable "nomad_secret" {
  description = "secret key to secure inter-cluster communication"
  type        = "string"
}
