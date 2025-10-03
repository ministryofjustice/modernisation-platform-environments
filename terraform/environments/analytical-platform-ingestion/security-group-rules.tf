locals {
  transfer_server_cidr_blocks_distinct = setunion(
    flatten([for k, v in local.environment_configuration.transfer_server_sftp_users : v.cidr_blocks]),
    flatten([for k, v in local.environment_configuration.transfer_server_sftp_users_with_egress : v.cidr_blocks])
  )
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = local.transfer_server_cidr_blocks_distinct
  from_port         = 2222
  ip_protocol       = "tcp"
  to_port           = 2222
  security_group_id = aws_security_group.transfer_server.id
  cidr_ipv4         = each.value
}

resource "aws_security_group_rule" "connected_vpc_endpoints_allow_all_vpc" {
  cidr_blocks       = [module.connected_vpc.vpc_cidr_block]
  description       = "Allow all traffic in from VPC CIDR"
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.connected_vpc_endpoints.id
  to_port           = 65535
  type              = "ingress"
}

resource "aws_security_group_rule" "isolated_vpc_endpoints_allow_all_vpc" {
  cidr_blocks       = [module.isolated_vpc.vpc_cidr_block]
  description       = "Allow all traffic in from VPC CIDR"
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.isolated_vpc_endpoints.id
  to_port           = 65535
  type              = "ingress"
}
