resource "aws_security_group" "legacy" {
  #checkov:skip=CKV2_AWS_5 "ignore"
  name        = "${var.env_name}-allow-legacy-traffic"
  description = "Security group to allow connectivity with resources in legacy environments. To be removed once all components have been migrated"
  vpc_id      = var.account_info.vpc_id
  tags        = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "icmp" {
  security_group_id = aws_security_group.legacy.id
  cidr_ipv4         = var.environment_config.legacy_counterpart_vpc_cidr
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
}

resource "aws_vpc_security_group_egress_rule" "icmp" {
  security_group_id = aws_security_group.legacy.id
  cidr_ipv4         = var.environment_config.legacy_counterpart_vpc_cidr
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
}

resource "aws_vpc_security_group_egress_rule" "oracle_db" {
  for_each = toset(["1521"])

  description       = "Legacy Oracle DB"
  security_group_id = aws_security_group.legacy.id
  cidr_ipv4         = var.environment_config.legacy_counterpart_vpc_cidr
  ip_protocol       = "tcp"
  from_port         = each.key
  to_port           = each.key
}

resource "aws_vpc_security_group_egress_rule" "ad_tcp" {
  for_each = toset(["53", "88", "135", "389", "445", "464", "636"])

  description       = "Legacy AD TCP"
  security_group_id = aws_security_group.legacy.id
  cidr_ipv4         = var.environment_config.legacy_counterpart_vpc_cidr
  ip_protocol       = "tcp"
  from_port         = each.key
  to_port           = each.key
}

resource "aws_vpc_security_group_egress_rule" "ad_tcp_1024-65535" {
  description       = "Legacy AD TCP"
  security_group_id = aws_security_group.legacy.id
  cidr_ipv4         = var.environment_config.legacy_counterpart_vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 1024
  to_port           = 65535
}

resource "aws_vpc_security_group_egress_rule" "ad_udp" {
  for_each = toset(["53", "88", "123", "138", "389", "445", "464"])

  description       = "Legacy AD UDP"
  security_group_id = aws_security_group.legacy.id
  cidr_ipv4         = var.environment_config.legacy_counterpart_vpc_cidr
  ip_protocol       = "udp"
  from_port         = each.key
  to_port           = each.key
}
