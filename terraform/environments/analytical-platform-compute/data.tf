# VPC sources
data "aws_vpc" "apc" {
  tags = {
    "Name" = "${local.application_name}-${local.environment}"
  }
}

data "aws_subnets" "apc_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.apc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-${local.environment}-private*"]
  }
}
