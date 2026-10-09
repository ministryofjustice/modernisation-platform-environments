# Keyed by availability zone rather than by route table ID, because route table
# IDs are unknown at plan time whenever a new availability zone is added.
module "transit_gateway_routes" {
  for_each = {
    for index, availability_zone in local.availability_zones :
    availability_zone => module.vpc.private_route_table_ids[index]
  }

  source = "./modules/routes"

  route_table_id          = each.value
  destination_cidr_blocks = local.environment_configuration.transit_gateway_routes
  transit_gateway_id      = data.aws_ec2_transit_gateway.moj_tgw.id
}
