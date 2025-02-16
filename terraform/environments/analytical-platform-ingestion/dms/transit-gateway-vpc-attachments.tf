resource "aws_ec2_transit_gateway_vpc_attachment" "moj_tgw" {
  transit_gateway_id                 = data.aws_ec2_transit_gateway.moj_tgw.id
  vpc_id                             = "${local.vpc_id}"
  subnet_ids                         = "${local.subnet_ids}"
  security_group_referencing_support = "enable"

  tags = local.tags
}
