# OPAHUB Load Balancer Security Group

resource "aws_security_group" "opahub_load_balancer" {
  name_prefix = "${local.opa_app_name}-load-balancer-sg"
  description = "Controls access to ${local.opa_app_name} lb"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-lb-sg", local.opa_app_name)) }
  )
}

# # Temp only for first install - to be removed after
resource "aws_vpc_security_group_ingress_rule" "alb_ingress_7001_all" {
  security_group_id = aws_security_group.opahub_load_balancer.id
  cidr_ipv4         = local.application_data.accounts[local.environment].aws_workspace
  ip_protocol       = "tcp"
  from_port         = 7001
  to_port           = 7001
  description       = "7001 from anywhere (WAF controlled)"
}
resource "aws_vpc_security_group_ingress_rule" "alb_ingress_443_all" {
  security_group_id = aws_security_group.opahub_load_balancer.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS from anywhere (WAF controlled)"
}

resource "aws_vpc_security_group_egress_rule" "alb_egress_all" {
  security_group_id = aws_security_group.opahub_load_balancer.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}


# Container Security Group

resource "aws_security_group" "ecs_tasks_opa" {
  name_prefix = "${local.opa_app_name}-ecs-tasks-security-group"
  description = "Controls access to ${local.opa_app_name} containers"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-task-sg", local.opa_app_name)) }
  )
}

resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_opa_ingress" {
  security_group_id            = aws_security_group.ecs_tasks_opa.id
  referenced_security_group_id = aws_security_group.opahub_load_balancer.id
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].opa_server_port
  to_port                      = local.application_data.accounts[local.environment].opa_server_port
  description                  = "Allow ALB to reach ECS app port"
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_opa_egress_all" {
  security_group_id = aws_security_group.ecs_tasks_opa.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}


# RDS Security Group

resource "aws_security_group" "opahub_db" {
  name        = "${local.opa_app_name}-mysql-db"
  description = "Allow MySQL DB inbound traffic"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-mysql-sg", local.opa_app_name)) }
  )
}

# Ingress from AWS Workspaces
resource "aws_vpc_security_group_ingress_rule" "opahub_db_ingress_workspaces" {
  security_group_id = aws_security_group.opahub_db.id
  cidr_ipv4         = local.application_data.accounts[local.environment].aws_workspace
  ip_protocol       = "tcp"
  from_port         = 3306
  to_port           = 3306
  description       = "Allow MySQL access from Workspaces"
}

# Ingress from ECS Cluster EC2s
resource "aws_vpc_security_group_ingress_rule" "opahub_db_ingress_ec2" {
  security_group_id            = aws_security_group.opahub_db.id
  referenced_security_group_id = aws_security_group.cluster_ec2.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  description                  = "Allow MySQL access from ECS Cluster EC2s"
}

# Allow all outbound
resource "aws_vpc_security_group_egress_rule" "opahub_db_egress_all" {
  security_group_id = aws_security_group.opahub_db.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}