resource "aws_subnet" "transit_gateway" {
  for_each = local.environment == "production" ? toset(local.wssb_supported_az_names) : toset([])

  vpc_id            = module.vpc[0].vpc_id
  cidr_block        = local.environment_configuration.vpc_transit_gateway_subnets[index(local.wssb_supported_az_names, each.key)]
  availability_zone = each.value

  tags = merge(
    local.tags,
    {
      Name = "${local.vpc_name}-${local.environment}-secure-browser-transit-gateway-${each.value}"
      Type = "transit-gateway"
    }
  )
}
