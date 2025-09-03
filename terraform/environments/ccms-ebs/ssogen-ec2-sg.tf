resource "aws_security_group" "ssogen_sg" {
  name        = "ssogen-sg-${local.environment}"
  description = "Security group for SSOGEN EC2 (WebLogic + OHS)"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "ssogen-sg-${local.environment}"
  })
}

############################################################
# ✅ INGRESS — Allow traffic to SSOGEN EC2s
############################################################

# SSH for admin access — WorkSpaces (private)
resource "aws_security_group_rule" "ssogen_sg_ingress_ssh_vpc" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  description       = "SSH from WorkSpaces subnets"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_ssh_lz_aws_subnet" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  description       = "SSH from WorkSpaces subnets"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_subnet_env]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_ssh_lz_aws_workspace_nonprod" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  description       = "SSH from WorkSpaces subnets"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_ssh_lz_aws_workspace_prod" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  description       = "SSH from WorkSpaces subnets"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}

# WebLogic Admin (7001) — WorkSpaces (private + NAT)
resource "aws_security_group_rule" "ssogen_sg_ingress_weblogic_private_vpc" {
  type              = "ingress"
  from_port         = 7001
  to_port           = 7001
  protocol          = "tcp"
  description       = "WebLogic 7001 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_weblogic_private_lz_aws_subnet" {
  type              = "ingress"
  from_port         = 7001
  to_port           = 7001
  protocol          = "tcp"
  description       = "WebLogic 7001 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_subnet_env]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_weblogic_private_lz_aws_workspace_nonprod" {
  type              = "ingress"
  from_port         = 7001
  to_port           = 7001
  protocol          = "tcp"
  description       = "WebLogic 7001 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_weblogic_private_lz_aws_workspace_prod" {
  type              = "ingress"
  from_port         = 7001
  to_port           = 7001
  protocol          = "tcp"
  description       = "WebLogic 7001 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_weblogic_nat_1" {
  type              = "ingress"
  from_port         = 7001
  to_port           = 7001
  protocol          = "tcp"
  description       = "WebLogic 7001 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["18.130.39.94/32"]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_weblogic_nat_2" {
  type              = "ingress"
  from_port         = 7001
  to_port           = 7001
  protocol          = "tcp"
  description       = "WebLogic 7001 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["35.177.145.193/32"]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_weblogic_nat_3" {
  type              = "ingress"
  from_port         = 7001
  to_port           = 7001
  protocol          = "tcp"
  description       = "WebLogic 7001 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["52.56.212.11/32"]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_weblogic_nat_4" {
  type              = "ingress"
  from_port         = 7001
  to_port           = 7001
  protocol          = "tcp"
  description       = "WebLogic 7001 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["35.176.254.38/32"]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_weblogic_nat_5" {
  type              = "ingress"
  from_port         = 7001
  to_port           = 7001
  protocol          = "tcp"
  description       = "WebLogic 7001 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["35.177.173.197/32"]
}

# Oracle HTTP Server (7777) — WorkSpaces (private + NAT)
resource "aws_security_group_rule" "ssogen_sg_ingress_ohs_private_vpc" {
  type              = "ingress"
  from_port         = 7777
  to_port           = 7777
  protocol          = "tcp"
  description       = "OHS 7777 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_ohs_private_lz_aws_subnet" {
  type              = "ingress"
  from_port         = 7777
  to_port           = 7777
  protocol          = "tcp"
  description       = "OHS 7777 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_subnet_env]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_ohs_private_lz_aws_workspace_nonprod" {
  type              = "ingress"
  from_port         = 7777
  to_port           = 7777
  protocol          = "tcp"
  description       = "OHS 7777 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_ohs_private_lz_aws_workspace_prod" {
  type              = "ingress"
  from_port         = 7777
  to_port           = 7777
  protocol          = "tcp"
  description       = "OHS 7777 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_ohs_nat_1" {
  type              = "ingress"
  from_port         = 7777
  to_port           = 7777
  protocol          = "tcp"
  description       = "OHS 7777 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["18.130.39.94/32"]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_ohs_nat_2" {
  type              = "ingress"
  from_port         = 7777
  to_port           = 7777
  protocol          = "tcp"
  description       = "OHS 7777 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["35.177.145.193/32"]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_ohs_nat_3" {
  type              = "ingress"
  from_port         = 7777
  to_port           = 7777
  protocol          = "tcp"
  description       = "OHS 7777 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["52.56.212.11/32"]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_ohs_nat_4" {
  type              = "ingress"
  from_port         = 7777
  to_port           = 7777
  protocol          = "tcp"
  description       = "OHS 7777 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["35.176.254.38/32"]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_ohs_nat_5" {
  type              = "ingress"
  from_port         = 7777
  to_port           = 7777
  protocol          = "tcp"
  description       = "OHS 7777 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["35.177.173.197/32"]
}

# Oracle HTTPS (4443) — WorkSpaces (private + NAT)
resource "aws_security_group_rule" "ssogen_sg_ingress_https_private_vpc" {
  type              = "ingress"
  from_port         = 4443
  to_port           = 4443
  protocol          = "tcp"
  description       = "OHS 4443 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_https_private_lz_aws_subnet" {
  type              = "ingress"
  from_port         = 4443
  to_port           = 4443
  protocol          = "tcp"
  description       = "OHS 4443 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_subnet_env]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_https_private_lz_aws_workspace_nonprod" {
  type              = "ingress"
  from_port         = 4443
  to_port           = 4443
  protocol          = "tcp"
  description       = "OHS 4443 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_https_private_lz_aws_workspace_prod" {
  type              = "ingress"
  from_port         = 4443
  to_port           = 4443
  protocol          = "tcp"
  description       = "OHS 4443 from WorkSpaces subnets (private)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_https_nat_1" {
  type              = "ingress"
  from_port         = 4443
  to_port           = 4443
  protocol          = "tcp"
  description       = "OHS 4443 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["18.130.39.94/32"]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_https_nat_2" {
  type              = "ingress"
  from_port         = 4443
  to_port           = 4443
  protocol          = "tcp"
  description       = "OHS 4443 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["35.177.145.193/32"]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_https_nat_3" {
  type              = "ingress"
  from_port         = 4443
  to_port           = 4443
  protocol          = "tcp"
  description       = "OHS 4443 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["52.56.212.11/32"]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_https_nat_4" {
  type              = "ingress"
  from_port         = 4443
  to_port           = 4443
  protocol          = "tcp"
  description       = "OHS 4443 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["35.176.254.38/32"]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_https_nat_5" {
  type              = "ingress"
  from_port         = 4443
  to_port           = 4443
  protocol          = "tcp"
  description       = "OHS 4443 from WorkSpaces NAT IPs (public)"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["35.177.173.197/32"]
}

# WebLogic managed servers (8000–8005) — internal app comms only
resource "aws_security_group_rule" "ssogen_sg_ingress_weblogic_managed" {
  type                     = "ingress"
  from_port                = 8000
  to_port                  = 8005
  protocol                 = "tcp"
  description              = "WebLogic managed servers from EBS App servers"
  security_group_id        = aws_security_group.ssogen_sg.id
  source_security_group_id = aws_security_group.ec2_sg_ebsapps.id
}

# Node Manager (5556) — intra-cluster only
resource "aws_security_group_rule" "ssogen_sg_ingress_nodemanager_self" {
  type                     = "ingress"
  from_port                = 5556
  to_port                  = 5556
  protocol                 = "tcp"
  description              = "WL Node Manager intra-SG"
  security_group_id        = aws_security_group.ssogen_sg.id
  source_security_group_id = aws_security_group.ssogen_sg.id
}

# ---- TEMP: ICMP for troubleshooting ----
# Allow ICMP Echo Requests to *this* SG from:
#  - Other SSOGEN instances (self)
#  - WorkSpaces subnets
resource "aws_security_group_rule" "ssogen_sg_ingress_icmp_self" {
  type                     = "ingress"
  from_port                = 8
  to_port                  = 0
  protocol                 = "icmp"
  description              = "TEMP: ICMP Echo from SSOGEN (self)"
  security_group_id        = aws_security_group.ssogen_sg.id
  source_security_group_id = aws_security_group.ssogen_sg.id
}

resource "aws_security_group_rule" "ssogen_sg_ingress_icmp_workspaces_nonprod" {
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  description       = "TEMP: ICMP Echo from WorkSpaces subnets"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env]
}
resource "aws_security_group_rule" "ssogen_sg_ingress_icmp_workspaces_prod" {
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  description       = "TEMP: ICMP Echo from WorkSpaces subnets"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}
# ---- END TEMP ----

############################################################
# ✅ EGRESS — Allow SSOGEN to reach dependencies
############################################################

# Oracle LDAP (non-SSL)
resource "aws_security_group_rule" "ssogen_sg_egress_ldap" {
  type              = "egress"
  from_port         = 1389
  to_port           = 1389
  protocol          = "tcp"
  description       = "Oracle LDAP"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["10.0.0.0/8"]
}

# Oracle LDAP (SSL)
resource "aws_security_group_rule" "ssogen_sg_egress_ldap_ssl" {
  type              = "egress"
  from_port         = 1636
  to_port           = 1636
  protocol          = "tcp"
  description       = "Oracle LDAP SSL"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["10.0.0.0/8"]
}

# Outbound HTTPS
resource "aws_security_group_rule" "ssogen_sg_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  description       = "Allow outbound HTTPS"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Outbound HTTP
resource "aws_security_group_rule" "ssogen_sg_egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  description       = "Allow outbound HTTP"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ---- TEMP: ICMP egress so these hosts can ping VPC/WorkSpaces ----
resource "aws_security_group_rule" "ssogen_sg_egress_icmp_vpc" {
  type              = "egress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  description       = "TEMP: ICMP Echo egress to VPC + WorkSpaces"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}
resource "aws_security_group_rule" "ssogen_sg_egress_icmp_workspaces_nonprod" {
  type              = "egress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  description       = "TEMP: ICMP Echo egress to VPC + WorkSpaces"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env]
}
resource "aws_security_group_rule" "ssogen_sg_egress_icmp_workspaces_prod" {
  type              = "egress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  description       = "TEMP: ICMP Echo egress to VPC + WorkSpaces"
  security_group_id = aws_security_group.ssogen_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env]
}
# ---- END TEMP ----