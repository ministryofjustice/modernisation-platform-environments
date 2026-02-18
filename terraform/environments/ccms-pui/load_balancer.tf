# PUI Load Balancer Configuration

resource "aws_lb" "pui" {
  name               = "${local.application_name}-lb"
  internal           = true
  load_balancer_type = "application"
  subnets            = data.aws_subnets.shared-private.ids

  security_groups = [aws_security_group.load_balancer.id]

  access_logs {
    bucket  = module.s3-bucket-logging.bucket.id
    prefix  = "${local.application_name}-lb"
    enabled = true
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-lb", local.application_name, local.environment)) }
  )

  depends_on = [module.s3-bucket-logging]
}

resource "aws_lb_target_group" "pui_target_group" {
  name                 = "${local.application_name}-tg"
  port                 = local.application_data.accounts[local.environment].pui_server_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 7200
    enabled         = true
  }

  health_check {
    path                = "/civil/actuator/health"
    healthy_threshold   = "5"
    interval            = "120"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200"
    timeout             = "5"
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-tg", local.application_name, local.environment)) }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Redirect all traffic from the lb to the target group
resource "aws_lb_listener" "pui" {
  load_balancer_arn = aws_lb.pui.id
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = aws_acm_certificate.external.arn

  default_action {
    target_group_arn = aws_lb_target_group.pui_target_group.id
    type             = "forward"
  }
}