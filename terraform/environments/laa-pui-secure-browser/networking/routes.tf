resource "aws_route" "transit_gateway_routes" {
  for_each = local.environment == "production" ? {
    for pair in setproduct(module.vpc[0].private_route_table_ids, local.environment_configuration.transit_gateway_routes) :
    "${pair[0]}-${pair[1]}" => {
      route_table_id = pair[0]
      cidr_block     = pair[1]
    }
  } : {}

  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.cidr_block
  transit_gateway_id     = data.aws_ec2_transit_gateway.moj_tgw.id
}
