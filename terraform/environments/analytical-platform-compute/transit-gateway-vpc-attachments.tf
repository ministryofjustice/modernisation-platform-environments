resource "aws_ec2_transit_gateway_vpc_attachment" "pttp" {
  # transit_gateway_id = data.aws_ec2_transit_gateway.pttp.id
  transit_gateway_id = data.aws_arn.moj_tgw.resource
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets

  tags = local.tags
}
