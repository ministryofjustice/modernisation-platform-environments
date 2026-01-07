resource "aws_security_group" "mis_ec2_shared" {
  #checkov:skip=CKV2_AWS_5 "ignore"
  name        = "${var.env_name}-mis-ec2-shared"
  description = "Security group to allow connectivity within MP"
  vpc_id      = var.account_info.vpc_id
  tags        = var.tags
}

#resource "aws_vpc_security_group_egress_rule" "http_s" {
#  for_each = toset(["80", "443"])
#
#  security_group_id = aws_security_group.mis_ec2_shared.id
#  cidr_ipv4         = "0.0.0.0/0"
#  ip_protocol       = "tcp"
#  from_port         = each.key
#  to_port           = each.key
#}
#
#resource "aws_vpc_security_group_egress_rule" "fleet_manager" {
#  security_group_id = aws_security_group.mis_ec2_shared.id
#  cidr_ipv4         = "0.0.0.0/0"
#  ip_protocol       = "tcp"
#  from_port         = 3389
#  to_port           = 3389
#}
#
#resource "aws_vpc_security_group_ingress_rule" "fleet_manager" {
#  security_group_id = aws_security_group.mis_ec2_shared.id
#  cidr_ipv4         = "0.0.0.0/0"
#  ip_protocol       = "tcp"
#  from_port         = 3389
#  to_port           = 3389
#}
#
#resource "aws_vpc_security_group_egress_rule" "domain_join" {
#  for_each                     = { for port in var.domain_join_ports : "${port.protocol}_${port.from_port}" => port }
#  from_port                    = each.value.from_port
#  to_port                      = each.value.to_port
#  ip_protocol                  = each.value.protocol
#  security_group_id            = aws_security_group.mis_ec2_shared.id
#  referenced_security_group_id = aws_directory_service_directory.mis_ad.security_group_id
#}
