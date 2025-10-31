resource "aws_ec2_transit_gateway_vpc_attachment" "moj_tgw" {
  count = local.environment == "production" ? 1 : 0

  transit_gateway_id                 = data.aws_ec2_transit_gateway.moj_tgw.id
  vpc_id                             = module.vpc[0].vpc_id
  subnet_ids                         = module.vpc[0].private_subnets
  security_group_referencing_support = "enable"

  tags = local.tags
}
