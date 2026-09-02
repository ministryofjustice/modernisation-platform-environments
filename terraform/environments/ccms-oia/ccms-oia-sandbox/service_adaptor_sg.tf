# Adaptor Load Balancer Security Group

resource "aws_security_group" "adaptor_load_balancer" {
  name_prefix = "${local.adaptor_app_name}-load-balancer-sg"
  description = "Controls access to ${local.adaptor_app_name} lb"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-lb-sg", local.adaptor_app_name)) }
  )
}

# HTTPS ingress from private subnets
resource "aws_vpc_security_group_ingress_rule" "adaptor_alb_ingress_443_a" {
  security_group_id = aws_security_group.adaptor_load_balancer.id
  cidr_ipv4         = data.aws_subnet.private_subnets_a.cidr_block
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS from private subnet A"
}

resource "aws_vpc_security_group_ingress_rule" "adaptor_alb_ingress_443_b" {
  security_group_id = aws_security_group.adaptor_load_balancer.id
  cidr_ipv4         = data.aws_subnet.private_subnets_b.cidr_block
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS from private subnet B"
}

resource "aws_vpc_security_group_ingress_rule" "adaptor_alb_ingress_443_c" {
  security_group_id = aws_security_group.adaptor_load_balancer.id
  cidr_ipv4         = data.aws_subnet.private_subnets_c.cidr_block
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS from private subnet C"
}

# All outbound traffic (to be locked down later)
# resource "aws_vpc_security_group_egress_rule" "adaptor_alb_egress_all" {
#   security_group_id = aws_security_group.adaptor_load_balancer.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1"
#   description       = "Allow all outbound traffic (to be restricted later)"
# }
# Restricted outbound traffic to OIA EC2 instances
resource "aws_security_group_rule" "adaptor_alb_egress_oia_ec2" {
  security_group_id        = aws_security_group.adaptor_load_balancer.id
  type                     = "egress"
  description              = "Allow ALB egress to OIA EC2 instances on ephemeral ports"
  protocol                 = "tcp"
  from_port                = local.application_data.accounts[local.environment].adaptor_server_port
  to_port                  = local.application_data.accounts[local.environment].adaptor_server_port
  source_security_group_id = aws_security_group.cluster_ec2.id
}

# Adapter Security Group


resource "aws_security_group" "ecs_tasks_adaptor" {
  name_prefix = "${local.adaptor_app_name}-ecs-tasks-security-group"
  description = "Controls access to ${local.adaptor_app_name} containers"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-task-sg", local.adaptor_app_name)) }
  )
}

# Ingress from ALB to ECS container port
resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_adaptor_ingress" {
  security_group_id            = aws_security_group.ecs_tasks_adaptor.id
  referenced_security_group_id = aws_security_group.adaptor_load_balancer.id
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].adaptor_server_port
  to_port                      = local.application_data.accounts[local.environment].adaptor_server_port
  description                  = "Allow ALB to reach adaptor container port"
}

# All outbound traffic from ECS tasks
# resource "aws_vpc_security_group_egress_rule" "ecs_tasks_adaptor_egress_all" {
#   security_group_id = aws_security_group.ecs_tasks_adaptor.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1"
#   description       = "Allow all outbound traffic"
# }

resource "aws_security_group_rule" "ecs_tasks_adaptor_egress_vpce" {
  security_group_id = aws_security_group.ecs_tasks_adaptor.id
  type              = "egress"
  description       = "Allow egress to VPC endpoints (logs/ecs/secrets)"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks = [
    data.aws_subnet.vpce_subnets_a.cidr_block,
    data.aws_subnet.vpce_subnets_b.cidr_block,
    data.aws_subnet.vpce_subnets_c.cidr_block,
  ]
}

resource "aws_security_group_rule" "ecs_tasks_adaptor_egress_s3" {
  security_group_id = aws_security_group.ecs_tasks_adaptor.id
  type              = "egress"
  description       = "Allow S3 access via gateway endpoint (prefix list)"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_ids   = [data.aws_prefix_list.s3.id]
}

resource "aws_security_group_rule" "ecs_tasks_adaptor_egress_443" {
  security_group_id = aws_security_group.ecs_tasks_adaptor.id
  type              = "egress"
  description       = "HTTPS"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]
}

resource "aws_security_group_rule" "ecs_tasks_adaptor_egress_1521" {
  security_group_id = aws_security_group.ecs_tasks_adaptor.id
  type              = "egress"
  description       = "Allow egress to protected subnets"
  protocol          = "tcp"
  from_port         = 1521
  to_port           = 1521
  cidr_blocks = [
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block,
  ]
}

resource "aws_security_group_rule" "ecs_tasks_adaptor_egress_1522" {
  security_group_id = aws_security_group.ecs_tasks_adaptor.id
  type              = "egress"
  description       = "Allow egress to protected subnets on port 1522"
  protocol          = "tcp"
  from_port         = 1522
  to_port           = 1522
  cidr_blocks = [
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block,
  ]
}

resource "aws_security_group_rule" "ecs_tasks_adaptor_egress_2049_efs" {
  security_group_id        = aws_security_group.ecs_tasks_adaptor.id
  type                     = "egress"
  description              = "Allow egress to EFS security group on port 2049"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  source_security_group_id = aws_security_group.oia-efs-security-group.id
}

resource "aws_security_group_rule" "ecs_tasks_adaptor_egress_ecs_tasks" {
  security_group_id        = aws_security_group.ecs_tasks_adaptor.id
  type                     = "egress"
  description              = "Allow egress to container tasks"
  protocol                 = "tcp"
  from_port                = local.application_data.accounts[local.environment].adaptor_server_port
  to_port                  = local.application_data.accounts[local.environment].adaptor_server_port
}