# Security Group for ClamAV Server
resource "aws_security_group" "ec2_sg_clamav" {
  name        = "ec2_sg_clamav"
  description = "Security Group for ClamAV Server"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("clamav-%s-sg", local.environment)) }
  )
}

# INGRESS Rules

### ClamAV

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_clamav_3310" {
  security_group_id = aws_security_group.ec2_sg_clamav.id

  cidr_ipv4   = data.aws_vpc.shared.cidr_block
  description = "Allow ClamAV from VPC"
  ip_protocol = "tcp"
  from_port   = 3310
  to_port     = 3310
}

# EGRESS Rules

### HTTPS
resource "aws_vpc_security_group_egress_rule" "egress_traffic_clamav_443" {
  security_group_id = aws_security_group.ec2_sg_clamav.id
  description       = "Outbound HTTPS"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
