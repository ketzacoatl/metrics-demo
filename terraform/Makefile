.PHONY: create-vpc-network plan apply depends generate-ssh-keypair generate-nomad-secret-keys generate-consul-secret-keys generate-consul-master-token scp-ssh-key ssh-bastion taint-core-leaders destroy

.DEFAULT_GOAL = help

## Use Terraform to create a VPC and network for the compute deployment
create-vpc-network:
	@terraform init
	@terraform plan -out=tf.out -target=module.vpc.module.public-subnets
	@terraform apply tf.out
	@terraform plan -out=tf.out -target=module.vpc.module.private-subnets
	@terraform apply tf.out
	@terraform plan -out=tf.out -target=module.vpc.module.public-gateway
	@terraform apply tf.out
	#@terraform plan -out=tf.out -target=module.vpc.module.nat-gateway
	#@terraform apply tf.out
	@rm -rf tf.out

## Use Terraform to review the plan and generate a tf.out file to apply
plan:
	@terraform init
	@terraform plan -out=tf.out

## Use Terraform to apply tf.out
apply:
	@terraform apply tf.out

## Use Terraform to destroy the VPC and all resources
destroy:
	@terraform init
	@terraform plan -destroy -out=tf.out
	@terraform apply tf.out

## rm -rf all state/data files (id_rsa, terraform.tfstate and tfvars)
clean:
	@rm -rf id_rsa id_rsa.pub
	@rm -rf terraform.tfstate terraform.tfstate.backup .terraform terraform.tfvars
	@rm -rf .terraform terraform.tfvars tf.out

## Generate secrets and other dependencies
depends: generate-ssh-keypair generate-nomad-secret-keys generate-consul-secret-keys generate-consul-master-token print-secret-help-msg
	@echo "success!"

## Echo instructions for how to use the secrets
print-secret-help-msg:
	@echo "Pick one secret from each of the sets listed above (eg, one nomad key, one consul key, etc)"

## Generate new ssh keypair
generate-ssh-keypair:
	@echo "generating SSH keypair"
	@ssh-keygen -t rsa -b 4096 -f $$PWD/id_rsa

## Generate Nomad Secret Key (3, you can pick one)
generate-nomad-secret-keys:
	@echo "generating secret keys for nomad (pick one)"
	@sudo docker run -it vancluever/nomad keygen
	@sudo docker run -it vancluever/nomad keygen
	@sudo docker run -it vancluever/nomad keygen

## Generate Consul Secret Key (3, you can pick one)
generate-consul-secret-keys:
	@echo "generating secret keys for consul (pick one)"
	@sudo docker run -it --entrypoint /bin/consul progrium/consul keygen
	@sudo docker run -it --entrypoint /bin/consul progrium/consul keygen
	@sudo docker run -it --entrypoint /bin/consul progrium/consul keygen

## Generate Master Token for Consul
generate-consul-master-token:
	@echo "generating master token for consul (pick one)"
	@python -c "import uuid; print uuid.uuid4()"
	@python -c "import uuid; print uuid.uuid4()"
	@python -c "import uuid; print uuid.uuid4()"

## scp SSH key to bastion host, so we can SSH to other hosts in the deployment
scp-ssh-key:
	@scp -i id_rsa id_rsa ubuntu@$$(terraform output bastion_ip):~/.ssh/

## SSH key to bastion host
ssh-bastion:
	@ssh -i id_rsa ubuntu@$$(terraform output bastion_ip)

## Taint the leader instances
taint-core-leaders:
	@terraform taint -module core-leaders aws_instance.auto-recover

## Show help screen.
help:
	@echo "Please use \`make <target>' where <target> is one of\n\n"
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "%-30s %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)
