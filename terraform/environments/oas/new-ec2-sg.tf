######################################
### EC2 SG
######################################
resource "aws_security_group" "ec2_sg" {
  count       = local.environment == "preproduction" ? 1 : 0

  name        = "${local.application_name}-${local.environment}-ec2-security-group"
  description = "EC2 Security Group"
  vpc_id      = data.aws_vpc.shared.id

  revoke_rules_on_delete = true

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-ec2-security-group" }
  )
}

######################################
### EC2 INGRESS RULES
######################################
resource "aws_security_group_rule" "ingress_admin_vpc" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9500
  to_port           = 9500
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  description       = "access to the admin server"
}

resource "aws_security_group_rule" "ingress_admin_workspace" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9500
  to_port           = 9500
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
  description       = "Access to the admin server from workspace"
}

resource "aws_security_group_rule" "ingress_managed_vpc_9502" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9502
  to_port           = 9502
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  description       = "Access to the managed server"
}

resource "aws_security_group_rule" "ingress_managed_workspace_9502" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9502
  to_port           = 9502
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
  description       = "Access to the managed server from workspace"
}

resource "aws_security_group_rule" "ingress_managed_lz_9502" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9502
  to_port           = 9502
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].inbound_cidr_lz]
  description       = "Access to the managed server from laa development"
}

resource "aws_security_group_rule" "ingress_managed_vpc_9505" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9505
  to_port           = 9505
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  description       = "Access to the managed server"
}

resource "aws_security_group_rule" "ingress_managed_workspace_9505" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9505
  to_port           = 9505
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
  description       = "Access to the managed server from workspace"
}

resource "aws_security_group_rule" "ingress_managed_lz_9505" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9505
  to_port           = 9505
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].inbound_cidr_lz]
  description       = "Access to the managed server from laa development"
}

resource "aws_security_group_rule" "ingress_managed_vpc_9514" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9514
  to_port           = 9514
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  description       = "Access to the managed server"
}

resource "aws_security_group_rule" "ingress_managed_workspace_9514" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9514
  to_port           = 9514
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
  description       = "Access to the managed server from workspace"
}

resource "aws_security_group_rule" "ingress_ssh_workspace" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
  description       = "ssh access to the managed server from workspace"
}

resource "aws_security_group_rule" "ingress_db_1521" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 1521
  to_port           = 1521
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  description       = "Database connections to rds apex edw and mojfin"
}

resource "aws_security_group_rule" "ingress_ldap_1389_vpc" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 1389
  to_port           = 1389
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  description       = "LDAP Server Connection"
}

resource "aws_security_group_rule" "ingress_http_lz_80" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].inbound_cidr_lz]
  description       = "http access from LZ to oas-mp to test connectivity"
}

resource "aws_security_group_rule" "ingress_http_lz_1389" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 1389
  to_port           = 1389
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].inbound_cidr_lz]
  description       = "http access from LZ to oas-mp to test connectivity"
}

resource "aws_security_group_rule" "ingress_http_lz_3443" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 3443
  to_port           = 3443
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].inbound_cidr_lz]
  description       = "http access from LZ to oas-mp to test connectivity"
}

resource "aws_security_group_rule" "ingress_ssh_from_bastion" {
  count = local.environment == "preproduction" ? 1 : 0

  type                    = "ingress"
  security_group_id       = aws_security_group.ec2_sg[0].id
  from_port               = 22
  to_port                 = 22
  protocol                = "tcp"
  source_security_group_id = module.bastion_linux.bastion_security_group
  description             = "SSH from the Bastion"
}

######################################
### EC2 EGRESS RULES
######################################
resource "aws_security_group_rule" "egress_ssm" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].outbound_access_cidr]
  description       = "Allow AWS SSM Session Manager"
}

resource "aws_security_group_rule" "egress_telnet_mojo" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 3443
  to_port           = 3443
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].outbound_access_cidr]
  description       = "Allow telnet to Portal - MoJo"
}

resource "aws_security_group_rule" "egress_admin_vpc" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9500
  to_port           = 9500
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  description       = "access to the admin server"
}

resource "aws_security_group_rule" "egress_admin_workspace" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9500
  to_port           = 9500
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
  description       = "Access to the admin server from workspace"
}

resource "aws_security_group_rule" "egress_managed_vpc_9502" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9502
  to_port           = 9502
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  description       = "Access to the managed server"
}

resource "aws_security_group_rule" "egress_managed_workspace_9502" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9502
  to_port           = 9502
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
  description       = "Access to the managed server from workspace"
}

resource "aws_security_group_rule" "egress_managed_vpc_9505" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9505
  to_port           = 9505
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  description       = "Access to the managed server"
}

resource "aws_security_group_rule" "egress_managed_workspace_9505" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9505
  to_port           = 9505
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
  description       = "Access to the managed server from workspace"
}

resource "aws_security_group_rule" "egress_managed_vpc_9514" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9514
  to_port           = 9514
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  description       = "Access to the managed server"
}

resource "aws_security_group_rule" "egress_managed_workspace_9514" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9514
  to_port           = 9514
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
  description       = "Access to the managed server from workspace"
}

resource "aws_security_group_rule" "egress_db_1521" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 1521
  to_port           = 1521
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  description       = "Database connections from rds apex edw and mojfin"
}

resource "aws_security_group_rule" "egress_ldap_1389_vpc" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 1389
  to_port           = 1389
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  description       = "LDAP Server Connection"
}

resource "aws_security_group_rule" "egress_http_outbound_80" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].outbound_access_cidr]
  description       = "Outbound internet access"
}

resource "aws_security_group_rule" "egress_http_lz_1389" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 1389
  to_port           = 1389
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].inbound_cidr_lz]
  description       = "http access from LZ to oas-mp to test connectivity"
}

resource "aws_security_group_rule" "egress_http_lz_1521" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 1521
  to_port           = 1521
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].inbound_cidr_lz]
  description       = "http access from LZ to oas-mp to test connectivity"
}
