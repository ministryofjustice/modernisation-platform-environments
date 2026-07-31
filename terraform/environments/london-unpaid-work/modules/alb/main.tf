resource "aws_lb" "alb" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnets
  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout
  drop_invalid_header_fields = true

  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = var.name
    enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    },
  )
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  ssl_policy        = var.listener_protocol == "HTTPS" ? var.alb_ssl_policy : null
  certificate_arn   = var.listener_protocol == "HTTPS" ? var.certificate_arn : null

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied"
      status_code  = "403"
    }
  }

  tags = var.tags
}

resource "aws_lb_target_group" "target_group" {
  name                 = var.target_group_name
  port                 = var.target_group_port
  protocol             = var.target_group_protocol
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    path                = var.healthcheck_path
    protocol            = var.healthcheck_protocol
    interval            = var.healthcheck_interval
    timeout             = var.healthcheck_timeout
    healthy_threshold   = var.healthcheck_healthy_threshold
    unhealthy_threshold = var.healthcheck_unhealthy_threshold
  }

  tags = merge(
    var.tags,
    {
      Name = var.target_group_name
    },
  )
}
