# Example security group with rules required for connectivity with legacy
resource "aws_security_group" "example" {
  name        = "example"
  description = "Example SG for legacy connectivity"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-example", local.application_name, local.environment)) }
  )
}

resource "aws_vpc_security_group_ingress_rule" "icmp" {
  security_group_id = aws_security_group.example.id
  cidr_ipv4         = local.application_data.accounts[local.environment].legacy_counterpart_cidr
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
}

resource "aws_vpc_security_group_egress_rule" "icmp" {
  security_group_id = aws_security_group.example.id
  cidr_ipv4         = local.application_data.accounts[local.environment].legacy_counterpart_cidr
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
}

resource "aws_vpc_security_group_egress_rule" "http" {
  for_each = toset(["80", "443"])

  security_group_id = aws_security_group.example.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = each.key
  to_port           = each.key
}

resource "aws_vpc_security_group_egress_rule" "oracle_db" {
  for_each = toset(["1521"])

  description       = "Legacy Oracle DB"
  security_group_id = aws_security_group.example.id
  cidr_ipv4         = local.application_data.accounts[local.environment].legacy_counterpart_cidr
  ip_protocol       = "tcp"
  from_port         = each.key
  to_port           = each.key
}

resource "aws_vpc_security_group_egress_rule" "ad_tcp" {
  for_each = toset(["53", "88", "135", "389", "445", "464", "636"])

  description       = "Legacy AD TCP"
  security_group_id = aws_security_group.example.id
  cidr_ipv4         = local.application_data.accounts[local.environment].legacy_counterpart_cidr
  ip_protocol       = "tcp"
  from_port         = each.key
  to_port           = each.key
}

resource "aws_vpc_security_group_egress_rule" "ad_udp" {
  for_each = toset(["53", "88", "123", "138", "389", "445","464"])

  description       = "Legacy AD UDP"
  security_group_id = aws_security_group.example.id
  cidr_ipv4         = local.application_data.accounts[local.environment].legacy_counterpart_cidr
  ip_protocol       = "udp"
  from_port         = each.key
  to_port           = each.key
}
