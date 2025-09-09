resource "aws_lb_target_group" "frontend" {
  name     = "vcms-frontend"
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.account_info.vpc_id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200-399"
  }

  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400
  }

  tags = local.tags
}
