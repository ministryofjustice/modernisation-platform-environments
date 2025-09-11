# Security Group for ClamAV Server
resource "aws_security_group" "ec2_sg_clamav" {
  name        = "ec2_sg_clamav"
  description = "Security Group for ClamAV Server"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-ClamAV", local.application_name, local.environment)) }
  )
}

# ClamAV
resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_clamav_3310" {
  security_group_id = aws_security_group.ec2_sg_clamav.id
  description       = "ClamAV"
  protocol          = "TCP"
  from_port         = 3310
  to_port           = 3310
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
  local.application_data.accounts[local.environment].lz_aws_subnet_env]
}

# SSH
resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_clamav_22" {
  security_group_id = aws_security_group.ec2_sg_clamav.id
  description       = "SSH"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
  local.application_data.accounts[local.environment].lz_aws_subnet_env]
}

# HTTPS
resource "aws_vpc_security_group_egress_rule" "egress_traffic_clamav_3310" {
  security_group_id = aws_security_group.ec2_sg_clamav.id
  description       = "ClamAV"
  protocol          = "TCP"
  from_port         = 3310
  to_port           = 3310
  cidr_blocks       = ["0.0.0.0/0"]
}

# SSH
resource "aws_vpc_security_group_egress_rule" "egress_traffic_clamav_22" {
  security_group_id = aws_security_group.ec2_sg_clamav.id
  description       = "SSH"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

# HTTPS
resource "aws_vpc_security_group_egress_rule" "egress_traffic_clamav_443" {
  security_group_id = aws_security_group.ec2_sg_clamav.id
  description       = "HTTPS"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}
