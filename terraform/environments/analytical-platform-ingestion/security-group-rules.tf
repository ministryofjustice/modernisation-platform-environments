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
