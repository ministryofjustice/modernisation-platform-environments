resource "aws_ec2_transit_gateway_vpc_attachment" "modernisation_platform" {
  count              = contains(["cloud-platform-development"], terraform.workspace) ? 1 : 0
  subnet_ids         = resource.aws_subnet.tgw_private[*].id
  transit_gateway_id = "tgw-053d9dd7f1222a554"
  vpc_id             = module.cluster_vpc[0].vpc_id

  tags = local.tags
}

resource "aws_route" "private_subnet_to_transit_gateway" {
  count = contains(["cloud-platform-development"], terraform.workspace) ? length(module.cluster_vpc[0].private_route_table_ids) : 0

  route_table_id         = module.cluster_vpc[0].private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = "tgw-053d9dd7f1222a554"
}


