# Look up existing VPC and subnets by tags — no remote state dependency needed.

locals {
  vpc_name = "cloud-platform-development" # Matches the VPC name tag from network/vpc.tf
}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [local.vpc_name]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  tags = {
    SubnetType = "Private"
  }
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

data "aws_subnets" "pod_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  tags = {
    SubnetType = "pod-private"
  }
}

data "aws_subnet" "pod_private" {
  for_each = toset(data.aws_subnets.pod_private.ids)
  id       = each.value
}
