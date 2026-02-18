#--EFS
resource "aws_security_group" "efs-security-group" {
  count       = local.is-development || local.is-test ? 1 : 0
  name_prefix = "${local.application_name_ssogen}-efs-security-group"
  description = "allow inbound access from container instances"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "efs-security-group-ingress" {

  count             = local.is-development || local.is-test ? length(local.private_subnets_cidr_blocks) : 0
  description       = "Allow inbound access from ec2 instances"
  security_group_id = aws_security_group.efs-security-group[0].id
  ip_protocol       = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = local.private_subnets_cidr_blocks[count.index]
}

resource "aws_vpc_security_group_egress_rule" "efs-security-group-egress" {
  count             = local.is-development || local.is-test ? 1 : 0
  description       = "Allow connections to EFS"
  security_group_id = aws_security_group.efs-security-group[count.index].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}