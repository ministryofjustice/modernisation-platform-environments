##############################################
### Internal NLB — ECS FreeRADIUS (UDP 1812)
###
### Internal load balancer for RADIUS traffic to ECS tasks.
### WorkSpaces AD connects here when switching from EC2.
### Health check uses TCP port 80 (LinOTP HTTP) since
### NLB cannot health-check UDP directly.
##############################################

resource "aws_lb" "radius_ecs" {
  count = local.environment == "development" ? 1 : 0

  name_prefix                      = "recs-"
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = [aws_subnet.private_a[0].id, aws_subnet.private_b[0].id]
  enable_cross_zone_load_balancing = true

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-radius-ecs-nlb" }
  )
}

resource "aws_lb_target_group" "radius_ecs" {
  count = local.environment == "development" ? 1 : 0

  name_prefix = "recs-"
  port        = 1812
  protocol    = "UDP"
  target_type = "ip"
  vpc_id      = aws_vpc.workspaces[0].id

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = 5000
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-radius-ecs-tg" }
  )
}

resource "aws_lb_listener" "radius_ecs" {
  count = local.environment == "development" ? 1 : 0

  load_balancer_arn = aws_lb.radius_ecs[0].arn
  port              = 1812
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.radius_ecs[0].arn
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-radius-ecs-listener" }
  )
}
