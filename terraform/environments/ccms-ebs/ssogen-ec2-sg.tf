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

############################################
# INGRESS — SSH (22) from WorkSpaces subnets (private)
############################################
resource "aws_security_group_rule" "ing_ssh_workspaces" {
  count             = local.is_development ? 1 : 0
  type              = "ingress"
  description       = "SSH from WorkSpaces subnets"
  security_group_id = aws_security_group.ssogen_sg[count.index].id
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks = [
    data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env,
  ]
}

############################################
# INGRESS — WebLogic Admin (7001)
############################################
resource "aws_security_group_rule" "ing_7001_workspaces_private" {
  count             = local.is_development ? 1 : 0
  type              = "ingress"
  description       = "WebLogic 7001 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  protocol          = "tcp"
  from_port         = 7001
  to_port           = 7001
  cidr_blocks = [
    data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env,
  ]
}

resource "aws_security_group_rule" "ing_7001_workspaces_nat" {
  count             = local.is_development ? 1 : 0
  type              = "ingress"
  description       = "WebLogic 7001 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  protocol          = "tcp"
  from_port         = 7001
  to_port           = 7001
  cidr_blocks = [
    "18.130.39.94/32",
    "35.177.145.193/32",
    "52.56.212.11/32",
    "35.176.254.38/32",
    "35.177.173.197/32"
  ]
}

############################################
# INGRESS — OHS 7777
############################################
resource "aws_security_group_rule" "ing_7777_workspaces_private" {
  count             = local.is_development ? 1 : 0
  type              = "ingress"
  description       = "OHS 7777 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  protocol          = "tcp"
  from_port         = 7777
  to_port           = 7777
  cidr_blocks = [
    data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env,
  ]
}

resource "aws_security_group_rule" "ing_7777_workspaces_nat" {
  count             = local.is_development ? 1 : 0
  type              = "ingress"
  description       = "OHS 7777 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  protocol          = "tcp"
  from_port         = 7777
  to_port           = 7777
  cidr_blocks = [
    "18.130.39.94/32",
    "35.177.145.193/32",
    "52.56.212.11/32",
    "35.176.254.38/32",
    "35.177.173.197/32"
  ]
}

############################################
# INGRESS — OHS 4443
############################################
resource "aws_security_group_rule" "ing_4443_workspaces_private" {
  count             = local.is_development ? 1 : 0
  type              = "ingress"
  description       = "OHS 4443 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  protocol          = "tcp"
  from_port         = 4443
  to_port           = 4443
  cidr_blocks = [
    data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env,
  ]
}

resource "aws_security_group_rule" "ing_4443_workspaces_nat" {
  count             = local.is_development ? 1 : 0
  type              = "ingress"
  description       = "OHS 4443 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg[0].id
  protocol          = "tcp"
  from_port         = 4443
  to_port           = 4443
  cidr_blocks = [
    "18.130.39.94/32",
    "35.177.145.193/32",
    "52.56.212.11/32",
    "35.176.254.38/32",
    "35.177.173.197/32"
  ]
}

############################################
# INGRESS — WebLogic managed servers (8000–8005) from EBS App SG
############################################
resource "aws_security_group_rule" "ing_8000_8005_from_ebsapps" {
  count                    = local.is_development ? 1 : 0
  type                     = "ingress"
  description              = "WebLogic managed servers from EBS App servers"
  security_group_id        = aws_security_group.ssogen_sg[0].id
  protocol                 = "tcp"
  from_port                = 8000
  to_port                  = 8005
  source_security_group_id = aws_security_group.ec2_sg_ebsapps.id
}

############################################
# INGRESS — Node Manager (5556) intra-cluster (self)
############################################
resource "aws_security_group_rule" "ing_5556_self" {
  count                    = local.is_development ? 1 : 0
  type                     = "ingress"
  description              = "WL Node Manager intra-SG"
  security_group_id        = aws_security_group.ssogen_sg[0].id
  protocol                 = "tcp"
  from_port                = 5556
  to_port                  = 5556
  source_security_group_id = aws_security_group.ssogen_sg[0].id
}

############################################
# TEMP INGRESS — ICMP Echo (self + WorkSpaces)
############################################
resource "aws_security_group_rule" "ing_icmp_self" {
  count                    = local.is_development ? 1 : 0
  type                     = "ingress"
  description              = "TEMP: ICMP Echo from SSOGEN (self)"
  security_group_id        = aws_security_group.ssogen_sg[0].id
  protocol                 = "icmp"
  from_port                = 8
  to_port                  = 0
  source_security_group_id = aws_security_group.ssogen_sg[0].id
}

resource "aws_security_group_rule" "ing_icmp_workspaces" {
  count             = local.is_development ? 1 : 0
  type              = "ingress"
  description       = "TEMP: ICMP Echo from WorkSpaces subnets"
  security_group_id = aws_security_group.ssogen_sg[0].id
  protocol          = "icmp"
  from_port         = 8
  to_port           = 0
  cidr_blocks = [
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env,
  ]
}

############################################
# EGRESS — Oracle LDAP (non-SSL + SSL)
############################################
resource "aws_security_group_rule" "eg_ldap_1389" {
  count             = local.is_development ? 1 : 0
  type              = "egress"
  description       = "Oracle LDAP"
  security_group_id = aws_security_group.ssogen_sg[0].id
  protocol          = "tcp"
  from_port         = 1389
  to_port           = 1389
  cidr_blocks       = ["10.0.0.0/8"]
}

resource "aws_security_group_rule" "eg_ldap_1636_ssl" {
  count             = local.is_development ? 1 : 0
  type              = "egress"
  description       = "Oracle LDAP SSL"
  security_group_id = aws_security_group.ssogen_sg[0].id
  protocol          = "tcp"
  from_port         = 1636
  to_port           = 1636
  cidr_blocks       = ["10.0.0.0/8"]
}

############################################
# EGRESS — 80/443
############################################
resource "aws_security_group_rule" "eg_http_80" {
  count             = local.is_development ? 1 : 0
  type              = "egress"
  description       = "Allow outbound HTTP"
  security_group_id = aws_security_group.ssogen_sg[0].id
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "eg_https_443" {
  count             = local.is_development ? 1 : 0
  type              = "egress"
  description       = "Allow outbound HTTPS"
  security_group_id = aws_security_group.ssogen_sg[0].id
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

############################################
# TEMP EGRESS — ICMP Echo to VPC + WorkSpaces
############################################
resource "aws_security_group_rule" "eg_icmp_vpc_workspaces" {
  count             = local.is_development ? 1 : 0
  type              = "egress"
  description       = "TEMP: ICMP Echo egress to VPC + WorkSpaces"
  security_group_id = aws_security_group.ssogen_sg[0].id
  protocol          = "icmp"
  from_port         = 8
  to_port           = 0
  cidr_blocks = [
    data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
    local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env,
  ]
}

#########################################
# SSOGEN Security Group — Allow inbound 4443 from ALB
#########################################

resource "aws_vpc_security_group_ingress_rule" "ing_4443_from_alb" {
  count                        = local.is_development ? 1 : 0
  security_group_id            = aws_security_group.ssogen_sg[0].id
  description                  = "Allow inbound HTTPS (4443) from SSOGEN internal ALB"
  from_port                    = 4443
  to_port                      = 4443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.sg_ssogen_internal_alb[count.index].id
}
