
resource "aws_security_group" "ecs_service" {
  name        = "ecs-service-${var.name}-${var.env_name}"
  description = "Security group for the ${var.env_name} ${var.name} service"
  vpc_id      = var.account_config.vpc_id
  tags        = var.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "ecs_service_to_db" {
  security_group_id            = aws_security_group.ecs_service.id
  description                  = "weblogic service to db"
  from_port                    = var.rds_port ? var.rds_port : var.elasticache_port ? var.elasticache_port : null
  to_port                      = var.rds_port ? var.rds_port : var.elasticache_port ? var.elasticache_port : null
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_to_ecs_service" {
  security_group_id            = aws_security_group.ecs_service.id
  description                  = "load balancer to ecs service"
  from_port                    = var.ecs_service_port
  to_port                      = var.ecs_service_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.alb_security_group_id
}

resource "aws_security_group_rule" "ecs_service_tls_egress" {
  description       = "Allow all outbound traffic to any IPv4 address on 443"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_service.id
}

# Possibly switch to bastion only ingress rule
resource "aws_security_group_rule" "vpc_to_ecs_service_ingress" {
  description       = "Allow inbound traffic from VPC"
  type              = "ingress"
  from_port         = var.ecs_service_port
  to_port           = var.ecs_service_port
  protocol          = "TCP"
  security_group_id = aws_security_group.ecs_service.id
  cidr_blocks       = [var.account_config.shared_vpc_cidr]
}
