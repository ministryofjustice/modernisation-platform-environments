resource "aws_lb" "ebsapps_lb" {
  name               = lower(format("lb-%s-ebsapp", local.component_name))
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_ebsapps_lb.id]
  subnets            = data.aws_subnets.shared-private.ids

  drop_invalid_header_fields = true
  enable_deletion_protection = true

  access_logs {
    bucket  = module.s3-bucket-logging.bucket.id
    prefix  = local.lb_log_prefix_ebsapp
    enabled = true
  }

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-ebsapp", local.component_name)) }
  )
}

resource "aws_lb_listener" "ebsapps_listener" {
  depends_on = [
    aws_acm_certificate_validation.external
  ]

  load_balancer_arn = aws_lb.ebsapps_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.external.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ebsapp_tg.id
  }
}

resource "aws_lb_target_group" "ebsapp_tg" {
  name     = lower(format("tg-%s-ebsapp", local.component_name))
  port     = local.application_data.accounts[local.environment].tg_apps_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.shared.id
  health_check {
    port     = local.application_data.accounts[local.environment].tg_apps_port
    protocol = "HTTP"
  }

  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 3600
  }
}

resource "aws_lb_target_group_attachment" "ebsapps" {
  count            = local.application_data.accounts[local.environment].ebsapps_no_instances
  target_group_arn = aws_lb_target_group.ebsapp_tg.arn
  target_id        = element(aws_instance.ec2_ebsapps.*.id, count.index)
  port             = local.application_data.accounts[local.environment].tg_apps_port
}
