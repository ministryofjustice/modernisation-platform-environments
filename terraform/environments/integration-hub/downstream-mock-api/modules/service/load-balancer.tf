resource "aws_security_group" "api_gateway_vpc_link" {
  name        = "${local.resource_name_prefix}-${local.environment}-apigw-vpc-link"
  description = "Security group for API Gateway VPC Link"
  vpc_id      = var.vpc.id

  egress {
    description = "Allow the VPC link to reach the internal load balancer"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc.cidr_block]
  }

  tags = local.tags
}

resource "aws_security_group" "load_balancer" {
  name        = "${local.resource_name_prefix}-${local.environment}-alb"
  description = "Security group for internal load balancer"
  vpc_id      = var.vpc.id

  egress {
    description     = "Allow the load balancer to reach the ECS service"
    from_port       = local.service_configuration.container_port
    to_port         = local.service_configuration.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
  }

  tags = local.tags
}

resource "aws_security_group_rule" "load_balancer_ingress_from_vpc_link" {
  description              = "Allow requests from the API Gateway VPC link"
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
  vpc_id      = var.vpc.id

  egress {
    description = "Allow the ECS service to reach AWS APIs over HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow DNS queries within the VPC"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc.cidr_block]
  }

  egress {
    description = "Allow TCP DNS queries within the VPC"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc.cidr_block]
  }

  tags = local.tags
}

resource "aws_security_group_rule" "ecs_ingress_from_load_balancer" {
  description              = "Allow requests from the internal load balancer"
  type                     = "ingress"
  from_port                = local.service_configuration.container_port
  to_port                  = local.service_configuration.container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_service.id
  source_security_group_id = aws_security_group.load_balancer.id
}


resource "aws_lb" "internal" {
  #checkov:skip=CKV_AWS_91:Development-only MVP uses API Gateway and ECS access logs; ALB access logging will be added before production
  #checkov:skip=CKV_AWS_150:Deletion protection is intentionally disabled for the development-only MVP
  #checkov:skip=CKV2_AWS_20:Traffic reaches this internal ALB only through the API Gateway VPC link
  name                       = "ih-bc-mock-${local.environment}-alb"
  load_balancer_type         = "application"
  internal                   = true
  security_groups            = [aws_security_group.load_balancer.id]
  subnets                    = var.private_subnet_ids
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = local.tags
}

resource "aws_lb_target_group" "service" {
  #checkov:skip=CKV_AWS_378:Traffic is confined to the VPC between the internal ALB and ECS task
  name        = "ih-bc-mock-${local.environment}-tg"
  port        = local.service_configuration.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc.id

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
  #checkov:skip=CKV_AWS_2:Traffic reaches this internal listener only through the API Gateway VPC link
  #checkov:skip=CKV_AWS_103:TLS terminates at API Gateway; the internal VPC link uses HTTP
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service.arn
  }
}
