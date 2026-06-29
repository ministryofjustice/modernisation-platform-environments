# EFS
resource "aws_security_group" "efs" {
  name        = "${local.application_name_short}-${local.environment}-efs"
  description = "Controls NFS access to the EFS file system from ECS tasks"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-efs" }
  )
}

# EFS Ingress
resource "aws_vpc_security_group_ingress_rule" "efs-from-ecs" {
  security_group_id            = aws_security_group.efs.id
  description                  = "Allow NFS from ECS tasks"
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.ecs.id
}

# RabbitMQ
resource "aws_security_group" "rabbitmq" {
  name        = "${local.application_name_short}-${local.environment}-rabbitmq"
  description = "Controls access to the RabbitMQ cluster"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-rabbitmq" }
  )
}

# RabbitMQ Ingress
resource "aws_vpc_security_group_ingress_rule" "rabbitmq-from-ecs" {
  security_group_id            = aws_security_group.rabbitmq.id
  description                  = "Allow AMQP from ECS tasks"
  ip_protocol                  = "tcp"
  from_port                    = 5672
  to_port                      = 5672
  referenced_security_group_id = aws_security_group.ecs.id
}

# RabbitMQ Egress
resource "aws_vpc_security_group_egress_rule" "rabbitmq-to-internet" {
  security_group_id = aws_security_group.rabbitmq.id
  description       = "Allow HTTPS outbound for SSM, Secrets Manager and package repositories"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# ECS
resource "aws_security_group" "ecs" {
  name        = "${local.application_name_short}-${local.environment}-ecs"
  description = "Controls traffic to and from ECS tasks"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-ecs" }
  )
}

# ECS Ingress
resource "aws_vpc_security_group_ingress_rule" "ecs-from-api-alb" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Allow HTTP traffic from API ALB to ECS tasks"
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  referenced_security_group_id = module.lb_api.security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "ecs-from-visualiser-alb" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Allow HTTP traffic from visualiser ALB to ECS tasks"
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  referenced_security_group_id = module.lb_visualiser.security_group.id
}

# ECS Egress
resource "aws_vpc_security_group_egress_rule" "ecs-to-internet" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow HTTPS outbound to internet"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "ecs-to-rds" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Allow SQL Server traffic to RDS"
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  referenced_security_group_id = data.aws_security_group.rds.id
}

resource "aws_vpc_security_group_egress_rule" "ecs-to-efs" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Allow NFS traffic to EFS"
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.efs.id
}

resource "aws_vpc_security_group_egress_rule" "ecs-to-rabbitmq" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Allow AMQP traffic to RabbitMQ"
  ip_protocol                  = "tcp"
  from_port                    = 5672
  to_port                      = 5672
  referenced_security_group_id = aws_security_group.rabbitmq.id
}

# RDS Ingress
# Managed here instead of RDS module 'allowed_security_groups' variable to avoid for_each error
resource "aws_vpc_security_group_ingress_rule" "rds-from-ecs" {
  security_group_id            = data.aws_security_group.rds.id
  description                  = "Allow SQL Server traffic from ECS tasks"
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  referenced_security_group_id = aws_security_group.ecs.id
}

# Visualiser ALB Ingress
# Managed here instead of locals.tf because loadbalancer.tf module does not support prefix lists
resource "aws_vpc_security_group_ingress_rule" "visualiser-alb-from-cloudfront" {
  security_group_id  = module.lb_visualiser.security_group.id
  description        = "Allow HTTPS from CloudFront edge nodes only"
  ip_protocol        = "tcp"
  from_port          = 443
  to_port            = 443
  prefix_list_id     = data.aws_ec2_managed_prefix_list.cloudfront.id
}