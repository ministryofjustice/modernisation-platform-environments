data "aws_caller_identity" "current" {}

data "aws_ami" "weblogic" {
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

data "aws_ec2_instance_type" "weblogic" {
  instance_type = var.instance_type
}

data "aws_route53_zone" "internal" {
  provider = aws.core-vpc

  name         = "${var.business_unit}-${var.environment}.modernisation-platform.internal."
  private_zone = true
}

# data "aws_route53_zone" "external" {
#   provider = aws.core-vpc

#   name         = "${var.business_unit}-${var.environment}.modernisation-platform.service.justice.gov.uk."
#   private_zone = false
# }

# temporarily using az.justice.gov.uk
data "aws_route53_zone" "external" {
  name         = "modernisation-platform.nomis.az.justice.gov.uk."
  private_zone = false
}

locals {
  # region = substr(var.availability_zone, 0, length(var.availability_zone) - 1)
  ebs_optimized    = data.aws_ec2_instance_type.weblogic.ebs_optimized_support == "unsupported" ? false : true
  block_device_map = { for bdm in data.aws_ami.weblogic.block_device_mappings : bdm.device_name => bdm }
  root_device_size = one([for bdm in data.aws_ami.weblogic.block_device_mappings : bdm.ebs.volume_size if bdm.device_name == data.aws_ami.weblogic.root_device_name])

  # Auto-scaling group related locals
  initial_lifecycle_hook_name = "weblogic-${var.name}-ready-hook"
  auto_scaling_group_name     = "weblogic-${var.name}"
}