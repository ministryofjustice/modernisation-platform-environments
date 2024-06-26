resource "aws_ec2_transit_gateway_vpc_attachment" "pttp" {
  transit_gateway_id = data.aws_ec2_transit_gateway.pttp
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
}
