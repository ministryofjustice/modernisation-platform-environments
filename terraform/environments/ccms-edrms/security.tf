# ### Load Balancer Security Group

# resource "aws_security_group" "load_balancer" {
#   name_prefix = "${local.application_name}-load-balancer-sg"
#   description = "Controls access to ${local.application_name} lb"
#   vpc_id      = data.aws_vpc.shared.id

#   tags = merge(local.tags,
#     { Name = lower(format("%s-%s-lb-sg", local.application_name, local.environment)) }
#   )
# }

# resource "aws_security_group_rule" "alb_ingress_443" {
#   security_group_id = aws_security_group.load_balancer.id
#   type              = "ingress"
#   description       = "HTTPS"
#   protocol          = "TCP"
#   from_port         = 443
#   to_port           = 443
#   cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
# }

# resource "aws_security_group_rule" "alb_egress_all" {
#   security_group_id = aws_security_group.load_balancer.id
#   type              = "egress"
#   description       = "All"
#   protocol          = -1
#   from_port         = 0
#   to_port           = 0
#   cidr_blocks       = ["0.0.0.0/0"]
# }


# ### Container Security Group

# resource "aws_security_group" "ecs_tasks_edrms" {
#   name_prefix = "${local.application_name}-ecs-tasks-security-group"
#   description = "Controls access to ${local.application_name} containers"
#   vpc_id      = data.aws_vpc.shared.id

#   tags = merge(local.tags,
#     { Name = lower(format("%s-%s-task-sg", local.application_name, local.environment)) }
#   )
# }

# resource "aws_security_group_rule" "ecs_tasks_edrms" {
#   security_group_id = aws_security_group.ecs_tasks_edrms.id
#   type              = "ingress"
#   description       = "EDRMS Server Port"
#   protocol          = "TCP"
#   from_port         = local.application_data.accounts[local.environment].edrms_server_port
#   to_port           = local.application_data.accounts[local.environment].edrms_server_port
#   cidr_blocks       = [
#       aws_security_group.load_balancer.id,
#     ]
# }

# resource "aws_security_group_rule" "ecs_tasks_egress_all" {
#   security_group_id = aws_security_group.ecs_tasks_edrms.id
#   type              = "egress"
#   description       = "All"
#   protocol          = -1
#   from_port         = 0
#   to_port           = 0
#   cidr_blocks       = ["0.0.0.0/0"]
# }
