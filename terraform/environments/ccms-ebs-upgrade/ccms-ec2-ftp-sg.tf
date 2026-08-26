# Security Group for FTP Server

resource "aws_security_group" "ec2_sg_ftp" {
  count       = local.is-test ? 1 : 0
  name        = "ec2_sg_ftp"
  description = "Security Group for FTP Server"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-FTP", local.application_name, local.environment)) }
  )
}

# INGRESS Rules

### FTP

resource "aws_security_group_rule" "ingress_traffic_ftp_20" {
  count             = local.is-test ? 1 : 0
  security_group_id = aws_security_group.ec2_sg_ftp[count.index].id
  type              = "ingress"
  description       = "FTP"
  protocol          = "TCP"
  from_port         = 20
  to_port           = 21
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
  local.application_data.accounts[local.environment].lz_aws_subnet_env]
}

### FTP Passive Ports

resource "aws_security_group_rule" "ingress_traffic_ftp_3000" {
  count             = local.is-test ? 1 : 0
  security_group_id = aws_security_group.ec2_sg_ftp[count.index].id
  type              = "ingress"
  description       = "FTP Passive Ports"
  protocol          = "TCP"
  from_port         = 3000
  to_port           = 3010
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
  local.application_data.accounts[local.environment].lz_aws_subnet_env]
}

### SSH

resource "aws_security_group_rule" "ingress_traffic_ftp_22" {
  count             = local.is-test ? 1 : 0
  security_group_id = aws_security_group.ec2_sg_ftp[count.index].id
  type              = "ingress"
  description       = "SSH"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
  local.application_data.accounts[local.environment].lz_aws_subnet_env]
}



# EGRESS Rules

### FTP

resource "aws_security_group_rule" "egress_traffic_ftp_20" {
  count             = local.is-test ? 1 : 0
  security_group_id = aws_security_group.ec2_sg_ftp[count.index].id
  type              = "egress"
  description       = "FTP"
  protocol          = "TCP"
  from_port         = 20
  to_port           = 21
  cidr_blocks = [data.aws_vpc.shared.cidr_block,
  local.application_data.accounts[local.environment].lz_aws_subnet_env]
}

### SSH

resource "aws_security_group_rule" "egress_traffic_ftp_22" {
  count             = local.is-test ? 1 : 0
  security_group_id = aws_security_group.ec2_sg_ftp[count.index].id
  type              = "egress"
  description       = "SSH"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

### HTTPS

resource "aws_security_group_rule" "egress_traffic_ftp_443" {
  count             = local.is-test ? 1 : 0
  security_group_id = aws_security_group.ec2_sg_ftp[count.index].id
  type              = "egress"
  description       = "HTTPS"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}
