resource "aws_ec2_transit_gateway_vpc_attachment" "moj_tgw" {
  transit_gateway_id                 = data.aws_ec2_transit_gateway.moj_tgw.id
  vpc_id                             = module.connected_vpc.vpc_id
  subnet_ids                         = module.connected_vpc.private_subnets
  security_group_referencing_support = "enable"

  tags = local.tags
}
