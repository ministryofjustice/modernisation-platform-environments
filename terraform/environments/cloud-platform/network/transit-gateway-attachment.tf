resource "aws_ec2_transit_gateway_vpc_attachment" "modernisation_platform" {
  subnet_ids         = resource.aws_subnet.tgw_private[*].id
  transit_gateway_id = "tgw-053d9dd7f1222a554"
  vpc_id             = module.cluster_vpc.vpc_id

  tags = local.tags
}

resource "aws_route" "private_subnet_to_transit_gateway" {
  count                  = length(module.cluster_vpc.private_route_table_ids)
  route_table_id         = module.cluster_vpc.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = "tgw-053d9dd7f1222a554"
}
