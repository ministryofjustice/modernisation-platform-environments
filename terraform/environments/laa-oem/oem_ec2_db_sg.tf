resource "aws_security_group" "oem_db_security_group" {
  name_prefix = "${local.application_name}-db-server-sg-"
  description = "controls access to the ebs app server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(tomap(
    { "Name" = "${local.application_name}-db-server-sg" }
  ), local.tags)
}

# Egress Rules for oem_db_security_group
# Note: egress is scoped rather than 0.0.0.0/0. HTTPS/HTTP to the internet is
# retained for OS patching (yum) and first-boot agent downloads in user data.
resource "aws_vpc_security_group_egress_rule" "oem_db_sg_egress_vpc" {
  security_group_id = aws_security_group.oem_db_security_group.id
  description       = "Allow all outbound traffic within the VPC"
  ip_protocol       = "-1"
  cidr_ipv4         = data.aws_vpc.shared.cidr_block

  tags = {
    Name = "Allow all outbound traffic within the VPC"
  }
}

resource "aws_vpc_security_group_egress_rule" "oem_db_sg_egress_s3" {
  security_group_id = aws_security_group.oem_db_security_group.id
  description       = "Allow S3 access via gateway endpoint (prefix list)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_prefix_list.s3.id

  tags = {
    Name = "S3 via gateway endpoint"
  }
}

resource "aws_vpc_security_group_egress_rule" "oem_db_sg_egress_vpce_a" {
  security_group_id = aws_security_group.oem_db_security_group.id
  description       = "Allow HTTPS to VPC interface endpoints (SSM, Logs, Secrets Manager) AZ a"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_subnet.protected_subnets_a.cidr_block

  tags = {
    Name = "HTTPS to VPC interface endpoints AZ a"
  }
}

resource "aws_vpc_security_group_egress_rule" "oem_db_sg_egress_vpce_b" {
  security_group_id = aws_security_group.oem_db_security_group.id
  description       = "Allow HTTPS to VPC interface endpoints (SSM, Logs, Secrets Manager) AZ b"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_subnet.protected_subnets_b.cidr_block

  tags = {
    Name = "HTTPS to VPC interface endpoints AZ b"
  }
}

resource "aws_vpc_security_group_egress_rule" "oem_db_sg_egress_vpce_c" {
  security_group_id = aws_security_group.oem_db_security_group.id
  description       = "Allow HTTPS to VPC interface endpoints (SSM, Logs, Secrets Manager) AZ c"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_subnet.protected_subnets_c.cidr_block

  tags = {
    Name = "HTTPS to VPC interface endpoints AZ c"
  }
}

resource "aws_vpc_security_group_egress_rule" "oem_db_sg_egress_https_internet" {
  security_group_id = aws_security_group.oem_db_security_group.id
  description       = "Allow HTTPS to internet for OS patching and package downloads"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "HTTPS to internet (patching)"
  }
}

# Ingress Rules for oem_db_security_group
resource "aws_vpc_security_group_ingress_rule" "oem_db_sg_ingress_tcp_22_22_cidr_1" {
  security_group_id = aws_security_group.oem_db_security_group.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_db_sg_ingress_tcp_22_22_cidr_2" {
  security_group_id = aws_security_group.oem_db_security_group.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.cidr_lz_workspaces_nonp
}

resource "aws_vpc_security_group_ingress_rule" "oem_db_sg_ingress_tcp_22_22_cidr_3" {
  security_group_id = aws_security_group.oem_db_security_group.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.cidr_lz_workspaces_prod
}

resource "aws_vpc_security_group_ingress_rule" "oem_db_sg_ingress_icmp_neg1_neg1_cidr_1" {
  security_group_id = aws_security_group.oem_db_security_group.id
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_db_sg_ingress_icmp_neg1_neg1_cidr_2" {
  security_group_id = aws_security_group.oem_db_security_group.id
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = local.cidr_lz_workspaces_nonp
}

resource "aws_vpc_security_group_ingress_rule" "oem_db_sg_ingress_icmp_neg1_neg1_cidr_3" {
  security_group_id = aws_security_group.oem_db_security_group.id
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = local.cidr_lz_workspaces_prod
}

resource "aws_vpc_security_group_ingress_rule" "oem_db_sg_ingress_tcp_1159_1159_cidr" {
  security_group_id = aws_security_group.oem_db_security_group.id
  ip_protocol       = "tcp"
  from_port         = 1159
  to_port           = 1159
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_db_sg_ingress_tcp_1521_1521_cidr" {
  security_group_id = aws_security_group.oem_db_security_group.id
  ip_protocol       = "tcp"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_db_sg_ingress_tcp_1830_1849_cidr" {
  security_group_id = aws_security_group.oem_db_security_group.id
  ip_protocol       = "tcp"
  from_port         = 1830
  to_port           = 1849
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_db_sg_ingress_tcp_2049_2049_cidr" {
  security_group_id = aws_security_group.oem_db_security_group.id
  ip_protocol       = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_db_sg_ingress_tcp_3872_3872_cidr" {
  security_group_id = aws_security_group.oem_db_security_group.id
  ip_protocol       = "tcp"
  from_port         = 3872
  to_port           = 3872
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_db_sg_ingress_tcp_4889_4889_cidr" {
  security_group_id = aws_security_group.oem_db_security_group.id
  ip_protocol       = "tcp"
  from_port         = 4889
  to_port           = 4889
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_db_sg_ingress_tcp_7101_7101_cidr" {
  security_group_id = aws_security_group.oem_db_security_group.id
  ip_protocol       = "tcp"
  from_port         = 7101
  to_port           = 7101
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_db_sg_ingress_tcp_7799_7799_cidr" {
  security_group_id = aws_security_group.oem_db_security_group.id
  ip_protocol       = "tcp"
  from_port         = 7799
  to_port           = 7799
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}
