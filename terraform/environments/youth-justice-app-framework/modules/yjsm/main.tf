#create keypair for ec2 instances
module "key_pair" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  key_name           = "yjsm-ec2-keypair"
  create_private_key = true

  tags = local.all_tags
}

resource "aws_ssm_parameter" "private_key" {
  #checkov:skip=CKV_AWS_337 TODO
  name        = "/ec2/keypairs/yjsm-private-key"
  description = "EC2 Private Key for yjsm-keypair"
  type        = "SecureString"
  value       = module.key_pair.private_key_pem

  tags = local.all_tags
}

data "template_file" "userdata" {
  template = file("${path.module}/ec2-userdata.tftpl")
  vars = {
    env         = var.environment
    environment = var.environment
    tags        = jsonencode(local.all_tags)
    project     = var.project_name
  }
}

resource "aws_instance" "yjsm" {
  ami                  = var.ami
  instance_type        = "t3a.xlarge"
  key_name             = module.key_pair.key_pair_name
  monitoring           = true
  ebs_optimized        = true
  iam_instance_profile = aws_iam_instance_profile.yjsm_ec2_profile.id
  tags = merge(
    local.all_tags,
    { "OS" = "Linux" }
  )

  network_interface {
    network_interface_id = aws_network_interface.main.id
    device_index         = 0
  }


  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }


  root_block_device {
    encrypted             = true
    delete_on_termination = false
    volume_size           = 60
    volume_type           = "gp2"
  }

}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}

resource "aws_network_interface" "main" {
  subnet_id         = var.subnet_id
  private_ip        = var.private_ip
  private_ips_count = 1
  security_groups   = [aws_security_group.yjsm_service.id]
}
