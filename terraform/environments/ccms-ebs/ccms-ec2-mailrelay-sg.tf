resource "aws_security_group" "ec2_sg_mailrelay" {
  name        = "ec2_sg_mailrelay"
  description = "Security Group for the Mailrelay server"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-mailrelay", local.application_name, local.environment)) }
  )
}


# INGRESS Rules

### SSH

resource "aws_security_group_rule" "ingress_traffic_mailrelay_22" {
  security_group_id = aws_security_group.ec2_sg_mailrelay.id
  type              = "ingress"
  description       = "SSH"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
  local.application_data.accounts[local.environment].lz_aws_subnet_env]
}

### SMTP

resource "aws_security_group_rule" "ingress_traffic_mailrelay_25" {
  security_group_id = aws_security_group.ec2_sg_mailrelay.id
  type              = "ingress"
  description       = "SMTP"
  protocol          = "TCP"
  from_port         = 25
  to_port           = 25
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
  local.application_data.accounts[local.environment].lz_aws_subnet_env]
}


# EGRESS Rules

### HTTPS

resource "aws_security_group_rule" "egress_traffic_mailrelay_443" {
  security_group_id = aws_security_group.ec2_sg_mailrelay.id
  type              = "egress"
  description       = "HTTPS"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

### SES

resource "aws_security_group_rule" "egress_traffic_mailrelay_587" {
  security_group_id = aws_security_group.ec2_sg_mailrelay.id
  type              = "egress"
  description       = "SES"
  protocol          = "TCP"
  from_port         = 587
  to_port           = 587
  cidr_blocks       = ["0.0.0.0/0"]
}
