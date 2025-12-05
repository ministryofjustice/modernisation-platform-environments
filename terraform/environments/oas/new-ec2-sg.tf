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
  type              = "egress"
  security_group_id = aws_security_group.ec2_sg[0].id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [local.application_data.accounts[local.environment].s3_vpc_endpoint_prefix]
  description       = "Outbound 443 to LAA VPC Endpoint SG"
}
