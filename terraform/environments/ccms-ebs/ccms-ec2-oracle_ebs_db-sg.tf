# Security Group for EBSDB
resource "aws_security_group" "ec2_sg_ebsdb" {
  name        = "ec2_sg_ebsdb"
  description = "SG traffic control for EBSDB"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-ebsdb", local.application_name, local.environment)) }
  )
}

### INGRESS
# HTTP
resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_80_1" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "HTTP"
  ip_protocol       = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_80_2" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "HTTP"
  ip_protocol       = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_80_3" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "HTTP"
  ip_protocol       = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_80_4" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "HTTP"
  ip_protocol       = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b
}

# HTTPS
resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_443_1" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "HTTPS"
  ip_protocol       = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_443_2" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "HTTPS"
  ip_protocol       = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_443_3" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "HTTPS"
  ip_protocol       = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_443_4" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "HTTPS"
  ip_protocol       = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b
}

# SSH
resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_22_1" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "SSH"
  ip_protocol       = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_22_2" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "SSH"
  ip_protocol       = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_22_3" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "SSH"
  ip_protocol       = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_22_4" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "SSH"
  ip_protocol       = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b
}

# Oracle LDAP
resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_1389_1" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle LDAP"
  ip_protocol       = "TCP"
  from_port         = 1389
  to_port           = 1389
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_1389_2" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle LDAP"
  ip_protocol       = "TCP"
  from_port         = 1389
  to_port           = 1389
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_1389_3" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle LDAP"
  ip_protocol       = "TCP"
  from_port         = 1389
  to_port           = 1389
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_1389_4" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle LDAP"
  ip_protocol       = "TCP"
  from_port         = 1389
  to_port           = 1389
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b
}

# Oracle Listerner Port
resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_152x_1" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle Net Listener"
  ip_protocol       = "TCP"
  from_port         = 1521
  to_port           = 1522
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_152x_2" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle Net Listener"
  ip_protocol       = "TCP"
  from_port         = 1521
  to_port           = 1522
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_152x_3" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle Net Listener"
  ip_protocol       = "TCP"
  from_port         = 1521
  to_port           = 1522
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_152x_4" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle Net Listener"
  ip_protocol       = "TCP"
  from_port         = 1521
  to_port           = 1522
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_152x_5" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle Net Listener"
  ip_protocol       = "TCP"
  from_port         = 1521
  to_port           = 1522
  cidr_ipv4         = local.application_data.accounts[local.environment].cloud_platform_subnet
}

# Oracle
resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_5101_1" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 5101
  to_port           = 5101
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_5101_2" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 5101
  to_port           = 5101
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_5101_3" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 5101
  to_port           = 5101
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_5101_4" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 5101
  to_port           = 5101
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b
}

# Oracle
resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_5401_1" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 5401
  to_port           = 5401
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_5401_2" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 5401
  to_port           = 5401
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_5401_3" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 5401
  to_port           = 5401
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_5401_4" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 5401
  to_port           = 5401
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b
}

# Oracle
resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_5575_1" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 5575
  to_port           = 5575
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_5575_2" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 5575
  to_port           = 5575
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_5575_3" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 5575
  to_port           = 5575
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_5575_4" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 5575
  to_port           = 5575
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b
}

# Oracle LDAP SSL
resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_1636_1" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle LDAP SSL"
  ip_protocol       = "TCP"
  from_port         = 1636
  to_port           = 1636
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_1636_2" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle LDAP SSL"
  ip_protocol       = "TCP"
  from_port         = 1636
  to_port           = 1636
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_1636_3" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle LDAP SSL"
  ip_protocol       = "TCP"
  from_port         = 1636
  to_port           = 1636
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_1636_4" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle LDAP SSL"
  ip_protocol       = "TCP"
  from_port         = 1636
  to_port           = 1636
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b
}

# Oracle
resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_10401_1" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 10401
  to_port           = 10401
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_10401_2" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 10401
  to_port           = 10401
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_10401_3" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 10401
  to_port           = 10401
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_10401_4" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 10401
  to_port           = 10401
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b
}

# Oracle HTTP
resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_800x_1" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle HTTP"
  ip_protocol       = "TCP"
  from_port         = 8000
  to_port           = 8005
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_800x_2" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle HTTP"
  ip_protocol       = "TCP"
  from_port         = 8000
  to_port           = 8005
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_800x_3" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle HTTP"
  ip_protocol       = "TCP"
  from_port         = 8000
  to_port           = 8005
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_800x_4" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle HTTP"
  ip_protocol       = "TCP"
  from_port         = 8000
  to_port           = 8005
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b
}

# Oracle HTTPS
resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_4443_1" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle HTTPS"
  ip_protocol       = "TCP"
  from_port         = 4443
  to_port           = 4444
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_4443_2" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle HTTPS"
  ip_protocol       = "TCP"
  from_port         = 4443
  to_port           = 4444
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_4443_3" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle HTTPS"
  ip_protocol       = "TCP"
  from_port         = 4443
  to_port           = 4444
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdb_4443_4" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle HTTPS"
  ip_protocol       = "TCP"
  from_port         = 4443
  to_port           = 4444
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_appstream_subnet_a_b
}

### EGRESS
# HTTP
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ebsdb_80" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle HTTPs"
  ip_protocol       = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

# HTTPS
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ebsdb_443" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "HTTPS"
  ip_protocol       = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# FTP
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ebsdb_2x" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "FTP"
  ip_protocol       = "TCP"
  from_port         = 20
  to_port           = 21
  cidr_ipv4         = "0.0.0.0/0"
}

# SSH
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ebsdb_22" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "SSH"
  ip_protocol       = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "0.0.0.0/0"
}

# ORACLE LDAP
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ebsdb_1389" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "ORACLE LDAP"
  ip_protocol       = "TCP"
  from_port         = 1389
  to_port           = 1389
  cidr_ipv4         = "0.0.0.0/0"
}

# ORACLE Net Listener
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ebsdb_152x" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "ORACLE Net Listener"
  ip_protocol       = "TCP"
  from_port         = 1521
  to_port           = 1522
  cidr_ipv4         = "0.0.0.0/0"
}

# Oracle
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ebsdb_5101" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 5101
  to_port           = 5101
  cidr_ipv4         = "0.0.0.0/0"
}

# Oracle
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ebsdb_5401" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 5401
  to_port           = 5401
  cidr_ipv4         = "0.0.0.0/0"
}

# Oracle
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ebsdb_5575" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 5575
  to_port           = 5575
  cidr_ipv4         = "0.0.0.0/0"
}

# Oracle LDAP SSL
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ebsdb_1636" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle LDAP SSL"
  ip_protocol       = "TCP"
  from_port         = 1636
  to_port           = 1636
  cidr_ipv4         = "0.0.0.0/0"
}

# Oracle
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ebsdb_10401" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 10401
  to_port           = 10401
  cidr_ipv4         = "0.0.0.0/0"
}

# Lloyds FTP
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ebsdb_50000" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle"
  ip_protocol       = "TCP"
  from_port         = 50000
  to_port           = 51000
  cidr_ipv4         = "0.0.0.0/0"
}

# Oracle HTTP
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ebsdb_800x" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle HTTP"
  ip_protocol       = "TCP"
  from_port         = 8000
  to_port           = 8005
  cidr_ipv4         = "0.0.0.0/0"
}

# Oracle HTTPS
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ebsdb_4443" {
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "Oracle HTTPS"
  ip_protocol       = "TCP"
  from_port         = 4443
  to_port           = 4444
  cidr_ipv4         = "0.0.0.0/0"
}

# SMTP
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ebsdb_2525" {
  count             = local.is-production ? 0 : 1
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  description       = "SMTP"
  ip_protocol       = "TCP"
  from_port         = 2525
  to_port           = 2525
  cidr_ipv4         = "0.0.0.0/0"
}
