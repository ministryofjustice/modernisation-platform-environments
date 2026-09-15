resource "aws_security_group" "ftp" {
  name        = "${local.component_name}-${local.env_label}-ftp-sg"
  description = "Controls access to the FTP server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ftp-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "ftp_control_from_vpc" {
  security_group_id = aws_security_group.ftp.id
  description       = "FTP control channel from the shared VPC"
  ip_protocol       = "tcp"
  from_port         = 20
  to_port           = 21
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ftp_passive_from_vpc" {
  security_group_id = aws_security_group.ftp.id
  description       = "FTP passive ports from the shared VPC"
  ip_protocol       = "tcp"
  from_port         = 3000
  to_port           = 3010
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ftp_ssh" {
  security_group_id = aws_security_group.ftp.id
  description       = "SSH from the shared VPC"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ftp_ssh_workspace" {
  security_group_id = aws_security_group.ftp.id
  description       = "SSH from AWS Workspaces"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_vpc_security_group_egress_rule" "ftp_control_to_vpc" {
  security_group_id = aws_security_group.ftp.id
  description       = "FTP control channel outbound to the shared VPC"
  ip_protocol       = "tcp"
  from_port         = 20
  to_port           = 21
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "ftp_https" {
  security_group_id = aws_security_group.ftp.id
  description       = "HTTPS outbound"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}
