resource "aws_ec2_transit_gateway_vpc_attachment" "modernisation_platform" {
  subnet_ids         = [module.cluster_vpc.private_subnet_ids, module.cluster_vpc.public_subnet_ids]
  transit_gateway_id = "tgw-053d9dd7f1222a554"
  vpc_id             = module.cluster_vpc.vpc_id

  tags = tags
}


