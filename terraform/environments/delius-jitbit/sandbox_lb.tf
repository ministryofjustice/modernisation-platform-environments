
resource "aws_lb_listener_rule" "listener_rule" {
  count        = local.is-development ? 1 : 0
  listener_arn = aws_lb_listener.listener.arn
  priority     = 10

  action {
    target_group_arn = aws_lb_target_group.target_group_fargate_sandbox[0].id
    type             = "forward"
  }

  condition {
    host_header {
      values = [local.sandbox_app_url]
    }
  }
}

resource "aws_lb_target_group" "target_group_fargate_sandbox" {
  # checkov:skip=CKV_AWS_261

  count = local.is-development ? 1 : 0

  name                 = "${local.application_name}-sandbox"
  port                 = local.app_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    path                = "/User/Login?ReturnUrl=%2f"
    healthy_threshold   = "5"
    interval            = "30"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-sandbox"
    }
  )
}
