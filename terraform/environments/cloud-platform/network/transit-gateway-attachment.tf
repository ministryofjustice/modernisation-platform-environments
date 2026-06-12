resource "aws_ec2_transit_gateway_vpc_attachment" "modernisation_platform" {
  count = contains(["cloud-platform-development"], terraform.workspace) ? 1 : 0
  subnet_ids         = resource.aws_subnet.tgw_private[*].id
  transit_gateway_id = "tgw-053d9dd7f1222a554"
  vpc_id             = module.cluster_vpc[0].vpc_id

  tags = local.tags
}


