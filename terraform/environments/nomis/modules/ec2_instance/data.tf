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

data "template_file" "user_data" {
  template = file("${path.module}/user_data/ansible.sh.tftpl")
  vars = {
    branch               = var.branch == "" ? "main" : var.branch
    ansible_repo         = var.ansible_repo == null ? "" : var.ansible_repo
    ansible_repo_basedir = var.ansible_repo_basedir == null ? "" : var.ansible_repo_basedir
  }
}
