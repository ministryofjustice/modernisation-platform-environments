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
resource "aws_security_group_rule" "rds_sg_ingress_vpc_shared_cidr" {
  count = local.environment == "preproduction" ? 1 : 0

  type                     = "ingress"
  security_group_id        = aws_security_group.rds_sg[0].id
  from_port                = 1521
  to_port                  = 1521
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_sg[0].id
  description              = "Database connections to OAS RDS"
}

######################################
### RDS SG Egress Rules
######################################
resource "aws_security_group_rule" "rds_sg_egress_vpc_shared_cidr" {
  count = local.environment == "preproduction" ? 1 : 0

  type                     = "egress"
  security_group_id        = aws_security_group.rds_sg[0].id
  from_port                = 1521
  to_port                  = 1521
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_sg[0].id
  description              = "Database connections to OAS RDS"
}