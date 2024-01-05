
resource "aws_security_group" "ecs_service" {
  name        = "ecs-service-${var.name}-${var.env_name}"
  description = "Security group for the ${var.env_name} ${var.name} service"
  vpc_id      = var.account_config.vpc_id
  tags        = var.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "delius_core_weblogic_to_db" {
  security_group_id            = aws_security_group.weblogic_service.id
  description                  = "weblogic service to db"
  from_port                    = var.delius_db_container_config.port
  to_port                      = var.delius_db_container_config.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.oracle_db_shared.security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_to_weblogic" {
  security_group_id            = aws_security_group.weblogic_service.id
  description                  = "load balancer to weblogic frontend"
  from_port                    = var.weblogic_config.frontend_container_port
  to_port                      = var.weblogic_config.frontend_container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
}

resource "aws_security_group_rule" "weblogic_allow_all_egress" {
  description       = "Allow all outbound traffic to any IPv4 address on 443"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.weblogic_service.id
}

resource "aws_security_group_rule" "alballow all ingress" {
  description       = "Allow inbound traffic from VPC"
  type              = "ingress"
  from_port         = var.ecs_frontend_port
  to_port           = var.ecs_frontend_port
  protocol          = "TCP"
  security_group_id = aws_security_group.ldap.id
  cidr_blocks       = [var.account_config.shared_vpc_cidr]
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "${var.name}-${var.env_name}"
  retention_in_days = 7
  tags              = var.tags
}
