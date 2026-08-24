resource "aws_security_group" "api_gateway_vpc_link" {
  name        = "${local.resource_name_prefix}-${local.environment}-apigw-vpc-link"
  description = "Security group for API Gateway VPC Link"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.tags
}

resource "aws_security_group_rule" "api_gateway_vpc_link_egress" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.api_gateway_vpc_link.id
}

resource "aws_security_group" "load_balancer" {
  name        = "${local.resource_name_prefix}-${local.environment}-alb"
  description = "Security group for internal load balancer"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.tags
}

resource "aws_security_group_rule" "load_balancer_ingress_from_vpc_link" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.load_balancer.id
  source_security_group_id = aws_security_group.api_gateway_vpc_link.id
}

resource "aws_security_group" "ecs_service" {
  name        = "${local.resource_name_prefix}-${local.environment}-ecs"
  description = "Security group for downstream mock API ECS service"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.tags
}

resource "aws_security_group_rule" "load_balancer_egress_to_ecs" {
  type                     = "egress"
  from_port                = local.service_configuration.container_port
  to_port                  = local.service_configuration.container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.load_balancer.id
  source_security_group_id = aws_security_group.ecs_service.id
}

resource "aws_security_group_rule" "ecs_ingress_from_load_balancer" {
  type                     = "ingress"
  from_port                = local.service_configuration.container_port
  to_port                  = local.service_configuration.container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_service.id
  source_security_group_id = aws_security_group.load_balancer.id
}

resource "aws_security_group_rule" "ecs_egress_any" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_service.id
}

resource "aws_lb" "internal" {
  name                       = "ih-bc-mock-${local.environment}-alb"
  load_balancer_type         = "application"
  internal                   = true
  security_groups            = [aws_security_group.load_balancer.id]
  subnets                    = data.aws_subnets.shared-private.ids
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = local.tags
}

resource "aws_lb_target_group" "service" {
  name        = "ih-bc-mock-${local.environment}-tg"
  port        = local.service_configuration.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.shared.id

  health_check {
    enabled             = true
    path                = local.service_configuration.health_check_path
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

  tags = local.tags
}

resource "aws_lb_listener" "service" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service.arn
  }
}
