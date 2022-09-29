data "aws_caller_identity" "current" {}

data "aws_vpc" "shared_vpc" {
  tags = {
    Name = "${var.business_unit}-${var.environment}"
  }
}

data "aws_subnet" "this" {
  tags = {
    Name = "${var.business_unit}-${var.environment}-${var.subnet_set}-${var.subnet_name}-${var.availability_zone}"
  }
}

data "aws_ami" "this" {
  most_recent = true
  owners      = [var.ami_owner]
  tags = {
    is-production = true # based on environment
  }

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_route53_zone" "internal" {
  provider = aws.core-vpc

  name         = "${var.business_unit}-${var.environment}.modernisation-platform.internal."
  private_zone = true
}

data "aws_route53_zone" "external" {
  provider = aws.core-vpc

  name         = "${var.business_unit}-${var.environment}.modernisation-platform.service.justice.gov.uk."
  private_zone = false
}

data "aws_ec2_instance_type" "database" {
  instance_type = var.instance.instance_type
}

data "cloudinit_config" "this" {
  count = length(try(var.user_data.templates, {})) > 0 ? 1 : 0
  dynamic "part" {
    for_each = try(var.user_data.templates, {})
    content {
      content_type = "text/cloud-config"
      merge_type   = "list(append)+dict(recurse_list)+str(append)"
      content = yamlencode({
        write_files = [
          {
            encoding    = "b64"
            content     = base64encode(templatefile("templates/${part.key}", merge(local.user_data_args, try(part.value.args, {}))))
            path        = part.value.path
            owner       = part.value.owner
            permissions = part.value.permissions
          }
        ]
      })
    }
  }
}
