######################################
### RDS SG
######################################
resource "aws_security_group" "rds_sg" {
  count = local.environment == "preproduction" ? 1 : 0

  name        = "${local.application_name}-${local.environment}-rds-security-group"
  description = "RDS Security Group"
  vpc_id      = data.aws_vpc.shared.id

  revoke_rules_on_delete = true

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-rds-security-group" }
  )
}


######################################
### RDS SG Ingress Rules
######################################
# Allow inbound from OAS application over TLS/SSL
resource "aws_security_group_rule" "ingress_rds_from_oas" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.rds_sg[0].id
  from_port         = 1521
  to_port           = 1521
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  description       = "Oracle connections from OAS over TLS"
}

resource "aws_security_group_rule" "ingress_rds_from_workspaces" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.rds_sg[0].id
  from_port         = 1521
  to_port           = 1521
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
  description       = "SQL Developer from Workspaces (troubleshooting only)"
}

######################################
### RDS SG Egress Rules
######################################
# Allow outbound to OAS application
resource "aws_security_group_rule" "rds_sg_egress_oas" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.rds_sg[0].id
  from_port         = 1521
  to_port           = 1521
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  description       = "Oracle responses to OAS"
}

resource "aws_security_group_rule" "rds_sg_egress_workspaces" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.rds_sg[0].id
  from_port         = 1521
  to_port           = 1521
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
  description       = "SQL Developer responses to Workspaces"
}