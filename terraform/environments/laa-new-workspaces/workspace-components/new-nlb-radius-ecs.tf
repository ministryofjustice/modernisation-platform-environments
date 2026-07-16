##############################################
### Internal NLB — ECS FreeRADIUS (UDP 1812)
###
### Internal load balancer for RADIUS traffic to ECS tasks.
### WorkSpaces AD connects here when switching from EC2.
### Health check uses TCP port 80 (LinOTP HTTP) since
### NLB cannot health-check UDP directly.
##############################################

resource "aws_lb" "radius_ecs" {
  name_prefix                      = "recs-"
  internal                         = true
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true

  subnet_mapping {
    subnet_id = aws_subnet.private_a.id
  }

  subnet_mapping {
    subnet_id = aws_subnet.private_b.id
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-radius-ecs-nlb" }
  )
}

resource "aws_lb_target_group" "radius_ecs" {
  name_prefix = "recs-"
  port        = 1812
  protocol    = "UDP"
  target_type = "ip"
  vpc_id      = aws_vpc.workspaces.id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    port                = 5000
    path                = "/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 6  # Allow 180s for LinOTP startup (startPeriod = 120s + buffer)
    matcher             = "200-399"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-radius-ecs-tg" }
  )
}

resource "aws_lb_listener" "radius_ecs" {
  load_balancer_arn = aws_lb.radius_ecs.arn
  port              = 1812
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.radius_ecs.arn
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-radius-ecs-listener" }
  )
}
