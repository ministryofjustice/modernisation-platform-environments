locals {
  all_subnets = merge([
    for subnet_type, azs in local.environment_configuration.vpc_subnets : {
      for az, config in azs :
      "${subnet_type}-${az}" => merge(config, {
        type = subnet_type
        az   = az
      })
    }
  ]...)
}

resource "aws_subnet" "main" {
  for_each = local.all_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = "${data.aws_region.current.region}${each.value.az}"

  tags = {
    Name = "${local.application_name}-${local.environment}-${each.value.type}-${each.value.az}"
    Type = each.value.type
  }
}
