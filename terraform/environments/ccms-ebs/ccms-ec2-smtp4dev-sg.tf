 resource "aws_security_group" "smtp4dev_mock_server_sg" {
 count    = local.is-production ? 0 : 1
 name        = "smtp4dev_mock_server_sg"
 description = "Security group for smtp4dev mock server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
      { Name = "smtp4dev_mock_server_sg" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "smtp4dev_workspace_80_ingress_rule" {
  count    = local.is_production ? 0 : 1
   security_group_id = aws_security_group.smtp4dev_mock_server_sg[count.index].id
   description = "This rule is used for AWS Workspace vm"
   ip_protocol = "tcp"
   from_port   = 80
    to_port     = 80
   cidr_ipv4   = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_vpc_security_group_ingress_rule" "smtp4dev_ccmsebs_2525_ingress_rule" {
  count    = local.is-production ? 0 : 1
  security_group_id = aws_security_group.smtp4dev_mock_server_sg[count.index].id

  description = "This rule is used for ccmsebs server"
  ip_protocol = "tcp"
  from_port   = 2525
  to_port     = 2525
  cidr_ipv4 = data.aws_subnet.data_subnets_a.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "smtp4dev_ccmsebs_110_ingress_rule" {
  count    = local.is-production ? 0 : 1
  security_group_id = aws_security_group.smtp4dev_mock_server_sg[count.index].id

  description = "POP3 (Port 110)"
  ip_protocol = "tcp"
  from_port   = 110
  to_port     = 110
  cidr_ipv4 = data.aws_subnet.data_subnets_a.cidr_block
}


resource "aws_vpc_security_group_egress_rule" "smtp4dev_http_egress_rule" {
  count    = local.is-production ? 0 : 1
  security_group_id = aws_security_group.smtp4dev_mock_server_sg[count.index].id

  description = "HTTPS outbound (Port 443)"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4 = "0.0.0.0/0"
}
