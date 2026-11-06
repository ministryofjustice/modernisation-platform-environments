# Security Group for shared ClamAV Server

resource "aws_security_group" "clamav" {
  name        = "${local.application_name}-clamav-sg"
  description = "Security Group for shared ClamAV Server"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = "${local.application_name}-clamav-sg" }
  )
}

# INGRESS Rules

resource "aws_vpc_security_group_ingress_rule" "clamav_3310" {
  security_group_id = aws_security_group.clamav.id
  description       = "Allow ClamAV from the shared VPC"
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
  ip_protocol       = "tcp"
  from_port         = 3310
  to_port           = 3310
}

# EGRESS Rules

resource "aws_vpc_security_group_egress_rule" "clamav_https" {
  security_group_id = aws_security_group.clamav.id
  description       = "Outbound HTTPS for virus definition updates"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
