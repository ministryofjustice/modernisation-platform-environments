# Security Group for shared ClamAV Server

resource "aws_security_group" "clamav" {
  name        = "${local.application_name}-clamav-sg"
  description = "Security Group for shared ClamAV Server"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = "${local.application_name}-clamav-sg" }
  )
}

# INGRESS Rules

# PUI ECS task SG, managed in the ccms-feasibility/ccms-pui stack
data "aws_security_group" "pui_ecs_tasks" {
  vpc_id = data.aws_vpc.shared.id
  name   = "ccms-pui-${local.env_label}-ecs-tasks-sg"
}

resource "aws_vpc_security_group_ingress_rule" "clamav_from_pui_ecs_tasks" {
  security_group_id            = aws_security_group.clamav.id
  description                  = "Allow ClamAV from the ccms-pui ECS tasks"
  ip_protocol                  = "tcp"
  from_port                    = 3310
  to_port                      = 3310
  referenced_security_group_id = data.aws_security_group.pui_ecs_tasks.id
}

# EBS DB SG, managed in the ccms-feasibility/ccms-ebs stack
data "aws_security_group" "ebsdb" {
  vpc_id = data.aws_vpc.shared.id
  name   = "ccms-ebs-${local.env_label}-ebsdb-sg"
}

resource "aws_vpc_security_group_ingress_rule" "clamav_from_ebsdb" {
  security_group_id            = aws_security_group.clamav.id
  description                  = "Allow ClamAV from the ccms-ebs database tier"
  ip_protocol                  = "tcp"
  from_port                    = 3310
  to_port                      = 3310
  referenced_security_group_id = data.aws_security_group.ebsdb.id
}

# EGRESS Rules

resource "aws_vpc_security_group_egress_rule" "clamav_https" {
  security_group_id = aws_security_group.clamav.id
  description       = "Outbound HTTPS for virus definition updates"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
