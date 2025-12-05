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
resource "aws_security_group_rule" "rds_sg_ingress_oracle_lz_cidr" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  from_port         = 1521
  to_port           = 1521
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_vpc_cidr]
  security_group_id = aws_security_group.rds_sg[0].id
  description       = "Sql Net on 1521"
}

resource "aws_security_group_rule" "rds_sg_ingress_oracle_man_cidr" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  from_port         = 1521
  to_port           = 1521
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
  security_group_id = aws_security_group.rds_sg[0].id
  description       = "Sql Net on 1521"
}

resource "aws_security_group_rule" "rds_sg_ingress_vpc_shared_cidr" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "ingress"
  from_port         = 1521
  to_port           = 1521
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.rds_sg[0].id
  description       = "Sql Net on 1521"
}

######################################
### RDS SG Egress Rules
######################################
resource "aws_security_group_rule" "rds_sg_egress_vpc_shared_cidr" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  from_port         = 1521
  to_port           = 1521
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.rds_sg[0].id
  description       = "Sql Net on 1521"
}