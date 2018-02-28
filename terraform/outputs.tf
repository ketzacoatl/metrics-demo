//IP of Bastion host in public subnet
output "bastion_ip" {
  value = "${aws_instance.bastion.public_ip}"
}

//The list of IP addresses for the leaders on EC2
output "leader_ips" {
  value = ["${data.template_file.core_leaders_private_ips.*.rendered}"]
}
