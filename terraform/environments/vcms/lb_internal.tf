resource "aws_lb" "frontend_internal" {
  name               = "frontend-internal-alb"
  internal           = true
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb_internal_sg.id
  ]

  subnets = local.account_config.private_subnet_ids

  enable_deletion_protection = false
  idle_timeout               = 60

  tags = local.tags
}

resource "aws_lb_listener" "frontend_internal_http" {
  load_balancer_arn = aws_lb.frontend_internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}


