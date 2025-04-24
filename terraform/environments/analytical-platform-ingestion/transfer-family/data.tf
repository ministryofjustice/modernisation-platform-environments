# Shared VPC and Subnets
data "aws_vpc" "isolated" {
  tags = {
    "Name" = "${local.application_name}-${local.environment}-isolated"
  }
}

data "aws_subnets" "isolated_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.isolated.id]
  }
  tags = {
    Name = "${local.application_name}-${local.environment}-isolated-private*"
  }
}

data "aws_subnets" "isolated_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.isolated.id]
  }
  tags = {
    Name = "${local.application_name}-${local.environment}-isolated-public*"
  }
}

data "aws_subnet" "isolated_private_subnets_a" {
  vpc_id = data.aws_vpc.isolated.id
  tags = {
    "Name" = "${local.application_name}-${local.environment}-isolated-private-${data.aws_region.current.name}a"
  }
}

data "aws_subnet" "isolated_private_subnets_b" {
  vpc_id = data.aws_vpc.isolated.id
  tags = {
    "Name" = "${local.application_name}-${local.environment}-isolated-private-${data.aws_region.current.name}b"
  }
}

data "aws_subnet" "isolated_private_subnets_c" {
  vpc_id = data.aws_vpc.isolated.id
  tags = {
    "Name" = "${local.application_name}-${local.environment}-isolated-private-${data.aws_region.current.name}c"
  }
}
