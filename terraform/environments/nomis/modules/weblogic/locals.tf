data "aws_caller_identity" "current" {}

data "aws_ami" "this" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ec2_instance_type" "this" {
  instance_type = var.instance_type
}

locals {
  # region = substr(var.availability_zone, 0, length(var.availability_zone) - 1)
  ebs_optimized = data.aws_ec2_instance_type.this.ebs_optimized_support == "unsupported" ? false : true
  block_device_map    = { for bdm in data.aws_ami.this.block_device_mappings : bdm.device_name => bdm }
  root_device_size    = one([for bdm in data.aws_ami.this.block_device_mappings : bdm.ebs.volume_size if bdm.device_name == data.aws_ami.this.root_device_name])
}