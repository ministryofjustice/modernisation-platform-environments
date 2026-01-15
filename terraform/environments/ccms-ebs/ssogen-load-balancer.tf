resource "aws_lb" "ssogen_alb" {
  count              = local.is_development ? 1 : 0
  name               = lower(format("lb-%s-ssogen-internal", local.application_name))
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_ssogen_internal_alb[count.index].id]
  subnets            = data.aws_subnets.shared-private.ids

  drop_invalid_header_fields = true
  enable_deletion_protection = true

  access_logs {
    bucket  = module.s3-bucket-logging.bucket.id
    prefix  = local.lb_log_prefix_ssogen_internal
    enabled = true
  }

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-ssogen-internal", local.application_name)) }
  )
}

resource "aws_lb_target_group" "ssogen_internal_tg" {
  count       = local.is_development ? 1 : 0
  name        = lower(format("tg-%s-ssogen", local.application_name))
  port        = local.application_data.accounts[local.environment].tg_ssogen_apps_port
  protocol    = "HTTPS"
  vpc_id      = data.aws_vpc.shared.id
  target_type = "instance"
  # deregistration_delay = 60
  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTPS"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 3600
  }
}

resource "aws_lb_listener" "ssogen_internal_listener" {
  count             = local.is_development ? 1 : 0
  load_balancer_arn = aws_lb.ssogen_alb[count.index].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.external.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ssogen_internal_tg[count.index].arn
  }

  depends_on = [aws_acm_certificate_validation.external_nonprod]
}

resource "aws_lb_target_group_attachment" "ssogen_internal" {
  count            = local.is_development ? local.application_data.accounts[local.environment].ssogen_no_instances : 0
  target_group_arn = aws_lb_target_group.ssogen_internal_tg[0].arn
  target_id        = element(aws_instance.ec2_ssogen.*.id, count.index)
  port             = local.application_data.accounts[local.environment].tg_ssogen_apps_port
}

