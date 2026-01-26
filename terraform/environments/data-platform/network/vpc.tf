resource "aws_vpc" "main" {
  cidr_block                           = local.network_configuration.vpc.cidr_block
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  enable_network_address_usage_metrics = true

  tags = {
    Name = "${local.application_name}-${local.environment}"
  }
}

resource "aws_vpc_encryption_control" "main" {
  vpc_id = aws_vpc.main.id
  mode   = "monitor"
}

resource "aws_vpc_ipv4_cidr_block_association" "additional" {
  for_each = try(local.network_configuration.vpc.additional_cidr_blocks, {})

  vpc_id     = aws_vpc.main.id
  cidr_block = each.value.cidr_block
}
