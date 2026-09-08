locals {
  private_subnets_cidr_blocks = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block,
  ]

  opahub_name    = "ccms-opahub"
  connector_name = "ccms-connector"
  adaptor_name   = "ccms-adaptor"
}
