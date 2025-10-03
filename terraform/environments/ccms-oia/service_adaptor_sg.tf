#######################################
# adaptor Load Balancer Security Group
#######################################

resource "aws_security_group" "adaptor_load_balancer" {
  name_prefix = "${local.adaptor_app_name}-load-balancer-sg"
  description = "Controls access to ${local.adaptor_app_name} lb"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-lb-sg", local.adaptor_app_name)) }
  )
}

resource "aws_security_group_rule" "adaptor_alb_ingress_443" {
  security_group_id = aws_security_group.adaptor_load_balancer.id
  type              = "ingress"
  description       = "HTTPS"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "adaptor_alb_egress_all" {
  security_group_id = aws_security_group.adaptor_load_balancer.id
  type              = "egress"
  description       = "All outbound"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"] # Will need to be locked down later
}

#######################################
# Container Security Group
#######################################

resource "aws_security_group" "ecs_tasks_adaptor" {
  name_prefix = "${local.adaptor_app_name}-ecs-tasks-security-group"
  description = "Controls access to ${local.adaptor_app_name} containers"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-task-sg", local.adaptor_app_name)) }
  )
}

resource "aws_security_group_rule" "ecs_tasks_adaptor_ingress" {
  security_group_id        = aws_security_group.ecs_tasks_adaptor.id
  type                     = "ingress"
  description              = "adaptor App Port"
  protocol                 = "TCP"
  from_port                = local.application_data.accounts[local.environment].adaptor_server_port
  to_port                  = local.application_data.accounts[local.environment].adaptor_server_port
  source_security_group_id = aws_security_group.adaptor_load_balancer.id
}

resource "aws_security_group_rule" "ecs_tasks_adaptor_egress_all" {
  security_group_id = aws_security_group.ecs_tasks_adaptor.id
  type              = "egress"
  description       = "All outbound"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}