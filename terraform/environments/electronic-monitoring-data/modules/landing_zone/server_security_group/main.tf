#------------------------------------------------------------------------------
# AWS security group 
#
# Set the allowed IP addresses for the SFTP server.
#------------------------------------------------------------------------------

resource "aws_security_group" "this" {
  name        = "${var.user_name}-inbound-ips"
  description = "Allowed IP addresses for ${var.user_name}"
  vpc_id      = var.vpc_id

  tags = {
    supplier = var.user_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "this_ipv4" {
  security_group_id = aws_security_group.this.id
  description       = "Allow specific access to IPv4 address via port 2222"
  ip_protocol       = "tcp"
  from_port         = 2222
  to_port           = 2222

  for_each  = { for cidr_ipv4 in var.cidr_ipv4s : cidr_ipv4 => cidr_ipv4 }
  cidr_ipv4 = each.key
}

resource "aws_vpc_security_group_ingress_rule" "this_ipv6" {
  security_group_id = aws_security_group.this.id
  description       = "Allow specific access to IPv6 address via port 2222"
  ip_protocol       = "tcp"
  from_port         = 2222
  to_port           = 2222

  for_each  = { for cidr_ipv6 in var.cidr_ipv6s : cidr_ipv6 => cidr_ipv6 }
  cidr_ipv6 = each.key
}
