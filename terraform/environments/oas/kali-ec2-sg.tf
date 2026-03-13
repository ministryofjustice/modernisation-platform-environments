resource "aws_security_group" "kali_sg" {
  count = local.environment == "preproduction" ? 1 : 0

  name        = "${local.application_name}-${local.environment}-ec2-kali-security-group"
  description = "Kali EC2 Security Group"
  vpc_id      = data.aws_vpc.shared.id

  revoke_rules_on_delete = true

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-ec2-kali-security-group" }
  )
}

######################################
### KALI EGRESS TO OAS INTERNAL VPC
######################################

resource "aws_security_group_rule" "kali_to_oas_vpc_all" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.kali_sg[0].id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]

  description = "Allow Kali to reach OAS internal VPC ranges on all ports and protocols for security testing"
}

######################################
### KALI OUTBOUND FOR SSM / UPDATES
######################################

resource "aws_security_group_rule" "kali_outbound_https" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.kali_sg[0].id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]

  description = "Outbound HTTPS for SSM and package repositories"
}

resource "aws_security_group_rule" "kali_outbound_http" {
  count = local.environment == "preproduction" ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.kali_sg[0].id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]

  description = "Outbound HTTP for package repositories"
}