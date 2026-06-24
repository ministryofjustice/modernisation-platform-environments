resource "aws_lb" "ssogen_alb" {
  count              = local.ssogen_enabled ? 1 : 0
  name               = lower(format("lb-%s-internal", local.application_name_ssogen))
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

  depends_on = [aws_lb_target_group.ssogen_internal_tg_ssogen_enc_app]

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-internal", local.application_name_ssogen)) }
  )
}

resource "aws_lb" "ssogen_alb_console" {
  count              = local.ssogen_enabled ? 1 : 0
  name               = lower(format("lb-console-%s-internal", local.application_name_ssogen))
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_ssogen_internal_alb[count.index].id]
  subnets            = data.aws_subnets.shared-private.ids

  drop_invalid_header_fields = true
  enable_deletion_protection = true

  access_logs {
    bucket  = module.s3-bucket-logging.bucket.id
    prefix  = local.lb_log_prefix_ssogen_internal_console
    enabled = true
  }

  depends_on = [aws_lb_target_group.ssogen_internal_tg_ssogen_console]
  
  tags = merge(local.tags,
    { Name = lower(format("lb-console-%s-internal", local.application_name_ssogen)) }
  )
}

resource "aws_lb_target_group" "ssogen_internal_tg_ssogen_enc_app" {
  count            = local.ssogen_enabled ? 1 : 0
  name             = lower(format("tg-%s-enc-app", local.application_name_ssogen))
  port             = local.application_data.accounts[local.environment].tg_ssogen_apps_enc_port
  protocol         = "HTTPS"
  protocol_version = "HTTP2"
  vpc_id           = data.aws_vpc.shared.id
  target_type      = "instance"
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "ssogen_internal_tg_ssogen_console" {
  count            = local.ssogen_enabled ? 1 : 0
  name             = lower(format("tg-%s-console", local.application_name_ssogen))
  port             = local.application_data.accounts[local.environment].tg_ssogen_admin_enc_port
  protocol         = "HTTPS"
  protocol_version = "HTTP2"
  vpc_id           = data.aws_vpc.shared.id
  target_type      = "instance"
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "ssogen_internal_app_listener" {
  count             = local.ssogen_enabled ? 1 : 0
  load_balancer_arn = aws_lb.ssogen_alb[count.index].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.external_ssogen[count.index].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ssogen_internal_tg_ssogen_enc_app[count.index].arn
  }

  depends_on = [aws_acm_certificate_validation.external_nonprod]
}

resource "aws_lb_listener" "ssogen_internal_console_listener" {
  count             = local.ssogen_enabled ? 1 : 0
  load_balancer_arn = aws_lb.ssogen_alb_console[count.index].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.external_ssogen[count.index].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ssogen_internal_tg_ssogen_console[count.index].arn
  }

  # depends_on = [aws_acm_certificate_validation.external_nonprod]
}
