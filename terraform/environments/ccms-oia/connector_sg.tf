# Connector Load Balancer Security Group

resource "aws_security_group" "connector_load_balancer" {
  name_prefix = "${local.connector_app_name}-load-balancer-sg"
  description = "Controls access to ${local.connector_app_name} lb"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-lb-sg", local.connector_app_name)) }
  )
}

# HTTPS ingress from private subnets
resource "aws_vpc_security_group_ingress_rule" "connector_alb_ingress_443_a" {
  security_group_id = aws_security_group.connector_load_balancer.id
  cidr_ipv4         = data.aws_subnet.private_subnets_a.cidr_block
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS from private subnet A"
}

resource "aws_vpc_security_group_ingress_rule" "connector_alb_ingress_443_b" {
  security_group_id = aws_security_group.connector_load_balancer.id
  cidr_ipv4         = data.aws_subnet.private_subnets_b.cidr_block
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS from private subnet B"
}

resource "aws_vpc_security_group_ingress_rule" "connector_alb_ingress_443_c" {
  security_group_id = aws_security_group.connector_load_balancer.id
  cidr_ipv4         = data.aws_subnet.private_subnets_c.cidr_block
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS from private subnet C"
}

# Allow all outbound (to be restricted later)
resource "aws_vpc_security_group_egress_rule" "connector_alb_egress_all" {
  security_group_id = aws_security_group.connector_load_balancer.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic (to be locked down later)"
}


# Container Security Group

resource "aws_security_group" "ecs_tasks_connector" {
  name_prefix = "${local.connector_app_name}-ecs-tasks-security-group"
  description = "Controls access to ${local.connector_app_name} containers"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-task-sg", local.connector_app_name)) }
  )
}

# Ingress from Connector ALB to ECS containers
resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_connector_ingress" {
  security_group_id            = aws_security_group.ecs_tasks_connector.id
  referenced_security_group_id = aws_security_group.connector_load_balancer.id
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].connector_server_port
  to_port                      = local.application_data.accounts[local.environment].connector_server_port
  description                  = "Allow ALB to reach Connector container port"
}

# All outbound traffic from ECS containers
resource "aws_vpc_security_group_egress_rule" "ecs_tasks_connector_egress_all" {
  security_group_id = aws_security_group.ecs_tasks_connector.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}