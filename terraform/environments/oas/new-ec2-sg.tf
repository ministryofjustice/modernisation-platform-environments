######################################
### EC2 SG
######################################
resource "aws_security_group" "ec2_sg" {
  count = local.environment == "preproduction" ? 1 : 0

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
resource "aws_security_group_rule" "ingress_oas_db_1521" {
  count = local.environment == "preproduction" ? 1 : 0

  type                     = "ingress"
  security_group_id        = aws_security_group.ec2_sg[0].id
  from_port                = 1521
  to_port                  = 1521
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds_sg[0].id
  description              = "Database connections to OAS RDS"
}

resource "aws_security_group_rule" "ingress_ssh_from_bastion" {
  count = local.environment == "preproduction" ? 1 : 0

  type                     = "ingress"
  security_group_id        = aws_security_group.ec2_sg[0].id
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = module.bastion_linux.bastion_security_group
  description              = "SSH from the Bastion"
}

resource "aws_security_group_rule" "ingress_ssh_from_workspaces" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
  description       = "SSH from Workspaces"
}

resource "aws_security_group_rule" "ingress_http_from_mojo" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  description       = "HTTP from Mojo"
}

resource "aws_security_group_rule" "ingress_https_from_mojo" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  description       = "HTTPS from Mojo"
}

resource "aws_security_group_rule" "ingress_admin_vpc" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "access to the admin server"
  from_port         = 9500
  to_port           = 9500
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "ingress_from_lb_9500" {
  count = local.environment == "preproduction" ? 1 : 0

  type                     = "ingress"
  security_group_id        = aws_security_group.ec2_sg[0].id
  description              = "Allow traffic from load balancer to EC2 on port 9500"
  from_port                = 9500
  to_port                  = 9500
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb_security_group[0].id
}

resource "aws_security_group_rule" "ingress_from_lb_9502" {
  count = local.environment == "preproduction" ? 1 : 0

  type                     = "ingress"
  security_group_id        = aws_security_group.ec2_sg[0].id
  description              = "Allow traffic from load balancer to EC2 on port 9502"
  from_port                = 9502
  to_port                  = 9502
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb_security_group[0].id
}

resource "aws_security_group_rule" "ingress_admin_workspace" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the admin server from workspace"
  from_port         = 9500
  to_port           = 9500
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
}

resource "aws_security_group_rule" "ingress_9500_from_mojo" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9500
  to_port           = 9500
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  description       = "9500 from Mojo"
}

resource "aws_security_group_rule" "ingress_admin_9501_vpc" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "access to the admin server"
  from_port         = 9501
  to_port           = 9501
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "ingress_admin_9501_workspace" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the admin server from workspace"
  from_port         = 9501
  to_port           = 9501
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
}

resource "aws_security_group_rule" "ingress_managed_9502_vpc" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the managed server"
  from_port         = 9502
  to_port           = 9502
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "ingress_managed_9502_workspace" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the managed server from workspace"
  from_port         = 9502
  to_port           = 9502
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
}

resource "aws_security_group_rule" "ingress_9502_from_mojo" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9502
  to_port           = 9502
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  description       = "9502 from Mojo"
}

resource "aws_security_group_rule" "ingress_managed_9503_vpc" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the managed server"
  from_port         = 9503
  to_port           = 9503
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "ingress_managed_9503_workspace" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the managed server from workspace"
  from_port         = 9503
  to_port           = 9503
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
}

resource "aws_security_group_rule" "ingress_managed_9505_vpc" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the managed server"
  from_port         = 9505
  to_port           = 9505
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "ingress_managed_9505_workspace" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the managed server from workspace"
  from_port         = 9505
  to_port           = 9505
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
}


resource "aws_security_group_rule" "ingress_managed_9514_vpc" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the managed server"
  from_port         = 9514
  to_port           = 9514
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "ingress_managed_9514_workspace" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the managed server from workspace"
  from_port         = 9514
  to_port           = 9514
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
}

######################################
### EC2 EGRESS RULES
######################################
resource "aws_security_group_rule" "egress_oas_db_1521" {
  count = local.environment == "preproduction" ? 1 : 0

  type                     = "egress"
  security_group_id        = aws_security_group.ec2_sg[0].id
  from_port                = 1521
  to_port                  = 1521
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds_sg[0].id
  description              = "Database connections to OAS RDS"
}

resource "aws_security_group_rule" "egress_https_s3" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [local.application_data.accounts[local.environment].s3_vpc_endpoint_prefix]
  description       = "Outbound 443 to LAA VPC Endpoint SG"
}

resource "aws_security_group_rule" "egress_http_internet" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Outbound HTTP for yum repositories"
}

resource "aws_security_group_rule" "egress_https_internet" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Outbound HTTPS for yum repositories and SSM"
}

resource "aws_security_group_rule" "egress_admin_vpc" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "access to the admin server"
  from_port         = 9500
  to_port           = 9500
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_9500_mojo" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9500
  to_port           = 9500
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  description       = "9500 to Mojo"
}

resource "aws_security_group_rule" "egress_admin_workspace" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the admin server from workspace"
  from_port         = 9500
  to_port           = 9500
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
}

resource "aws_security_group_rule" "egress_admin_9501_vpc" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "access to the admin server"
  from_port         = 9501
  to_port           = 9501
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_admin_9501_workspace" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the admin server from workspace"
  from_port         = 9501
  to_port           = 9501
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
}

resource "aws_security_group_rule" "egress_managed_9502_vpc" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the managed server"
  from_port         = 9502
  to_port           = 9502
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_managed_9502_workspace" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the managed server from workspace"
  from_port         = 9502
  to_port           = 9502
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
}

resource "aws_security_group_rule" "egress_9502_mojo" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 9502
  to_port           = 9502
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  description       = "9502 to Mojo"
}

resource "aws_security_group_rule" "egress_managed_9503_vpc" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the managed server"
  from_port         = 9503
  to_port           = 9503
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_managed_9503_workspace" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the managed server from workspace"
  from_port         = 9503
  to_port           = 9503
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
}

resource "aws_security_group_rule" "egress_managed_9505_vpc" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the managed server"
  from_port         = 9505
  to_port           = 9505
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_managed_9505_workspace" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the managed server from workspace"
  from_port         = 9505
  to_port           = 9505
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
}


resource "aws_security_group_rule" "egress_managed_9514_vpc" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the managed server"
  from_port         = 9514
  to_port           = 9514
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_managed_9514_workspace" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  description       = "Access to the managed server from workspace"
  from_port         = 9514
  to_port           = 9514
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
}