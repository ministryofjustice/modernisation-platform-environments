#######################################
# OPAHUB Load Balancer Security Group
#######################################

resource "aws_security_group" "opahub_load_balancer" {
  name_prefix = "${local.opa_app_name}-load-balancer-sg"
  description = "Controls access to ${local.opa_app_name} lb"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-lb-sg", local.application_name)) }
  )
}

# resource "aws_security_group_rule" "alb_ingress_443" {
#   security_group_id = aws_security_group.opahub_load_balancer.id
#   type              = "ingress"
#   description       = "HTTPS"
#   protocol          = "TCP"
#   from_port         = 443
#   to_port           = 443
#   cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
# }

# resource "aws_security_group_rule" "alb_ingress_443_workspaces" {
#   security_group_id = aws_security_group.opahub_load_balancer.id
#   type              = "ingress"
#   description       = "HTTPS from AWS Workspaces"
#   protocol          = "TCP"
#   from_port         = 443
#   to_port           = 443
#   cidr_blocks       = [local.application_data.accounts[local.environment].aws_workspace]
# }

# Allow traffic from anywhere - WAF will control access
resource "aws_security_group_rule" "alb_ingress_443_all" {
  security_group_id = aws_security_group.opahub_load_balancer.id
  type              = "ingress"
  description       = "HTTPS from AWS Workspaces"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "alb_egress_all" {
  security_group_id = aws_security_group.opahub_load_balancer.id
  type              = "egress"
  description       = "All outbound"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

#######################################
# Container Security Group
#######################################

resource "aws_security_group" "ecs_tasks_opa" {
  name_prefix = "${local.opa_app_name}-ecs-tasks-security-group"
  description = "Controls access to ${local.opa_app_name} containers"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-task-sg", local.opa_app_name)) }
  )
}

resource "aws_security_group_rule" "ecs_tasks_opa_ingress" {
  security_group_id        = aws_security_group.ecs_tasks_opa.id
  type                     = "ingress"
  description              = "OPAHUB App Port"
  protocol                 = "TCP"
  from_port                = local.application_data.accounts[local.environment].opa_server_port
  to_port                  = local.application_data.accounts[local.environment].opa_server_port
  source_security_group_id = aws_security_group.opahub_load_balancer.id
}

resource "aws_security_group_rule" "ecs_tasks_opa_egress_all" {
  security_group_id = aws_security_group.ecs_tasks_opa.id
  type              = "egress"
  description       = "All outbound"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}


#######################################
# RDS Security Group
#######################################

resource "aws_security_group" "opahub_db" {
  name        = "${local.opa_app_name}-mysql-db"
  description = "Allow MySQL DB inbound traffic"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-mysql-sg", local.opa_app_name)) }
  )
}

resource "aws_security_group_rule" "opahub_db_ingress" {
  security_group_id        = aws_security_group.opahub_db.id
  type                     = "ingress"
  description              = "MySQL access from ECS tasks"
  protocol                 = "TCP"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.ecs_tasks_opa.id
}

resource "aws_security_group_rule" "opahub_db_egress_all" {
  security_group_id = aws_security_group.opahub_db.id
  type              = "egress"
  description       = "All outbound"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}
