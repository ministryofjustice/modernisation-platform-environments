data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}*"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-public-${local.region}*"
  }
}
