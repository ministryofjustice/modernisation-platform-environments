############################################
# Security Group (no inline rules) — dev only
############################################
resource "aws_security_group" "ssogen_sg" {
  count       = local.ssogen_enabled ? 1 : 0
  name        = "ssogen-sg-${local.environment}"
  description = "Security group for SSOGEN EC2 (WebLogic + OHS)"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, { Name = "ssogen-sg-${local.environment}" })
}

# ############################################
# # TEMP INGRESS — 4443 from WorkSpaces subnets (private)
# ############################################
resource "aws_vpc_security_group_ingress_rule" "ing_4443_workspaces" {
  count             = local.ssogen_enabled ? 1 : 0
  ip_protocol       = "tcp"
  description       = "4443 from WorkSpaces subnets"
  security_group_id = aws_security_group.ssogen_sg[count.index].id
  from_port         = 4443
  to_port           = 4443
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

# ############################################
# # INGRESS — 7001 within ec2 instances
# ############################################
resource "aws_vpc_security_group_ingress_rule" "ing_console_ec2" {
  count                        = local.ssogen_enabled ? 1 : 0
  ip_protocol                  = "tcp"
  description                  = "7001 from EC2 instances"
  security_group_id            = aws_security_group.ssogen_sg[count.index].id
  from_port                    = 7001
  to_port                      = 7001
  referenced_security_group_id = aws_security_group.ssogen_sg[count.index].id
}

# ############################################
# # INGRESS — 7003 within ec2 instances
# ############################################
resource "aws_vpc_security_group_ingress_rule" "ing_console_ec2_7003" {
  count                        = local.ssogen_enabled ? 1 : 0
  ip_protocol                  = "tcp"
  description                  = "7003 from EC2 instances"
  security_group_id            = aws_security_group.ssogen_sg[count.index].id
  from_port                    = 7003
  to_port                      = 7003
  referenced_security_group_id = aws_security_group.ssogen_sg[count.index].id
}
# ############################################
# # INGRESS — SSH (22) from WorkSpaces subnets (private)
# ############################################
resource "aws_vpc_security_group_ingress_rule" "ing_ssh_workspaces" {
  count             = local.ssogen_enabled ? 1 : 0
  ip_protocol       = "tcp"
  description       = "SSH from WorkSpaces subnets"
  security_group_id = aws_security_group.ssogen_sg[count.index].id
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

# #########################################
# # SSOGEN Security Group — Allow outbound 7001 from EC2 to EC2 (self)
# #########################################

resource "aws_vpc_security_group_egress_rule" "from_ec2_to_ec2" {
  count                        = local.ssogen_enabled ? 1 : 0
  security_group_id            = aws_security_group.ssogen_sg[count.index].id
  description                  = "Allow outbound to EC2 (self)"
  from_port                    = 7001
  to_port                      = 7001
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ssogen_sg[count.index].id
}

# #########################################
# # SSOGEN Security Group — Allow outbound 7003 from EC2 to EC2 (self)
# #########################################

resource "aws_vpc_security_group_egress_rule" "from_ec2_to_ec2_7003" {
  count                        = local.ssogen_enabled ? 1 : 0
  security_group_id            = aws_security_group.ssogen_sg[count.index].id
  description                  = "Allow outbound to EC2 (self)"
  from_port                    = 7003
  to_port                      = 7003
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ssogen_sg[count.index].id
}

# #########################################
# # SSOGEN Security Group — Allow outbound from ec2 to RDS
# #########################################

resource "aws_vpc_security_group_egress_rule" "from_ec2_to_rds" {
  count                        = local.ssogen_enabled ? 1 : 0
  security_group_id            = aws_security_group.ssogen_sg[count.index].id
  description                  = "Allow outbound to RDS"
  from_port                    = local.application_data.accounts[local.environment].tg_db_port
  to_port                      = local.application_data.accounts[local.environment].tg_db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ec2_sg_ebsdb.id
}

# #########################################
# # SSOGEN Security Group — Allow Outbound 443 from ssogen EC2 to SSM (for Session Manager)
# #########################################

resource "aws_vpc_security_group_egress_rule" "from_ec2_to_ssm" {
  count             = local.ssogen_enabled ? 1 : 0
  security_group_id = aws_security_group.ssogen_sg[count.index].id
  description       = "Allow outbound to SSM"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# #########################################
# # SSOGEN Security Group — Allow inbound 7001 from ALB
# #########################################

resource "aws_vpc_security_group_egress_rule" "from_ec2_to_efs" {
  count                        = local.ssogen_enabled ? 1 : 0
  security_group_id            = aws_security_group.ssogen_sg[count.index].id
  description                  = "Allow outbound to EFS"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.efs-security-group[0].id
}

# #########################################
# # SSOGEN Security Group — Allow inbound 4443 from ALB
# #########################################

resource "aws_vpc_security_group_ingress_rule" "ing_4443_from_alb" {
  count                        = local.ssogen_enabled ? 1 : 0
  security_group_id            = aws_security_group.ssogen_sg[0].id
  description                  = "Allow inbound HTTPS (4443) from SSOGEN internal ALB"
  from_port                    = 4443
  to_port                      = 4443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.sg_ssogen_internal_alb[count.index].id
}
