# Load balancers
resource "aws_lb" "alb" {
  count              = var.create_alb ? 1 : 0
  name               = "${var.env_name}-${var.name}-alb"
  internal           = var.is_internal
  load_balancer_type = var.load_balancer_type
  security_groups = concat(
    [var.bastion_sg_id]
  )
  subnets = var.account_config.ordered_private_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-${var.env_name}-alb"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Listeners
resource "aws_lb_listener" "alb_listener_https" {
  count = var.create_alb ? 1 : 0

  load_balancer_arn = aws_lb.alb[0].arn
  port              = var.listener_port_https
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      status_code  = "200"
      content_type = "text/plain"
      message_body = "OK"
    }
  }
}

resource "aws_lb_listener" "http_listener" {
  # Redirect HTTP to HTTPS
  count             = var.create_alb ? 1 : 0
  load_balancer_arn = aws_lb.alb[0].arn
  protocol          = "HTTP"
  port              = var.listener_port_http
  default_action {
    type = "redirect"
    redirect {
      port        = var.listener_port_https
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener_rule" "listener_rules" {
  count = var.create_alb ? length(var.listener_rules) : 0

  listener_arn = aws_lb_listener.alb_listener_https[0].arn
  condition {
    path_pattern {
      values = [var.listener_rules[count.index].path]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}
