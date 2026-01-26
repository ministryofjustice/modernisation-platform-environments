resource "aws_ec2_transit_gateway_vpc_attachment" "moj_tgw" {
  count = try(local.network_configuration.vpc.additional_cidr_blocks.transit_gateway, null) != null ? 1 : 0

  transit_gateway_id = data.aws_ec2_transit_gateway.moj_tgw.id
  vpc_id             = aws_vpc.main.id
  subnet_ids = [
    for key, subnet in aws_subnet.additional : subnet.id
    if local.additional_cidr_subnets[key].type == "attachments"
  ]
  security_group_referencing_support = "enable"
  appliance_mode_support             = "enable"
}
