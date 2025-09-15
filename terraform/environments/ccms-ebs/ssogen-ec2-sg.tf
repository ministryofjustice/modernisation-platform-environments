############################################
# Security Group (no inline rules) — dev only
############################################
resource "aws_security_group" "ssogen_sg" {
  count       = local.is_development ? 1 : 0
  name        = "ssogen-sg-${local.environment}"
  description = "Security group for SSOGEN EC2 (WebLogic + OHS)"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, { Name = "ssogen-sg-${local.environment}" })
}

# INGRESS — SSH (22) from WorkSpaces subnets (private)
resource "aws_vpc_security_group_ingress_rule" "ingress_ssh_workspaces_1" {
  count             = local.is_development ? 1 : 0
  description       = "SSH from WorkSpaces subnets"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ingress_ssh_workspaces_2" {
  count             = local.is_development ? 1 : 0
  description       = "SSH from WorkSpaces subnets"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_ssh_workspaces_3" {
  count             = local.is_development ? 1 : 0
  description       = "SSH from WorkSpaces subnets"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_ssh_workspaces_4" {
  count             = local.is_development ? 1 : 0
  description       = "SSH from WorkSpaces subnets"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env
}

# INGRESS — WebLogic Admin (7001)
resource "aws_vpc_security_group_ingress_rule" "ingress_7001_workspaces_private_1" {
  count             = local.is_development ? 1 : 0
  description       = "WebLogic 7001 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7001
  to_port           = 7001
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ingress_7001_workspaces_private_2" {
  count             = local.is_development ? 1 : 0
  description       = "WebLogic 7001 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7001
  to_port           = 7001
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_7001_workspaces_private_3" {
  count             = local.is_development ? 1 : 0
  description       = "WebLogic 7001 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7001
  to_port           = 7001
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_7001_workspaces_private_4" {
  count             = local.is_development ? 1 : 0
  description       = "WebLogic 7001 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7001
  to_port           = 7001
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_7001_workspaces_nat_1" {
  count             = local.is_development ? 1 : 0
  description       = "WebLogic 7001 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7001
  to_port           = 7001
  cidr_ipv4         = "18.130.39.94/32"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_7001_workspaces_nat_2" {
  count             = local.is_development ? 1 : 0
  description       = "WebLogic 7001 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7001
  to_port           = 7001
  cidr_ipv4         = "35.177.145.193/32"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_7001_workspaces_nat_3" {
  count             = local.is_development ? 1 : 0
  description       = "WebLogic 7001 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7001
  to_port           = 7001
  cidr_ipv4         = "52.56.212.11/32"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_7001_workspaces_nat_4" {
  count             = local.is_development ? 1 : 0
  description       = "WebLogic 7001 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7001
  to_port           = 7001
  cidr_ipv4         = "35.176.254.38/32"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_7001_workspaces_nat_5" {
  count             = local.is_development ? 1 : 0
  description       = "WebLogic 7001 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7001
  to_port           = 7001
  cidr_ipv4         = "35.177.173.197/32"
}

# INGRESS — OHS 7777
resource "aws_vpc_security_group_ingress_rule" "ingress_7777_workspaces_private_1" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 7777 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7777
  to_port           = 7777
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ingress_7777_workspaces_private_2" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 7777 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7777
  to_port           = 7777
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_7777_workspaces_private_3" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 7777 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7777
  to_port           = 7777
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_7777_workspaces_private_4" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 7777 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7777
  to_port           = 7777
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_7777_workspaces_nat_!" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 7777 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7777
  to_port           = 7777
  cidr_ipv4         = "18.130.39.94/32"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_7777_workspaces_nat_2" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 7777 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7777
  to_port           = 7777
  cidr_ipv4         = "35.177.145.193/32"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_7777_workspaces_nat_3" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 7777 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7777
  to_port           = 7777
  cidr_ipv4         = "52.56.212.11/32"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_7777_workspaces_nat_4" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 7777 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7777
  to_port           = 7777
  cidr_ipv4         = "35.176.254.38/32"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_7777_workspaces_nat_5" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 7777 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 7777
  to_port           = 7777
  cidr_ipv4         = "35.177.173.197/32"
}

# INGRESS — OHS 4443
resource "aws_vpc_security_group_ingress_rule" "ingress_4443_workspaces_private_1" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 4443 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 4443
  to_port           = 4443
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}
resource "aws_vpc_security_group_ingress_rule" "ingress_4443_workspaces_private_2" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 4443 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 4443
  to_port           = 4443
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_subnet_env
}
resource "aws_vpc_security_group_ingress_rule" "ingress_4443_workspaces_private_3" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 4443 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 4443
  to_port           = 4443
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env
}
resource "aws_vpc_security_group_ingress_rule" "ingress_4443_workspaces_private_4" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 4443 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 4443
  to_port           = 4443
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_4443_workspaces_nat_1" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 4443 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 4443
  to_port           = 4443
  cidr_ipv4         = "18.130.39.94/32"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_4443_workspaces_nat_2" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 4443 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 4443
  to_port           = 4443
  cidr_ipv4         = "35.177.145.193/32"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_4443_workspaces_nat_3" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 4443 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 4443
  to_port           = 4443
  cidr_ipv4         = "52.56.212.11/32"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_4443_workspaces_nat_4" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 4443 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 4443
  to_port           = 4443
  cidr_ipv4         = "35.176.254.38/32"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_4443_workspaces_nat_5" {
  count             = local.is_development ? 1 : 0
  description       = "OHS 4443 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 4443
  to_port           = 4443
  cidr_ipv4         = "35.177.173.197/32"
}

# INGRESS — WebLogic managed servers (8000–8005) from EBS App SG
resource "aws_vpc_security_group_ingress_rule" "ingress_8000_8005_from_ebsapps" {
  count                        = local.is_development ? 1 : 0
  description                  = "WebLogic managed servers from EBS App servers"
  security_group_id            = aws_security_group.ssogen_sg[0].id
  ip_protocol                  = "tcp"
  from_port                    = 8000
  to_port                      = 8005
  referenced_security_group_id = aws_security_group.ec2_sg_ebsapps.id
}

# INGRESS — Node Manager (5556) intra-cluster (self)
resource "aws_vpc_security_group_ingress_rule" "ingress_5556_self" {
  count                        = local.is_development ? 1 : 0
  description                  = "WL Node Manager intra-SG"
  security_group_id            = aws_security_group.ssogen_sg[0].id
  ip_protocol                  = "tcp"
  from_port                    = 5556
  to_port                      = 5556
  referenced_security_group_id = aws_security_group.ssogen_sg[0].id
}

# TEMP INGRESS — ICMP Echo (self + WorkSpaces)
resource "aws_vpc_security_group_ingress_rule" "ingress_icmp_self" {
  count                        = local.is_development ? 1 : 0
  description                  = "TEMP: ICMP Echo from SSOGEN (self)"
  security_group_id            = aws_security_group.ssogen_sg[0].id
  ip_protocol                  = "icmp"
  from_port                    = 8
  to_port                      = 0
  referenced_security_group_id = aws_security_group.ssogen_sg[0].id
}

resource "aws_vpc_security_group_ingress_rule" "ingress_icmp_workspaces_1" {
  count             = local.is_development ? 1 : 0
  description       = "TEMP: ICMP Echo from WorkSpaces subnets"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "icmp"
  from_port         = 8
  to_port           = 0
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env
}

resource "aws_vpc_security_group_ingress_rule" "ingress_icmp_workspaces_2" {
  count             = local.is_development ? 1 : 0
  description       = "TEMP: ICMP Echo from WorkSpaces subnets"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "icmp"
  from_port         = 8
  to_port           = 0
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env
}

# EGRESS — Oracle LDAP (non-SSL + SSL)
resource "aws_vpc_security_group_egress_rule" "egress_ldap_1389" {
  count             = local.is_development ? 1 : 0
  description       = "Oracle LDAP"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 1389
  to_port           = 1389
  cidr_ipv4         = "10.0.0.0/8"
}

resource "aws_vpc_security_group_egress_rule" "egress_ldap_1636_ssl" {
  count             = local.is_development ? 1 : 0
  description       = "Oracle LDAP SSL"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 1636
  to_port           = 1636
  cidr_ipv4         = "10.0.0.0/8"
}

# EGRESS — 80/443
resource "aws_vpc_security_group_egress_rule" "egress_http_80" {
  count             = local.is_development ? 1 : 0
  description       = "Allow outbound HTTP"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "egress_https_443" {
  count             = local.is_development ? 1 : 0
  description       = "Allow outbound HTTPS"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# TEMP EGRESS — ICMP Echo to VPC + WorkSpaces
resource "aws_vpc_security_group_egress_rule" "egress_icmp_vpc_workspaces_1" {
  count             = local.is_development ? 1 : 0
  description       = "TEMP: ICMP Echo egress to VPC + WorkSpaces"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "icmp"
  from_port         = 8
  to_port           = 0
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "egress_icmp_vpc_workspaces_2" {
  count             = local.is_development ? 1 : 0
  description       = "TEMP: ICMP Echo egress to VPC + WorkSpaces"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "icmp"
  from_port         = 8
  to_port           = 0
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env
}

resource "aws_vpc_security_group_egress_rule" "egress_icmp_vpc_workspaces_3" {
  count             = local.is_development ? 1 : 0
  description       = "TEMP: ICMP Echo egress to VPC + WorkSpaces"
  security_group_id = aws_security_group.ssogen_sg[0].id
  ip_protocol       = "icmp"
  from_port         = 8
  to_port           = 0
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env
}
