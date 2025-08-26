module "transit_gateway_routes" {
  for_each = toset(module.vpc.private_route_table_ids)


  source = "./modules/routes"

  route_table_id          = each.value
  destination_cidr_blocks = local.environment_configuration.transit_gateway_routes
  transit_gateway_id      = data.aws_ec2_transit_gateway.moj_tgw.id
}
